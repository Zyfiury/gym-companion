# Gym Companion - full automated test pipeline
# Usage: .\scripts\run_all_tests.ps1 [-SkipMaestro] [-SkipBuild]

param(
    [switch]$SkipMaestro,
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$App = Join-Path $Root "app"
$MaestroFlows = Join-Path $Root "maestro\flows"
$Apk = Join-Path $App "build\app\outputs\flutter-apk\app-debug.apk"

function Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }

Push-Location $App
try {
    Step "Flutter analyze"
    flutter analyze --no-fatal-infos --no-fatal-warnings
    if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed" }

    Step "Flutter unit/widget tests"
    flutter test
    if ($LASTEXITCODE -ne 0) { throw "flutter test failed" }

    if (-not $SkipBuild) {
        Step "Build debug APK"
        flutter build apk --debug
        if ($LASTEXITCODE -ne 0) { throw "flutter build apk failed" }
    }

    if (-not $SkipMaestro) {
        $adb = Get-Command adb -ErrorAction SilentlyContinue
        $maestroCmd = Get-Command maestro -ErrorAction SilentlyContinue
        if (-not $maestroCmd) {
            Write-Warning "Maestro CLI not found - skipping E2E. Install: https://maestro.mobile.dev"
        }
        elseif (-not $adb) {
            Write-Warning "adb not found - skipping E2E. Install Android SDK platform-tools."
        }
        else {
            Step "Check emulator/device"
            $devices = adb devices | Select-String "device$"
            if (-not $devices) {
                throw "No Android device/emulator connected. Start an emulator first."
            }

            if (Test-Path $Apk) {
                Step "Install APK"
                adb install -r $Apk
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "Install failed - trying uninstall + reinstall"
                    adb uninstall com.gymcompanion.gym_companion 2>$null
                    adb install $Apk
                    if ($LASTEXITCODE -ne 0) { throw "adb install failed" }
                }
            }
            else {
                throw "APK not found at $Apk - run without -SkipBuild"
            }

            $mobileFlows = @(
                "setup.yaml",
                "login_flow.yaml",
                "onboarding_flow.yaml",
                "full_app_flow.yaml",
                "swap_meal_flow.yaml",
                "allergy_block_flow.yaml",
                "feed_post_flow.yaml",
                "profile_export_flow.yaml",
                "chat_rule_flow.yaml",
                "chat_workout_flow.yaml",
                "cheap_meal_plan_flow.yaml",
                "custom_workout_flow.yaml",
                "camera_calorie_flow.yaml",
                "release_smoke.yaml"
            )

            foreach ($flow in $mobileFlows) {
                $path = Join-Path $MaestroFlows $flow
                if (-not (Test-Path $path)) {
                    throw "Missing flow: $path"
                }
                Step "Maestro: $flow"
                maestro test $path
                if ($LASTEXITCODE -ne 0) { throw "Maestro failed: $flow" }
            }
        }
    }

    Step "All checks passed"
    Write-Host "SUCCESS: analyze + unit tests + build + Maestro (if enabled)" -ForegroundColor Green
}
catch {
    Write-Host "FAILED: $_" -ForegroundColor Red
    exit 1
}
finally {
    Pop-Location
}
