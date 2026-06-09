# Share Gym Companion with iPhone friends (free)

No Apple Developer fee. Your friend opens a link in Safari and can add it to their Home Screen like an app.

## Your link

After running `.\scripts\deploy_web.ps1`:

**https://zyfiury.github.io/gym-companion/**

(Replace `zyfiury` if your GitHub username differs.)

## What to send your friend

Copy/paste this message:

---

**Gym Companion — test the app on your iPhone (free)**

1. Open this link in **Safari** (not Chrome):  
   https://zyfiury.github.io/gym-companion/
2. Tap **Share** (square with arrow) → **Add to Home Screen** → **Add**
3. Open **Gym Companion** from your home screen
4. Log in:
   - Email: `test@gym.app`
   - Password: `test123`
5. Complete the quick onboarding (weight, goal, etc.)

**Note:** This is the **same Flutter app** as Android (web build). Coach, meals, delivery/eat out, and workouts work. Camera scan and Apple Health need the native Android app.

---

## Android friends

Send the APK instead (no link needed):

- Desktop: `C:\Users\omarz\Desktop\GymCompanion-test.apk`
- Or rebuild: `.\scripts\share_test_apk.ps1`

Same test login: `test@gym.app` / `test123`

## Re-deploy after changes

```powershell
.\scripts\deploy_web.ps1
```

GitHub Actions rebuilds automatically (about 2–5 min).
