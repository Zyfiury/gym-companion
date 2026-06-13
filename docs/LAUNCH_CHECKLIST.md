# Launch checklist — from code to customers

Work top to bottom. Items marked **[OMAR]** need your accounts/card and can't be done by the agent.

---

## 1. Identity (do first)

- [ ] **[OMAR] Pick the final name.** Candidates with availability notes are in the chat (short version: "Gym Companion" is usable but crowded — gymcompanion.com is already taken by a similar product, so you'd need a different domain like getgymcompanion.app).
- [ ] **[OMAR] Buy the domain** (~£10/yr) — Cloudflare Registrar or Namecheap. Prefer `.app` or `.com`. Check the name is also free as:
  - Google Play app name (search the store)
  - Instagram / TikTok / X handle
- [ ] If the name changes from "Gym Companion": update `app/lib/config/app_config.dart` (appName, supportEmail, URLs), `android/app/src/main/AndroidManifest.xml` label, store listing copy, legal pages, and the website. Ask the agent — it's a 15-minute job.

## 2. Business email

- [ ] **[OMAR]** Either:
  - **Google Workspace** (~£5/mo) → `omar@yourdomain.com` — best for Play Console + RevenueCat + support, or
  - **Cloudflare Email Routing** (free) → forwards `support@yourdomain.com` to your Gmail. Fine to start.
- [ ] Update `supportEmail` in `app_config.dart` and the legal pages once live.

## 3. Website

- [ ] Landing page is ready in `website/` (waitlist + privacy + terms).
- [ ] **[OMAR]** Create a free [Formspree](https://formspree.io) form, replace `YOUR_FORM_ID` in `website/index.html` (2 places).
- [ ] **[OMAR]** Deploy: Cloudflare Pages or Netlify drop (see `website/README.md`). Point your domain at it.
- [ ] Update `privacyPolicyUrl` / `termsOfServiceUrl` in `app_config.dart` to the new domain (currently GitHub Pages — works fine until then).

## 4. Google Play

- [ ] **[OMAR] Create a Play Console developer account** — $25 one-time, needs ID verification (can take a few days — start now).
- [ ] Create the app in Play Console, fill store listing from `docs/STORE_LISTING.md` (copy is final).
- [ ] Upload assets from `store-listing/` (icon + feature graphic ready).
- [ ] **Screenshots:** real captures exist in `docs/screenshots/latest/` — pick 6–8 (home, coach, meals, progress, workout, paywall) and upload. Re-capture if UI changed since 7 Jun (it has — worth redoing; see `docs/SCREENSHOT_GUIDE.md`).
- [ ] Data safety form: answers in `docs/DATA_SAFETY_FORM.md`.
- [ ] Content rating questionnaire, target audience, ads declaration (No ads).
- [ ] **Internal testing release first** — upload AAB, test on your phone.
- [ ] **Closed testing: 12+ testers for 14 days is required before Production** for new personal accounts. Recruit friends/family/Discord early — this is the longest pole in the tent.

## 5. Monetization

- [ ] **[OMAR]** In Play Console → Monetize → Subscriptions: create `pro_monthly` (£7.99) and `pro_annual` (£59.99, 7-day trial) to match `docs/PLAY_CONSOLE_SUBSCRIPTIONS.md`.
- [ ] **[OMAR]** In RevenueCat: link the Play products to the `pro` entitlement, add the public API key to the app config.
- [ ] Test the purchase flow on a real device via Internal testing (`docs/SUBSCRIPTION_MANUAL_TEST.md`).

## 6. Marketing (start during the 14-day closed test)

- [ ] **[OMAR]** Reserve social handles (Instagram, TikTok, X) for the chosen name.
- [ ] Content that works for fitness apps: 15–30s screen-recordings of photo-logging a real meal, and "asked my AI coach X" clips.
- [ ] Build-in-public thread on X — devlog posts convert well for indie apps.
- [ ] Waitlist email at launch: Formspree exports a CSV; send the Play Store link.

---

## Status

| Asset | State |
|-------|-------|
| App | 114 tests passing, release-ready |
| Landing page | `website/` — needs Formspree ID + deploy |
| Legal pages | Live on GitHub Pages, copies on landing page |
| Store copy | Final in `docs/STORE_LISTING.md` |
| Store graphics | Icon + feature graphic ready in `store-listing/` |
| Screenshots | Usable set in `docs/screenshots/latest/`, recommend re-capture |
| Blockers | Play Console account, domain, name decision — all **[OMAR]** |
