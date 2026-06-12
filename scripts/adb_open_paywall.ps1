# Opens Gym Companion and navigates to Pro paywall → monthly purchase button.
# Google Play purchase confirmation must be completed manually on the device.
#
# Prerequisites:
#   - USB debugging enabled, device connected (adb devices)
#   - App installed from Internal testing track
#   - User signed in (or script will stop at login)
#
# Usage:
#   .\scripts\adb_open_paywall.ps1
#   .\scripts\adb_open_paywall.ps1 -SkipLaunch   # app already open on home

param(
    [string]$Package = "com.gymcompanion.gym_companion",
    [string]$Activity = "com.gymcompanion.gym_companion.MainActivity",
    [int]$StepDelayMs = 1500,
    [switch]$SkipLaunch
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

function Invoke-Adb {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
    $out = & adb @Args 2>&1
    if ($LASTEXITCODE -ne 0) { throw "adb $($Args -join ' ') failed: $out" }
    return $out
}

function Wait-Ui {
    param([int]$Ms = $StepDelayMs)
    Start-Sleep -Milliseconds $Ms
}

function Get-UiDump {
    Invoke-Adb shell uiautomator dump /sdcard/gym_uidump.xml | Out-Null
    $local = Join-Path $env:TEMP "gym_uidump.xml"
    Invoke-Adb pull /sdcard/gym_uidump.xml $local | Out-Null
    return Get-Content $local -Raw
}

function Get-BoundsCenter {
    param([string]$Bounds)
    if ($Bounds -match '\[(\d+),(\d+)\]\[(\d+),(\d+)\]') {
        $x1 = [int]$Matches[1]; $y1 = [int]$Matches[2]
        $x2 = [int]$Matches[3]; $y2 = [int]$Matches[4]
        return @(([int](($x1 + $x2) / 2)), ([int](($y1 + $y2) / 2)))
    }
    return $null
}

function Tap-SemanticsOrText {
    param(
        [string[]]$SemanticsIds = @(),
        [string[]]$TextContains = @()
    )
    $xml = Get-UiDump
    $nodes = [regex]::Matches($xml, '<node[^>]+>')

    foreach ($id in $SemanticsIds) {
        $pattern = "content-desc=""$id"""
        $m = [regex]::Match($xml, "<node[^>]*$pattern[^>]*bounds=""([^""]+)""")
        if ($m.Success) {
            $center = Get-BoundsCenter $m.Groups[1].Value
            if ($center) {
                Write-Host "  Tapping semantics '$id' at $($center[0]),$($center[1])"
                Invoke-Adb shell input tap $center[0] $center[1] | Out-Null
                return $true
            }
        }
    }

    foreach ($text in $TextContains) {
        $m = [regex]::Match($xml, "<node[^>]*text=""[^""]*$([regex]::Escape($text))[^""]*""[^>]*bounds=""([^""]+)""")
        if ($m.Success) {
            $center = Get-BoundsCenter $m.Groups[2].Value
            if ($center) {
                Write-Host "  Tapping text containing '$text' at $($center[0]),$($center[1])"
                Invoke-Adb shell input tap $center[0] $center[1] | Out-Null
                return $true
            }
        }
        # Flutter sometimes puts label in content-desc
        $m2 = [regex]::Match($xml, "<node[^>]*content-desc=""[^""]*$([regex]::Escape($text))[^""]*""[^>]*bounds=""([^""]+)""")
        if ($m2.Success) {
            $center = Get-BoundsCenter $m2.Groups[2].Value
            if ($center) {
                Write-Host "  Tapping content-desc containing '$text' at $($center[0]),$($center[1])"
                Invoke-Adb shell input tap $center[0] $center[1] | Out-Null
                return $true
            }
        }
    }

    return $false
}

# --- Main ---
Write-Step "Checking ADB device"
$devices = Invoke-Adb devices
if ($devices -notmatch "device`$") {
    throw "No Android device found. Run: adb devices"
}

if (-not $SkipLaunch) {
    Write-Step "Launching $Package"
    Invoke-Adb shell am force-stop $Package | Out-Null
    Invoke-Adb shell am start -n "$Package/$Activity" | Out-Null
    Wait-Ui -Ms 4000
}

Write-Step "Open Profile (header avatar)"
if (-not (Tap-SemanticsOrText -SemanticsIds @('tab-profile') -TextContains @('Profile'))) {
    Write-Warning "Could not find profile button — sign in first, or tap Profile manually."
}
Wait-Ui

Write-Step "Switch to Account tab"
if (-not (Tap-SemanticsOrText -SemanticsIds @('profile-tab-account') -TextContains @('Account'))) {
    Write-Warning "Could not find Account tab — tap it manually."
}
Wait-Ui

Write-Step "Open Gym Companion Pro paywall"
if (-not (Tap-SemanticsOrText -SemanticsIds @('profile-pro-upgrade') -TextContains @('Gym Companion Pro', 'Pro'))) {
    Write-Warning "Could not find Pro upgrade row — tap it manually."
}
Wait-Ui -Ms 2000

Write-Step "Select Monthly plan (default; tap to ensure)"
Tap-SemanticsOrText -SemanticsIds @('paywall-monthly-tab') -TextContains @('Monthly') | Out-Null
Wait-Ui

Write-Step "Tap Start Pro (opens Google Play billing)"
if (-not (Tap-SemanticsOrText -SemanticsIds @('paywall-purchase-btn') -TextContains @('Start Pro'))) {
    Write-Warning "Could not find purchase button — scroll down and tap 'Start Pro' manually."
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host " MANUAL STEP REQUIRED ON YOUR PHONE" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "1. Confirm the Google Play purchase dialog"
Write-Host "2. Complete payment (license testers are not charged)"
Write-Host "3. Wait for 'Welcome to Gym Companion Pro!' snackbar"
Write-Host ""
Write-Host "Then verify entitlement:" -ForegroundColor Green
Write-Host "  python scripts/verify_revenuecat_entitlement.py --user-id YOUR_FIREBASE_UID"
Write-Host ""
