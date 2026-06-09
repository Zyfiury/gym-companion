# Gym Companion

AI-powered gym, nutrition, and budget companion built for OpenClaw agents.

## Project structure

```
gymapp/
├── SOUL.md          # App personality & tone
├── USER.md          # User profile, plan, progress log
├── AGENTS.md        # PlanAgent, LocationAgent, RecipeAgent, DeliveryAgent
├── skills/          # Agent skill definitions
├── frontend/        # React + Vite + Tailwind (mobile-first)
├── maestro/flows/   # UI test flows
└── scripts/         # Cron setup helpers
```

## API keys

Set in environment or OpenClaw secrets:

| Variable | Purpose |
|----------|---------|
| `YOUTUBE_API_KEY` | Recipe cooking videos |
| `GOOGLE_PLACES_API_KEY` | Nearby stores & restaurants |
| `TROLLEY_API_KEY` | UK supermarket pricing |

Copy `.env.example` to `.env` for local frontend overrides.

## Flutter app (native — recommended for emulator/phone)

```bash
cd app
flutter pub get
flutter run -d emulator-5554
```

Package: `com.gymcompanion.gym_companion`

## Web frontend (legacy)

```bash
cd frontend
npm install
npm run dev
```

Open http://localhost:5173

## Maestro tests

With dev server running:

```bash
cd maestro
maestro test flows/
```

## Cron jobs

Registered via OpenClaw Gateway:

| Job | Schedule | Action |
|-----|----------|--------|
| gymapp-morning-brief | 8am daily | Workout + meals + shopping → Discord DM |
| gymapp-macro-checkin | 8pm daily | Macro check-in prompt → Discord DM |
| gymapp-weekly-plan | Sun 9am | PlanAgent weekly replan |

Setup: `powershell -File scripts/setup-cron.ps1`

## Agent spawn pattern

On daily plan request, PlanAgent runs `sessions_spawn` for LocationAgent + RecipeAgent in parallel, `sessions_yield`, then merges results. See `AGENTS.md`.
