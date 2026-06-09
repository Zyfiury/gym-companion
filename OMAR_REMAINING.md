# What only you can do (5 steps)

Everything else is automated in code/scripts. These need your Google/GitHub accounts.

## 1. Firebase (5 min)

```powershell
firebase login
.\scripts\deploy_firebase.ps1
```

Then Firebase Console → Project `gym-b541e` → Android app → add **release SHA-1** from:

`app\android\KEYSTORE_CREDENTIALS.local`

## 2. Google Cloud (5 min)

Same API key as YouTube — enable **Cloud Vision API** and **Places API** in [Google Cloud Console](https://console.cloud.google.com/apis/library?project=gym-b541e).

## 3. Play Console (20 min)

1. Create app listing
2. Upload `app\build\app\outputs\bundle\release\app-release.aab` (run `.\scripts\build_release.ps1` after keystore exists)
3. Internal testing → add your Gmail as tester
4. Create subscription products → link in RevenueCat (`pro` entitlement)

## 4. GitHub Pages (2 min)

Repo → Settings → Pages → Build and deployment → **GitHub Actions**

Push `main` — legal URLs go live at `/legal/privacy.html`

## 5. Phone

```powershell
.\scripts\install_on_phone.ps1
```

---

## One-command local setup

```powershell
.\scripts\setup_all.ps1
```

Runs: keystore, tests, debug APK, release AAB (if keystore exists), Firebase deploy (if logged in).
