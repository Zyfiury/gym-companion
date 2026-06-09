# Gym Companion — Billion-Dollar Launch Plan

**Goal:** Ship a premium, store-ready fitness app that users trust, pay for, and recommend.

**Current state:** Strong MVP — 10/10 unit tests, 9/9 Maestro E2E, full feature set (AI coach, meals, workouts, barcode, feed, export).

**Target:** App Store + Google Play launch in 3 phases over ~4 weeks.

---

## Phase 1 — Launch blockers (Week 1) ✅ Started

| # | Task | Status | Owner action |
|---|------|--------|--------------|
| 1 | Google Sign-In (Firebase) | ✅ Code ready | Enable Google provider in Firebase Console + add SHA-1 |
| 2 | Sign in with Apple (iOS) | ✅ Code ready | Enable Apple capability in Xcode + Firebase |
| 3 | Forgot password | ✅ Implemented | — |
| 4 | Account deletion | ✅ Implemented | — |
| 5 | Hide test accounts in release builds | ✅ `kReleaseMode` | — |
| 6 | Privacy Policy + Terms links | ✅ In-app links | Host pages at `gymcompanion.app` |
| 7 | RevenueCat UID linking | ✅ On login | Swap `sk_` key for public SDK key in `.env` |
| 8 | Release signing (Android keystore) | ⏳ | Generate upload keystore, update `build.gradle.kts` |
| 9 | iOS Firebase (`GoogleService-Info.plist`) | ⏳ | Register iOS app in Firebase, fix bundle ID |
| 10 | Rotate API keys — stop shipping `.env` in APK | ⏳ | Use `--dart-define` for production CI |

---

## Phase 2 — Premium polish (Week 2)

| # | Task | Why it matters |
|---|------|----------------|
| 11 | Custom app icon + splash screen | First impression = premium |
| 12 | Onboarding value prop (3 slides before signup) | Conversion |
| 13 | Paywall alignment — gate export + unlimited chat | Revenue honesty |
| 14 | Manage subscription screen | Apple/Google requirement |
| 15 | Firebase Crashlytics | Post-launch stability |
| 16 | Firebase Analytics (signup, paywall, retention) | Growth decisions |
| 17 | Email verification (optional soft gate) | Reduce spam accounts |
| 18 | Offline mode messaging | Trust on poor network |
| 19 | App Store screenshots (6.7", 6.1", iPad) | Discovery |
| 20 | Play Store feature graphic + screenshots | Discovery |

---

## Phase 3 — Scale & differentiate (Week 3–4)

| # | Task | Million-pound moat |
|---|------|-------------------|
| 21 | Push notification campaigns (streak, Sunday plan) | Retention |
| 22 | Referral / invite friends (feed + XP) | Viral growth |
| 23 | Personalised weekly email digest | Engagement |
| 24 | Restaurant / meal delivery integration (LocationAgent) | Unique UK value |
| 25 | Apple Health + Google Health Connect sync | Ecosystem lock-in |
| 26 | Coach voice mode (TTS responses) | Premium feel |
| 27 | A/B test paywall copy via Remote Config | Revenue optimisation |
| 28 | ASO: keywords, localisation (UK + US) | Organic installs |

---

## Monetisation model (recommended)

| Tier | Price | Includes |
|------|-------|----------|
| **Free** | £0 | 10 AI messages/day, basic plan, barcode log |
| **Pro** | £7.99/mo | Unlimited AI, export PDF/CSV, meal swaps, priority support |
| **Annual** | £59.99/yr | Same as Pro, 37% saving |

Configure in RevenueCat → entitlements `pro` → offerings `monthly` + `annual`.

---

## Store submission checklist

### Google Play
- [ ] Upload keystore + Play App Signing
- [ ] Data safety form (health, email, photos)
- [ ] Content rating questionnaire
- [ ] Privacy policy URL
- [ ] Subscription terms in listing
- [ ] Internal testing → closed → production rollout

### Apple App Store
- [ ] Apple Developer account ($99/yr)
- [ ] Sign in with Apple enabled (mandatory with Google)
- [ ] App Privacy nutrition labels
- [ ] Account deletion in-app (✅ done)
- [ ] HealthKit usage justification
- [ ] Subscription metadata + review notes with test account
- [ ] TestFlight → App Review

---

## Legal pages to host

Create at `https://gymcompanion.app/`:

1. **Privacy Policy** — data collected (email, health, food logs), Firebase, Groq, RevenueCat
2. **Terms of Service** — subscription auto-renewal, cancellation, liability
3. **Support** — `support@gymcompanion.app`

---

## Firebase Console setup (required for Google login)

See `GOOGLE_SIGNIN_SETUP.md` for step-by-step.

Quick summary:
1. Authentication → Enable **Google** + **Apple** + **Email/Password**
2. Add Android SHA-1 (debug + release keystore)
3. Register iOS app → download `GoogleService-Info.plist`
4. Firestore rules: users can only read/write own `users/{uid}`

---

## Run production build

```powershell
# Android release (after keystore configured)
flutter build appbundle --release

# iOS (after signing + plist)
flutter build ipa --release

# Full QA before submit
.\scripts\run_all_tests.ps1
```

---

## Success metrics (first 90 days)

| Metric | Target |
|--------|--------|
| Day-7 retention | > 25% |
| Free → Pro conversion | > 4% |
| Crash-free sessions | > 99.5% |
| App Store rating | > 4.5★ |
| MAU | 10,000 (stretch) |

---

## Premium upgrade (implemented)

| Feature | Status |
|---------|--------|
| Home dashboard (default tab) | Done |
| Premium splash + gradient branding | Done |
| Paywall redesign (monthly/annual) | Done |
| Pro gates: export, shuffle meals, chat quota | Done |
| Free message counter (persisted) | Done |
| Profile in header avatar | Done |
| Chat quota chip | Done |
| Light theme polish | Done |

---

**Bottom line:** Core app is built and premium-tier UX is in place. Phase 1 closes store blockers; Phases 2–3 scale to a defensible billion-dollar category leader in AI fitness.
