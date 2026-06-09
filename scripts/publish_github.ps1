# Publishes this repo to GitHub (run after: gh auth login)
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

$gh = if (Get-Command gh -ErrorAction SilentlyContinue) { "gh" } else { "C:\Program Files\GitHub CLI\gh.exe" }
if (-not (Test-Path $gh) -and $gh -ne "gh") { throw "GitHub CLI not found. Install from https://cli.github.com or restart your terminal." }

& $gh auth status | Out-Null

$repoName = "gym-companion"

$hasOrigin = git remote 2>$null | Select-String -Pattern '^origin$' -Quiet

if ($hasOrigin) {
  git push -u origin main
} else {
  & $gh repo create $repoName --private --source=. --remote=origin --push --description "AI-powered gym, nutrition, and budget companion (Flutter + OpenClaw agents)"
}

Write-Host "Done. Repo URL:"
& $gh repo view --web 2>$null
