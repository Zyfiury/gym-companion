# Build a shareable APK for friends to sideload (real GPS, your .env baked in).
# Usage: .\scripts\share_test_apk.ps1

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$App = Join-Path $Root "app"
$EnvFile = Join-Path $App ".env"

if (-not (Test-Path $EnvFile)) {
    Write-Host "ERROR: app\.env not found. Copy app\.env.example and add your API keys first." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Building profile APK (stable for testers, includes .env) ===" -ForegroundColor Cyan
Push-Location $App
try {
    flutter build apk --profile
    if ($LASTEXITCODE -ne 0) { exit 1 }
}
finally {
    Pop-Location
}

$Apk = Join-Path $App "build\app\outputs\flutter-apk\app-profile.apk"
$Desktop = [Environment]::GetFolderPath("Desktop")
$Out = Join-Path $Desktop "GymCompanion-test.apk"
$ScriptsCopy = Join-Path $Root "scripts\GymCompanion-test.apk"
Copy-Item $Apk $Out -Force
Copy-Item $Apk $ScriptsCopy -Force

Write-Host ""
Write-Host "SUCCESS" -ForegroundColor Green
Write-Host "APK copied to:"
Write-Host "  $Out"
Write-Host "  $ScriptsCopy"
Write-Host ""
Write-Host "Send to your friend via Google Drive, WhatsApp, or Discord."
Write-Host "They must enable Install unknown apps for that app, then open the APK."
Write-Host ""
Write-Host "Test login: test@gym.app / test123"
Start-Process explorer.exe -ArgumentList "/select,`"$Out`""
