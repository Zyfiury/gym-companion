# Publishes this repo to GitHub (run after: gh auth login)
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

gh auth status | Out-Null

$repoName = "gym-companion"

if (git remote get-url origin 2>$null) {
  git push -u origin main
} else {
  gh repo create $repoName --private --source=. --remote=origin --push --description "AI-powered gym, nutrition, and budget companion (Flutter + OpenClaw agents)"
}

Write-Host "Done. Repo URL:"
gh repo view --web 2>$null
