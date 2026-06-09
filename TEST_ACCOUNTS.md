# Test Accounts (Flutter App)

Pre-seeded on first app launch. Passwords are hashed with SHA-256 in local storage.

| Email | Password | Display Name | Profile | Notes |
|-------|----------|--------------|---------|-------|
| `test@gym.app` | `test123` | Test User | ✅ Complete | 125 XP, cut goal, **dairy allergy**, allergy-safe meals |
| `demo@gym.app` | `demo123` | Demo User | ❌ Needs onboarding | Use for signup/onboarding Maestro flow |
| `alex@gym.app` | `alex123` | Alex | ✅ Complete | 320 XP, bulk goal, feed posts |

## Quick login (app)

Tap **"Use test account"** on the login screen to auto-fill `test@gym.app` / `test123`.

## Maestro

```bash
cd maestro
maestro test flows/login_flow.yaml
maestro test flows/full_app_flow.yaml
maestro test flows/onboarding_flow.yaml
maestro test flows/allergy_block_flow.yaml
maestro test flows/swap_meal_flow.yaml
```
