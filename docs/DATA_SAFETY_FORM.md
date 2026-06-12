# Google Play Data Safety Form — Gym Companion

Use this when filling **Play Console → App content → Data safety → Start**.

Privacy policy URL: https://zyfiury.github.io/gym-companion/legal/privacy.html

---

## Overview questions

| Question | Answer |
|----------|--------|
| Does your app collect or share user data? | **Yes** |
| Is all data encrypted in transit? | **Yes** (HTTPS/TLS) |
| Do you provide a way to request data deletion? | **Yes** — Profile → Account → Delete account |
| Have you committed to Google Play Families Policy? | Only if targeting children — **No** (app is 16+) |
| Independent security review | **No** (unless you have one) |

---

## Data types to declare

For each type below: **Collected** = Yes, **Shared** = Yes (with third parties listed), **Processed ephemerally** = No unless noted.

### Personal info

| Data type | Collected | Shared | Required or optional | Purpose |
|-----------|-----------|--------|----------------------|---------|
| **Email address** | Yes | Yes — Firebase | Required (account) | Account management, authentication |
| **Name** | Yes | Yes — Firebase | Optional (display name) | Account management, community feed |

### Health and fitness

| Data type | Collected | Shared | Required or optional | Purpose |
|-----------|-----------|--------|----------------------|---------|
| **Health info** | Yes | Yes — Firebase | Optional | Weight, height, age, goals, workout logs, food logs, steps (Health Connect) |
| **Fitness info** | Yes | Yes — Firebase | Optional | Workouts, PRs, macro tracking |

*In the form, pick **Health and fitness** and select weight, fitness info, and/or other health info as applicable.*

### Photos and videos

| Data type | Collected | Shared | Required or optional | Purpose |
|-----------|-----------|--------|----------------------|---------|
| **Photos** | Yes | Yes — Google Cloud Vision, Groq | Optional (user initiates camera) | Barcode scan, meal calorie estimation |

### Location

| Data type | Collected | Shared | Required or optional | Purpose |
|-----------|-----------|--------|----------------------|---------|
| **Precise location** | Yes | Yes — Google Places | Optional (permission) | Nearby supermarkets and restaurants |

### App activity

| Data type | Collected | Shared | Required or optional | Purpose |
|-----------|-----------|--------|----------------------|---------|
| **App interactions** | Yes | Yes — Firebase Analytics | Not optional (analytics) | Analytics, product improvement |
| **In-app search history** | No | — | — | — |
| **Other user-generated content** | Yes | Yes — Firebase | Optional | Community feed posts |

### App info and performance

| Data type | Collected | Shared | Required or optional | Purpose |
|-----------|-----------|--------|----------------------|---------|
| **Crash logs** | Yes | Yes — Firebase Crashlytics | Not optional | Diagnostics |
| **Diagnostics** | Yes | Yes — Firebase Crashlytics | Not optional | App stability |

### Device or other IDs

| Data type | Collected | Shared | Required or optional | Purpose |
|-----------|-----------|--------|----------------------|---------|
| **Device or other IDs** | Yes | Yes — Firebase, RevenueCat | Required for subscriptions/analytics | Analytics, subscription management |

---

## Third-party sharing (for each data type)

When asked "Is this data shared with third parties?" → **Yes**, then select:

| Third party | Data shared | Purpose |
|-------------|-------------|---------|
| **Google (Firebase)** | Account, health/fitness, feed, analytics, crashes | Hosting, auth, analytics |
| **Groq** | Chat messages, food descriptions | AI coach responses |
| **Google Cloud (Vision)** | Meal photos | Food recognition |
| **Google (Places)** | Location | Store/restaurant search |
| **RevenueCat** | Purchase status, user ID | Subscription management |
| **Google Play** | Purchase transactions | Billing |

---

## Data handling

| Question | Answer |
|----------|--------|
| Data sold to third parties | **No** |
| Data used for advertising | **No** |
| Data used for personalization | **Yes** — meal/workout personalisation |
| Data collection required or optional | Mix — account email required; location/camera/health optional |
| Users can request deletion | **Yes** — in-app delete account |
| Data deletion method | In-app: Profile → Account → Delete account; or email support@gymcompanion.app |

---

## Security practices

- Data encrypted in transit: **Yes**
- Users can request deletion: **Yes**
- Data deletion URL or method: describe in-app delete + support email

---

## Account creation

| Method | Supported |
|--------|-----------|
| Username and password | Yes (email/password) |
| OAuth | Yes (Google Sign-In) |
| Other | No |

---

## After submitting

1. Preview the Data safety section on your store listing
2. Ensure it matches your [privacy policy](https://zyfiury.github.io/gym-companion/legal/privacy.html)
3. If you add new data collection later, update both the form and privacy policy
