# Build release App Bundle with pre-flight checks
# Usage: .\scripts\build_release.ps1

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$App = Join-Path $Root "app"
$EnvFile = Join-Path $App ".env"

function Fail($msg) {
    Write-Host "BLOCKED: $msg" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Release pre-flight ===" -ForegroundColor Cyan

if (-not (Test-Path $EnvFile)) {
    Fail ".env not found at $EnvFile"
}

$envContent = Get-Content $EnvFile -Raw
if ($envContent -match 'DEV_PRO_OVERRIDE\s*=\s*true') {
    Fail "Remove DEV_PRO_OVERRIDE=true from .env before release builds"
}
if ($envContent -match 'your-project|your-firebase|your-revenuecat|REPLACE') {
    Fail ".env still contains placeholder values"
}
if ($envContent -notmatch 'FIREBASE_PROJECT_ID=\S+') {
    Fail "FIREBASE_PROJECT_ID not set in .env"
}
if ($envContent -match 'REVENUECAT_KEY=sk_') {
    Fail "REVENUECAT_KEY must be public goog_... key, not sk_ secret"
}

$keyProps = Join-Path $App "android\key.properties"
if (-not (Test-Path $keyProps)) {
    Write-Warning "android/key.properties not found — release will sign with debug key (not Play Store ready)"
}

Push-Location $App
try {
    Write-Host "`n=== Flutter test ===" -ForegroundColor Cyan
    flutter test
    if ($LASTEXITCODE -ne 0) { Fail "flutter test failed" }

    Write-Host "`n=== Build App Bundle ===" -ForegroundColor Cyan
    flutter build appbundle --release
    if ($LASTEXITCODE -ne 0) { Fail "flutter build appbundle failed" }

    $aab = Join-Path $App "build\app\outputs\bundle\release\app-release.aab"
    Write-Host "`nSUCCESS: $aab" -ForegroundColor Green
    Write-Host "Next: upload to Play Console internal testing track" -ForegroundColor Yellow
}
finally {
    Pop-Location
}
