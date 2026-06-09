# Run every automated setup step for Gym Companion.
# Usage: .\scripts\setup_all.ps1

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$App = Join-Path $Root "app"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Gym Companion - full automated setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/5] Upload keystore..." -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "create_upload_keystore.ps1")

Write-Host ""
Write-Host "[2/5] Flutter tests..." -ForegroundColor Cyan
Push-Location $App
try {
    flutter test
    if ($LASTEXITCODE -ne 0) { throw "Tests failed" }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "[3/5] Debug APK..." -ForegroundColor Cyan
Push-Location $App
try {
    flutter build apk --debug
    if ($LASTEXITCODE -ne 0) { throw "Debug APK build failed" }
    Write-Host "  -> app\build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor Green
}
finally {
    Pop-Location
}

$keyProps = Join-Path $App "android\key.properties"
if (Test-Path $keyProps) {
    Write-Host ""
    Write-Host "[4/5] Release App Bundle..." -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot "build_release.ps1")
} else {
    Write-Host ""
    Write-Host "[4/5] Skipping release AAB (no key.properties)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[5/5] Firebase deploy (best effort)..." -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "deploy_firebase.ps1")
$firebaseOk = $LASTEXITCODE -eq 0

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DONE - automated steps" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "YOU still need to do (accounts / stores):" -ForegroundColor Yellow
Write-Host "  1. firebase login  then  .\scripts\deploy_firebase.ps1"
Write-Host "  2. Add release SHA-1 from app\android\KEYSTORE_CREDENTIALS.local to Firebase"
Write-Host "  3. Play Console: upload app-release.aab, create subscriptions, link RevenueCat"
Write-Host "  4. GitHub: enable Pages (GitHub Actions source), push to main"
Write-Host "  5. Phone: .\scripts\install_on_phone.ps1"
Write-Host ""

if (-not $firebaseOk) {
    Write-Host "Firebase deploy skipped or failed - run firebase login first." -ForegroundColor DarkYellow
}
