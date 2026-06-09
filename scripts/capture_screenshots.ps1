$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$AppDir = Join-Path $Root "app"
$FlowsDir = Join-Path $Root "maestro\flows"
$OutDir = Join-Path $Root "docs\screenshots"

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$maestro = Get-Command maestro -ErrorAction SilentlyContinue
if (-not $maestro) {
    Write-Error "Maestro CLI not found. Install from https://maestro.mobile.dev"
}

$devices = adb devices | Select-String "device$"
if (-not $devices) {
    Write-Error "No Android emulator/device attached. Start an emulator first."
}

Write-Host "Building debug APK..."
Push-Location $AppDir
flutter build apk --debug
if ($LASTEXITCODE -ne 0) { Pop-Location; exit $LASTEXITCODE }
Pop-Location

Write-Host "Installing APK on device..."
adb install -r (Join-Path $AppDir "build\app\outputs\flutter-apk\app-debug.apk")

$stamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$runDir = Join-Path $OutDir $stamp
New-Item -ItemType Directory -Force -Path $runDir | Out-Null

Write-Host "Running screenshot flow -> $runDir"
Push-Location (Join-Path $Root "maestro")
maestro test --test-output-dir $runDir flows\screenshot_all_pages.yaml
$code = $LASTEXITCODE
Pop-Location

# Flatten PNGs from Maestro nested output into run folder root
Get-ChildItem -Path $runDir -Recurse -Filter "*.png" | ForEach-Object {
    $dest = Join-Path $runDir $_.Name
    if ($_.FullName -ne $dest) {
        Move-Item -Force $_.FullName $dest
    }
}

Write-Host ""
Write-Host "Screenshots saved to: $runDir"
Get-ChildItem $runDir -Filter "*.png" | Sort-Object Name | ForEach-Object { Write-Host "  $($_.Name)" }
exit $code
