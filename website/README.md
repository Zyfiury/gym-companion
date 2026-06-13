# Gym Companion — landing page

Static site: no build step, no dependencies.

## Files

| File | Purpose |
|------|---------|
| `index.html` | Landing page with waitlist form |
| `privacy.html` | Privacy policy (copy of `docs/legal/privacy.html`) |
| `terms.html` | Terms of service (copy of `docs/legal/terms.html`) |
| `assets/` | App icon + screenshots |

## Before going live

1. **Waitlist form** — create a free form at [formspree.io](https://formspree.io) (50 submissions/month free), then replace `YOUR_FORM_ID` in both forms in `index.html`. Alternatives: [Web3Forms](https://web3forms.com) (free, just needs an access key) or a [Tally](https://tally.so) embed.
2. **Domain** — once bought, set it as the custom domain in your host's dashboard.

## Deploy (pick one, all free)

**Cloudflare Pages** (recommended):
1. Push this repo to GitHub.
2. Cloudflare dashboard → Workers & Pages → Create → Pages → connect repo.
3. Build settings: no build command, output directory `website`.

**Netlify**: drag-and-drop the `website/` folder at [app.netlify.com/drop](https://app.netlify.com/drop).

**GitHub Pages**: already serving `docs/` at `zyfiury.github.io/gym-companion` — you can copy these files into `docs/` instead if you prefer one host.

## Keep legal pages in sync

`docs/legal/*.html` is the source of truth (the app links to the GitHub Pages URLs). If you edit those, re-copy them here.
