# Play Console Subscriptions + RevenueCat Linking

Package ID: `com.gymcompanion.gym_companion`

## Prerequisites (one-time)

1. **Play Console → Settings → API access**
   - Link your Google Cloud project
   - Grant access to your Play Console developer account

2. **Google Cloud → IAM → Service account**
   - Create a service account with Play Console API access
   - Download JSON key

3. **RevenueCat → Project Settings → Google Play**
   - Upload the Google Play service credentials JSON
   - Enter package name: `com.gymcompanion.gym_companion`

---

## Step A — Create subscriptions in Play Console

1. Open [Google Play Console](https://play.google.com/console)
2. Select **Gym Companion** (`com.gymcompanion.gym_companion`)
3. Go to **Monetise with Play → Products → Subscriptions**
4. Click **Create subscription**

### Subscription 1: Monthly

| Field | Value |
|-------|-------|
| Product ID | `monthly` |
| Name | Gym Companion Pro Monthly |
| Description | Unlimited AI coach, analytics, export, and premium features |
| Base plan ID | `monthly-base` |
| Billing period | 1 month |
| Price | £7.99 |
| Free trial | Optional (e.g. 7 days) |
| Status | **Activate** the base plan |

### Subscription 2: Annual

| Field | Value |
|-------|-------|
| Product ID | `annual` |
| Name | Gym Companion Pro Annual |
| Description | Best value — all Pro features for one year |
| Base plan ID | `annual-base` |
| Billing period | 1 year |
| Price | £59.99 |
| Status | **Activate** the base plan |

5. Complete **Monetise → Monetisation setup** (payments profile, merchant account) if not done.

---

## Step B — Link in RevenueCat

1. [RevenueCat Dashboard](https://app.revenuecat.com) → your project
2. **Products → + New → Google Play**
   - Add `monthly`
   - Add `annual`
3. **Entitlements → `pro`**
   - Attach Google Play products `monthly` and `annual`
   - Remove or deprioritise Test Store products for production
4. **Offerings → `default`**
   - Package `monthly` → Google Play product `monthly`
   - Package `annual` → Google Play product `annual`
   - Set `default` as **Current offering**

The app reads `offerings.current.monthly` and `offerings.current.annual` in `app/lib/services/subscription_service.dart`.

---

## Step C — Test purchases

1. Play Console → **Testing → License testers** → add your Gmail
2. Upload AAB to **Internal testing** (see `docs/STORE_LISTING.md`)
3. Open the internal test opt-in link on a physical Android device
4. In app: **Profile → Account → Upgrade to Pro**
5. Complete a test purchase (license testers are not charged)
6. Verify **RevenueCat → Customers** shows active `pro` entitlement
7. Test **Restore purchases** after reinstalling

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Purchase could not be completed" | Offerings empty — check RevenueCat `default` offering has `monthly`/`annual` packages |
| Products not syncing | Wait up to 24h after creating Play products; verify service credentials JSON |
| Not a license tester | Add Gmail under Play Console → Testing → License testers |
| Wrong package | RevenueCat package name must be `com.gymcompanion.gym_companion` |
