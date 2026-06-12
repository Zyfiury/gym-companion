#!/usr/bin/env python3
"""Generate Play Store listing graphics from app icon."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
ICON = ROOT / "app" / "assets" / "icon" / "app_icon.png"
OUT = ROOT / "store-listing"

# Gym Companion brand (matches app theme)
BG = (17, 28, 34)          # #111C22
SURFACE = (24, 40, 48)     # #182830
ACCENT = (61, 122, 147)    # #3D7A93
ACCENT_LIGHT = (127, 181, 160)  # #7FB5A0
TEXT = (232, 240, 244)     # #E8F0F4
TEXT_MUTED = (139, 170, 187)


def _font(size: int, bold: bool = False):
    candidates = [
        "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for path in candidates:
        p = Path(path)
        if p.exists():
            return ImageFont.truetype(str(p), size)
    return ImageFont.load_default()


def export_icons():
    icon = Image.open(ICON).convert("RGBA")
    for size, name in [(512, "icon-512.png"), (1024, "icon-1024.png")]:
        resized = icon.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(OUT / name, "PNG", optimize=True)
        print(f"Wrote {OUT / name}")


def export_feature_graphic():
    w, h = 1024, 500
    img = Image.new("RGB", (w, h), BG)
    draw = ImageDraw.Draw(img)

    # Subtle gradient bands
    for y in range(h):
        t = y / h
        r = int(BG[0] + (SURFACE[0] - BG[0]) * t * 0.6)
        g = int(BG[1] + (SURFACE[1] - BG[1]) * t * 0.6)
        b = int(BG[2] + (SURFACE[2] - BG[2]) * t * 0.6)
        draw.line([(0, y), (w, y)], fill=(r, g, b))

    # Accent glow circle behind icon
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse((40, 80, 420, 460), fill=(*ACCENT, 40))
    img = Image.alpha_composite(img.convert("RGBA"), glow).convert("RGB")
    draw = ImageDraw.Draw(img)

    icon = Image.open(ICON).convert("RGBA")
    icon_size = 320
    icon = icon.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    img.paste(icon, (80, (h - icon_size) // 2), icon)

    title_font = _font(56, bold=True)
    sub_font = _font(28)
    tag_font = _font(22)

    draw.text((440, 140), "Gym Companion", font=title_font, fill=TEXT)
    draw.text((440, 210), "AI coach · Meals · Workouts", font=sub_font, fill=ACCENT_LIGHT)
    draw.text((440, 270), "Personalised macros, plans & progress", font=tag_font, fill=TEXT_MUTED)

    # Accent line
    draw.rounded_rectangle((440, 320, 700, 326), radius=3, fill=ACCENT)

    bullets = ["Track calories & protein", "Adaptive workout splits", "Budget-friendly meal plans"]
    y = 340
    for line in bullets:
        draw.ellipse((440, y + 6, 452, y + 18), fill=ACCENT_LIGHT)
        draw.text((464, y), line, font=tag_font, fill=TEXT)
        y += 36

    out = OUT / "feature-graphic-1024x500.png"
    img.save(out, "PNG", optimize=True)
    print(f"Wrote {out}")


def export_screenshot_frames():
    """Placeholder frames showing recommended capture dimensions."""
    screens = [
        ("01-home", "Home — macro ring & greeting"),
        ("02-coach", "Coach — AI chat"),
        ("03-food", "Food — meal plan"),
        ("04-workout", "Workout — weekly split"),
        ("05-progress", "Progress — weight & PRs"),
        ("06-profile", "Profile — your stats"),
        ("07-paywall", "Pro — subscription"),
        ("08-feed", "Feed — community"),
    ]
    w, h = 1080, 1920
    title_font = _font(42, bold=True)
    body_font = _font(28)

    for slug, label in screens:
        img = Image.new("RGB", (w, h), BG)
        draw = ImageDraw.Draw(img)
        draw.rounded_rectangle((40, 80, w - 40, h - 200), radius=32, fill=SURFACE)
        draw.text((80, 120), "REPLACE WITH REAL SCREENSHOT", font=title_font, fill=ACCENT_LIGHT)
        draw.text((80, 200), label, font=body_font, fill=TEXT)
        draw.text(
            (80, h - 140),
            "Capture on device: Power + Vol Down\nThen replace this file before upload",
            font=_font(24),
            fill=TEXT_MUTED,
        )
        out = OUT / "screenshots" / f"{slug}-PLACEHOLDER.png"
        img.save(out, "PNG")
        print(f"Wrote placeholder {out}")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "screenshots").mkdir(exist_ok=True)
    if not ICON.exists():
        raise SystemExit(f"Icon not found: {ICON}")
    export_icons()
    export_feature_graphic()
    export_screenshot_frames()
    print("\nDone. Upload from:", OUT)


if __name__ == "__main__":
    main()
