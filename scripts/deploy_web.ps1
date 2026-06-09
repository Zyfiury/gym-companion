# Deploy free web app for iPhone friends (GitHub Pages - no Apple fee).
# Usage: .\scripts\deploy_web.ps1
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

$gh = if (Get-Command gh -ErrorAction SilentlyContinue) { "gh" } else { "C:\Program Files\GitHub CLI\gh.exe" }
if (-not (Get-Command $gh -ErrorAction SilentlyContinue)) {
  throw "GitHub CLI not found. Install from https://cli.github.com"
}

& $gh auth status | Out-Null

$envFile = Join-Path $root "app\.env"
if (Test-Path $envFile) {
  $envRaw = Get-Content $envFile -Raw
  $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($envRaw))
  $b64 | & $gh secret set APP_DOTENV_B64
  Write-Host "Synced app\.env to GitHub secret APP_DOTENV_B64" -ForegroundColor Green
} else {
  Write-Host "No app\.env found. Flutter web build will fail without APP_DOTENV_B64 secret." -ForegroundColor Yellow
}

$owner = (& $gh api user -q .login)
$repo = "gym-companion"
try {
  & $gh api "repos/$owner/$repo/pages" 2>$null | Out-Null
} catch {
  & $gh api -X POST "repos/$owner/$repo/pages" -f build_type=workflow 2>$null | Out-Null
  Write-Host "Enabled GitHub Pages on repo." -ForegroundColor Green
}

Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
git add -A
$status = git status --porcelain
if ($status) {
  git commit -m "Deploy web app to GitHub Pages for free iPhone testing"
  git push origin main
} else {
  Write-Host "No local changes. Triggering workflow manually." -ForegroundColor DarkYellow
  & $gh workflow run pages.yml
}

$pagesUrl = "https://$($owner.ToLower()).github.io/$repo/"
Write-Host ""
Write-Host "Web app URL (send to iPhone friends):" -ForegroundColor Green
Write-Host "  $pagesUrl" -ForegroundColor White
Write-Host ""
Write-Host "First deploy takes 2-5 minutes." -ForegroundColor Cyan
Write-Host "iPhone: Safari, then Share, then Add to Home Screen" -ForegroundColor Cyan
Write-Host 'Test login: test@gym.app / test123' -ForegroundColor Cyan
