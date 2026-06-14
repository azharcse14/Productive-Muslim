#!/usr/bin/env python3
"""Generate Qalbee app icons (heart 'qalb' + crescent motif) using Pillow.

Brand palette (from lib/core/theme/qalbee_colors.dart):
  teal    #15564D   gold #C08A2E / #E2B264   cream #F6F4EE
Outputs (all squares, supersampled then LANCZOS-downsampled for clean edges):
  assets/icon/qalbee_icon.png             1024  full icon w/ teal background
  assets/icon/qalbee_icon_foreground.png  1024  heart only, transparent bg (adaptive)
"""
import math
from PIL import Image, ImageDraw

OUT = "assets/icon"
S = 1024          # final size
SS = 4            # supersample factor
W = S * SS        # working canvas size

TEAL_TOP = (24, 96, 86)      # slightly lighter teal
TEAL_BOT = (12, 60, 54)      # darker teal
GOLD_TOP = (230, 184, 104)   # #E6B868
GOLD_BOT = (176, 124, 38)    # #B07C26
CREAM = (246, 244, 238)


def vgradient(size, top, bot):
    """Vertical gradient image."""
    g = Image.new("RGB", (1, size))
    for y in range(size):
        t = y / (size - 1)
        g.putpixel((0, y), tuple(round(top[i] + (bot[i] - top[i]) * t) for i in range(3)))
    return g.resize((size, size))


def heart_points(cx, cy, scale):
    """Classic parametric heart, centered at (cx, cy)."""
    pts = []
    n = 720
    for i in range(n + 1):
        t = math.pi * 2 * i / n
        x = 16 * math.sin(t) ** 3
        y = -(13 * math.cos(t) - 5 * math.cos(2 * t)
              - 2 * math.cos(3 * t) - math.cos(4 * t))
        pts.append((cx + x * scale, cy + y * scale))
    return pts


def main():
    # ---- background (teal gradient) with soft rounded square already implied by launcher ----
    bg = vgradient(W, TEAL_TOP, TEAL_BOT).convert("RGBA")

    # subtle radial glow behind heart
    glow = Image.new("L", (W, W), 0)
    gd = ImageDraw.Draw(glow)
    r = int(W * 0.42)
    gd.ellipse([W // 2 - r, W // 2 - r, W // 2 + r, W // 2 + r], fill=70)
    glow = glow.resize((W, W))
    glow_layer = Image.new("RGBA", (W, W), (255, 255, 255, 0))
    glow_layer.putalpha(glow)
    # tint glow cream
    glow_rgb = Image.new("RGBA", (W, W), CREAM + (0,))
    glow_rgb.putalpha(glow)
    bg = Image.alpha_composite(bg, glow_rgb)

    # ---- heart shape (gold gradient fill) ----
    cx, cy = W // 2, int(W * 0.46)
    scale = W * 0.0235
    pts = heart_points(cx, cy, scale)

    mask = Image.new("L", (W, W), 0)
    ImageDraw.Draw(mask).polygon(pts, fill=255)

    gold = vgradient(W, GOLD_TOP, GOLD_BOT).convert("RGBA")
    heart = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    heart.paste(gold, (0, 0), mask)

    # ---- crescent moon carved into heart (negative space, upper-left) ----
    cm_r = int(W * 0.135)
    mx, my = int(W * 0.40), int(W * 0.40)
    crescent = Image.new("L", (W, W), 0)
    cd = ImageDraw.Draw(crescent)
    cd.ellipse([mx - cm_r, my - cm_r, mx + cm_r, my + cm_r], fill=255)
    off = int(cm_r * 0.62)
    cut = Image.new("L", (W, W), 0)
    ImageDraw.Draw(cut).ellipse(
        [mx - cm_r + off, my - cm_r - off // 2,
         mx + cm_r + off, my + cm_r - off // 2], fill=255)
    # crescent = circle minus offset circle
    cres_px = crescent.load()
    cut_px = cut.load()
    # subtract
    from PIL import ImageChops
    crescent = ImageChops.subtract(crescent, cut)

    # punch crescent out of heart alpha
    ha = heart.split()[3]
    ha = ImageChops.subtract(ha, crescent)
    heart.putalpha(ha)

    # small five-point star next to crescent (negative space)
    star_cx, star_cy = int(W * 0.545), int(W * 0.345)
    star_r = int(W * 0.052)
    spts = []
    for i in range(10):
        ang = -math.pi / 2 + i * math.pi / 5
        rr = star_r if i % 2 == 0 else star_r * 0.42
        spts.append((star_cx + rr * math.cos(ang), star_cy + rr * math.sin(ang)))
    star = Image.new("L", (W, W), 0)
    ImageDraw.Draw(star).polygon(spts, fill=255)
    ha = ImageChops.subtract(heart.split()[3], star)
    heart.putalpha(ha)

    # ---- compose full icon ----
    full = Image.alpha_composite(bg, heart)
    full = full.resize((S, S), Image.LANCZOS)
    full.save(f"{OUT}/qalbee_icon.png")

    # ---- adaptive foreground: heart on transparent, scaled down (safe zone) ----
    fg = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    fg = Image.alpha_composite(fg, heart)
    # shrink to ~66% for adaptive safe area
    fg_small = fg.resize((int(S * 0.66), int(S * 0.66)), Image.LANCZOS)
    canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    pos = (S - fg_small.width) // 2
    canvas.alpha_composite(fg_small, (pos, pos))
    canvas.save(f"{OUT}/qalbee_icon_foreground.png")

    print("wrote", f"{OUT}/qalbee_icon.png", "and foreground")


if __name__ == "__main__":
    main()
