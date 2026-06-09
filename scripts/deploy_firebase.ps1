# Deploy Firestore rules + indexes to gym-b541e
# Usage: firebase login   (once)
#        .\scripts\deploy_firebase.ps1

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Push-Location $Root

try {
    Write-Host "Deploying Firestore rules and indexes..." -ForegroundColor Cyan
    firebase deploy --only firestore --project gym-b541e
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`nIf auth failed, run: firebase login" -ForegroundColor Yellow
        exit $LASTEXITCODE
    }
    Write-Host "`nFirestore deploy complete." -ForegroundColor Green
}
finally {
    Pop-Location
}
