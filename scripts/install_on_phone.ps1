$ErrorActionPreference = "Stop"
$Apk = "c:\Users\omarz\.openclaw\workspace\gymapp\app\build\app\outputs\flutter-apk\app-debug.apk"

if (-not (Test-Path $Apk)) {
    Write-Host "Building debug APK..."
    Push-Location "c:\Users\omarz\.openclaw\workspace\gymapp\app"
    flutter build apk --debug
    Pop-Location
}

Write-Host ""
Write-Host "Connected devices:"
adb devices
Write-Host ""

$physical = adb devices | Select-String "device$" | Where-Object { $_ -notmatch "emulator" }
if ($physical) {
    Write-Host "Installing on phone..."
    adb install -r $Apk
    Write-Host "Done! Open 'Gym Companion' on your phone."
} else {
    Write-Host "No physical phone detected via USB."
    Write-Host ""
    Write-Host "Option A — USB install:"
    Write-Host "  1. On phone: Settings > About > tap Build number 7x"
    Write-Host "  2. Settings > Developer options > USB debugging ON"
    Write-Host "  3. Plug in USB, accept 'Allow debugging' prompt"
    Write-Host "  4. Run this script again"
    Write-Host ""
    Write-Host "Option B — Copy APK manually:"
    Write-Host "  $Apk"
    Write-Host "  Copy to phone (Google Drive / USB file transfer), open it, allow 'Install unknown apps'"
    explorer.exe "/select,$Apk"
}
