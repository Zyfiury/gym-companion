# Sync Android SHA-1 fingerprints to Firebase and refresh google-services.json.
# Fixes Google Sign-In ApiException 10 (DEVELOPER_ERROR).
#
# Usage:
#   .\scripts\sync_google_signin.ps1                    # debug + upload keys
#   .\scripts\sync_google_signin.ps1 -FromDevice        # also read SHA from phone/emulator APK
#   .\scripts\sync_google_signin.ps1 -Sha1 "AB:CD:..."  # add Play App Signing SHA manually

param(
    [switch]$FromDevice,
    [string]$Sha1 = ""
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$AppId = "1:928816456435:android:187277bbd8fe7444f04d86"
$Project = "gym-b541e"
$Package = "com.gymcompanion.gym_companion"
$OutJson = Join-Path $Root "app\android\app\google-services.json"
$ApkSigner = Get-ChildItem "$env:LOCALAPPDATA\Android\Sdk\build-tools" -Recurse -Filter "apksigner.bat" -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName

function Normalize-Sha1([string]$sha) {
    ($sha -replace ":", "").ToLowerInvariant()
}

function Invoke-Firebase([string[]]$CmdArgs) {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $lines = & firebase @CmdArgs 2>&1
    $ErrorActionPreference = $prev
    $out = ($lines | ForEach-Object { "$_" }) -join "`n"
    if ($LASTEXITCODE -ne 0 -and $out -notmatch '[a-f0-9]{40}' -and $out -notmatch '^\s*\{') {
        throw "firebase $($CmdArgs -join ' ') failed: $out"
    }
    return $out
}

function Get-RegisteredSha1 {
    $list = Invoke-Firebase @("apps:android:sha:list", $AppId, "--project", $Project)
    $shaMatches = [regex]::Matches($list, '[a-f0-9]{40}')
    $set = @{}
    foreach ($m in $shaMatches) { $set[$m.Value.ToLowerInvariant()] = $true }
    return $set
}

function Add-Sha1IfMissing([string]$label, [string]$sha1, $registered) {
    $norm = Normalize-Sha1 $sha1
    if ($registered.ContainsKey($norm)) {
        Write-Host "  OK  $label ($norm)" -ForegroundColor DarkGray
        return
    }
    Write-Host "  ADD $label ($norm)" -ForegroundColor Yellow
    Invoke-Firebase @("apps:android:sha:create", $AppId, $norm, "--project", $Project) | Out-Null
    $registered[$norm] = $true
}

function Get-DeviceSha1 {
    if (-not $ApkSigner) {
        Write-Warning "apksigner not found - install Android SDK build-tools"
        return @()
    }
    $found = @()
    $devices = adb devices | Select-String "device$" | ForEach-Object { ($_ -split "\s+")[0] } | Where-Object { $_ -ne "List" }
    foreach ($serial in $devices) {
        $pathLine = adb -s $serial shell pm path $Package 2>$null
        if (-not $pathLine) {
            Write-Host "  skip $serial - $Package not installed" -ForegroundColor DarkGray
            continue
        }
        $remote = ($pathLine -split ":", 2)[1].Trim()
        $local = Join-Path $env:TEMP "gym_signin_$serial.apk"
        adb -s $serial pull $remote $local | Out-Null
        $out = & $ApkSigner verify --print-certs $local 2>&1 | Out-String
        $m = [regex]::Match($out, 'SHA-1 digest:\s*([a-f0-9]{40})', 'IgnoreCase')
        if ($m.Success) {
            $sha = $m.Groups[1].Value.ToLowerInvariant()
            Write-Host "  device $serial -> SHA-1 $sha" -ForegroundColor Cyan
            $found += $sha
        }
    }
    return $found | Select-Object -Unique
}

Write-Host "`n=== Sync Google Sign-In (Firebase $Project) ===" -ForegroundColor Cyan
$registered = Get-RegisteredSha1

Write-Host "`nKeystore fingerprints:" -ForegroundColor Cyan
$debugLine = keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android 2>&1 |
    Select-String "SHA1:\s*(.+)"
if ($debugLine) {
    Add-Sha1IfMissing "debug" $debugLine.Matches.Groups[1].Value.Trim() $registered
}

$keyProps = Join-Path $Root "app\android\key.properties"
if (Test-Path $keyProps) {
    $kv = @{}
    Get-Content $keyProps | Where-Object { $_ -match '=' } | ForEach-Object {
        $k, $v = $_ -split '=', 2
        $kv[$k.Trim()] = $v.Trim()
    }
    if ($kv.storeFile -and $kv.storePassword -and $kv.keyAlias) {
        $ks = Resolve-Path (Join-Path (Join-Path $Root "app\android\app") $kv.storeFile)
        $uploadLine = keytool -list -v -keystore $ks -alias $kv.keyAlias -storepass $kv.storePassword 2>&1 |
            Select-String "SHA1:\s*(.+)"
        if ($uploadLine) {
            Add-Sha1IfMissing "upload" $uploadLine.Matches.Groups[1].Value.Trim() $registered
        }
    }
}

if ($Sha1) {
    Add-Sha1IfMissing "manual" $Sha1 $registered
}

if ($FromDevice) {
    Write-Host "`nInstalled APK fingerprints:" -ForegroundColor Cyan
    foreach ($sha in Get-DeviceSha1) {
        Add-Sha1IfMissing "device" $sha $registered
    }
}

Write-Host "`nRefreshing google-services.json..." -ForegroundColor Cyan
$json = Invoke-Firebase @("apps:sdkconfig", "android", $AppId, "--project", $Project)
$start = $json.IndexOf('{')
if ($start -lt 0) { throw "Failed to download google-services.json from Firebase" }
$parsed = $json.Substring($start).Trim()
$parsed | Set-Content -Path $OutJson -Encoding UTF8
Write-Host "Wrote $OutJson" -ForegroundColor Green

Write-Host "`nDone. Rebuild and upload a new AAB:" -ForegroundColor Yellow
Write-Host "  cd app && flutter build appbundle --release" -ForegroundColor White
Write-Host "`nPlay Store installs also need the App signing SHA-1 from Play Console > App integrity." -ForegroundColor DarkYellow
Write-Host "Run with -FromDevice while your phone is plugged in to auto-add it." -ForegroundColor DarkYellow
