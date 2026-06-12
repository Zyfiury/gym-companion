# Subscription Purchase — Manual Test Checklist

Use this on a **real Android device** with the app installed from **Play Internal testing** (not sideload APK).

---

## Before you start

| Step | Done |
|------|------|
| Play Console → **Testing → License testers** → your Gmail added | ☐ |
| Internal testing release is **live** and device has opt-in link installed | ☐ |
| Signed in to Play Store on device with **same Gmail** as license tester | ☐ |
| RevenueCat `default` offering has Google Play `monthly` + `annual` packages | ☐ |
| `REVENUECAT_SECRET_KEY=sk_...` in `app/.env` (for verification script only) | ☐ |

**Find your Firebase UID (RevenueCat app_user_id):**
- Firebase Console → Authentication → Users → copy UID  
- Or Profile in app after login (if shown) / debug logs

---

## Optional: ADB assist (opens paywall for you)

```powershell
cd C:\Users\omarz\.openclaw\workspace\gymapp
.\scripts\adb_open_paywall.ps1
```

Requires USB debugging. Script navigates: **Profile → Account → Gym Companion Pro → Monthly → Start Pro**.  
You still **manually confirm** the Google Play dialog on the phone.

---

## Test 1 — Monthly purchase

| # | Action | Expected | Pass |
|---|--------|----------|------|
| 1 | Open app (signed in) | Home loads | ☐ |
| 2 | Tap **profile avatar** (top right) | Profile opens | ☐ |
| 3 | **Account** tab → **Gym Companion Pro** | Paywall shows Monthly + Annual | ☐ |
| 4 | Ensure **Monthly** selected | Shows £7.99/month | ☐ |
| 5 | Tap **Start Pro — £7.99/month** | Google Play purchase sheet | ☐ |
| 6 | Complete purchase (test card / license tester) | Success, snackbar "Welcome to Gym Companion Pro!" | ☐ |
| 7 | Coach tab — send messages | No "0 msgs left" lock (unlimited) | ☐ |
| 8 | Profile → Export CSV | Works without paywall (Pro) | ☐ |

### Verify in RevenueCat (CLI)

```powershell
python scripts/verify_revenuecat_entitlement.py --user-id YOUR_FIREBASE_UID
```

Or poll until active after purchase:

```powershell
python scripts/verify_revenuecat_entitlement.py --user-id YOUR_FIREBASE_UID --watch 10
```

Expected: `✅ pro entitlement is ACTIVE`

| # | Check | Pass |
|---|-------|------|
| 9 | RevenueCat Dashboard → Customers → your UID → `pro` active | ☐ |
| 10 | Verification script returns active | ☐ |

---

## Test 2 — Restore purchases

| # | Action | Expected | Pass |
|---|--------|----------|------|
| 1 | Note you are Pro | Coach unlimited | ☐ |
| 2 | Uninstall Gym Companion | App removed | ☐ |
| 3 | Reinstall from Internal testing link | Fresh install | ☐ |
| 4 | Sign in with **same account** | Logged in | ☐ |
| 5 | Profile → Account → **Restore purchases** | "Pro restored ✓" | ☐ |
| 6 | Run verification script again | `pro` still active | ☐ |

---

## Test 3 — Cancel subscription

| # | Action | Expected | Pass |
|---|--------|----------|------|
| 1 | On phone: **Play Store → Profile → Payments & subscriptions → Subscriptions** | Gym Companion listed | ☐ |
| 2 | Cancel subscription | Shows active until period end | ☐ |
| 3 | App may still show Pro until expiry | Normal grace behavior | ☐ |
| 4 | After expiry (or revoke in Play test tools), reopen app | Pro features locked again | ☐ |

---

## Test 4 — Annual plan (optional)

| # | Action | Expected | Pass |
|---|--------|----------|------|
| 1 | Paywall → **Annual** → Start Pro | Play sheet for annual product | ☐ |
| 2 | Complete purchase | `pro` active, annual product in RevenueCat | ☐ |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "Item not available" | Play products not active; wait up to 24h after creating subs |
| Purchase sheet never appears | Reinstall from Internal track; check RevenueCat offering |
| Verification 404 | Wrong Firebase UID; complete purchase first; ensure logged in |
| REST API auth error | Use `sk_` secret key, not `goog_` public key |
| Still free after purchase | Tap Restore; check RevenueCat customer ID matches Firebase UID |

---

## Production gate

Do **not** submit to Production until Tests 1 and 2 pass on a physical device.
