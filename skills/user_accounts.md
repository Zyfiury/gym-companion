# SKILL.md — user_accounts

## Objective
Handle multi-user accounts with per-user data isolation.

## Storage
- **Accounts:** IndexedDB `gymapp/accounts` — email, passwordHash (SHA-256), userId, displayName
- **User data:** IndexedDB `gymapp_{userId}/data` — profile, food log, gamification, etc.
- **Agent memory:** `/memory/users/{userId}/chat_history.json`, `USER.md`, `feed.json`

## Session
Frontend stores `gymapp_session` in localStorage: `{ userId, email, displayName }`

## On signup
1. Create account in accounts store.
2. Initialize user profile with `profileComplete: false`.
3. Run onboarding wizard (goal, stats, budget).
4. Set `profileComplete: true` after wizard.

## On login
1. Verify SHA-256 password hash.
2. Load user data from `gymapp_{userId}`.
3. Restore chat history from per-user store.

## On logout
Clear session, return to Login page. Data persists in IndexedDB.

## Agent sync
All API messages include `userId` field for routing to correct memory folder.
