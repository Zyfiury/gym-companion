# Generate Android upload keystore for Play Store (run once).
# Usage: .\scripts\create_upload_keystore.ps1
# Optional: -Password "your-secure-password"

param(
    [string]$Password = ""
)

$ErrorActionPreference = "Stop"
$AndroidDir = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..\app\android")).Path
$Keystore = Join-Path $AndroidDir "upload-keystore.jks"
$KeyProps = Join-Path $AndroidDir "key.properties"
$CredsFile = Join-Path $AndroidDir "KEYSTORE_CREDENTIALS.local"

if (Test-Path $Keystore) {
    Write-Host "Keystore already exists: $Keystore" -ForegroundColor Yellow
    if (-not (Test-Path $KeyProps)) {
        Write-Host "key.properties missing. Restore from KEYSTORE_CREDENTIALS.local or delete .jks and re-run."
    }
    exit 0
}

if ([string]::IsNullOrWhiteSpace($Password)) {
    $Password = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 24 | ForEach-Object { [char]$_ })
}

$dname = "CN=Gym Companion, OU=Mobile, O=GymCompanion, L=London, C=GB"
Write-Host "Creating upload keystore at $Keystore ..." -ForegroundColor Cyan

$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
    Write-Host "keytool not found. Install JDK or Android Studio." -ForegroundColor Red
    exit 1
}

& keytool -genkey -v `
    -keystore $Keystore `
    -alias upload `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -storepass $Password `
    -keypass $Password `
    -dname $dname

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

@"
storePassword=$Password
keyPassword=$Password
keyAlias=upload
storeFile=../upload-keystore.jks
"@ | Set-Content -Path $KeyProps -Encoding UTF8

$credText = @"
BACK UP THESE FILES SECURELY. Losing the keystore blocks Play Store updates.

Keystore: $Keystore
Alias: upload
Password: $Password

Add release SHA-1 to Firebase:
  keytool -list -v -keystore "$Keystore" -alias upload -storepass $Password
"@
$credText | Set-Content -Path $CredsFile -Encoding UTF8

Write-Host ""
Write-Host "SUCCESS" -ForegroundColor Green
Write-Host "  Keystore: $Keystore"
Write-Host "  key.properties: $KeyProps"
Write-Host "  Credentials backup: $CredsFile (gitignored)"
Write-Host ""
Write-Host "Next: add release SHA-1 to Firebase Console (see KEYSTORE_CREDENTIALS.local)" -ForegroundColor Yellow
