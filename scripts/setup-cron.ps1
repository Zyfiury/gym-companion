# Register Gym App cron jobs via OpenClaw CLI
$ErrorActionPreference = "Stop"
$DiscordUser = "829800292307959909"
$Tz = "Europe/London"
$Model = "anthropic/claude-haiku-4-5-20251001"
$Workspace = "C:\Users\omarz\.openclaw\workspace\gymapp"

Write-Host "Registering gymapp cron jobs..."

openclaw cron add `
  --name "gymapp-morning-brief" `
  --cron "0 8 * * *" `
  --tz $Tz `
  --message "GYMAPP_MORNING: Read $Workspace/USER.md and skills. Push today's workout, meal plan, and shopping list to user. Use plan_generation and shopping_list skills. Deliver concise Discord DM." `
  --announce `
  --to $DiscordUser `
  --channel discord `
  --model $Model `
  --session isolated `
  --description "8am daily workout + meal + shopping brief"

openclaw cron add `
  --name "gymapp-macro-checkin" `
  --cron "0 20 * * *" `
  --tz $Tz `
  --message "GYMAPP_CHECKIN: Run progress_checkin skill. Ask user what they ate today. Log to USER.md weekly progress log. Gentle macro feedback. Discord DM." `
  --announce `
  --to $DiscordUser `
  --channel discord `
  --model $Model `
  --session isolated `
  --description "8pm daily macro check-in"

openclaw cron add `
  --name "gymapp-weekly-plan" `
  --cron "0 9 * * 0" `
  --tz $Tz `
  --message "GYMAPP_WEEKLY: PlanAgent run. Read $Workspace/USER.md progress. Regenerate weekly workout split and daily macros per plan_generation.md. Update Weekly Plan in USER.md. Discord summary." `
  --announce `
  --to $DiscordUser `
  --channel discord `
  --model $Model `
  --session isolated `
  --description "Sunday 9am weekly plan regeneration"

Write-Host "Done. Verify with: openclaw cron list"
