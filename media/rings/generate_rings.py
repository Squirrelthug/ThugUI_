"""Generate the ring textures the "Ring thickness" slider picks from.

Ring_Main.tga (the original, hand-made ring) is a soft band centred at radius
82 of 128, ~18px wide at half alpha, fading linearly to nothing over ~14px on
each side, with the fringe going black as the alpha drops -- a subtle dark
outline. The Cooldown swipe and the radial StatusBar can only draw whatever
texture they are handed, so thickness cannot be changed at runtime; instead
this script bakes one ring per slider stop, keeping the band centre, the
edge softness and the black fringe of the original and varying only the
width. The stop that matches the original (18) is not generated: the code
keeps using Ring_Main.tga there so the default is pixel-identical to before.

Run from the addon root with Pillow installed:
    python media/rings/generate_rings.py
"""
import os
from PIL import Image

SIZE = 256
CENTER = SIZE / 2.0
BAND_RADIUS = 82.0      # measured on Ring_Main.tga: peak alpha at r = 82
EDGE = 14.0             # measured: full alpha to zero over ~14px each side
SUPER = 4               # supersampling per axis
STOPS = range(6, 67, 3) # 6, 9, ..., 66 -- must match the slider in ui/pages/CursorRings.lua


def alpha_at(r, thickness):
    half = thickness / 2.0
    edge = min(EDGE, thickness)
    d = abs(r - BAND_RADIUS)
    core = half - edge / 2.0
    if d <= core:
        return 1.0
    fade_end = half + edge / 2.0
    if d >= fade_end:
        return 0.0
    return (fade_end - d) / edge


def rgb_for(alpha):
    # White where the band is solid, black in the faint fringe, blended between:
    # Ring_Main.tga goes white at alpha ~0.4 and black at ~0.2.
    t = (alpha - 0.2) / 0.2
    t = max(0.0, min(1.0, t))
    v = int(round(255 * t))
    return v, v, v


def render(thickness):
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = im.load()
    step = 1.0 / SUPER
    samples = SUPER * SUPER
    for y in range(SIZE):
        for x in range(SIZE):
            acc = 0.0
            for sy in range(SUPER):
                for sx in range(SUPER):
                    dx = x + (sx + 0.5) * step - CENTER
                    dy = y + (sy + 0.5) * step - CENTER
                    acc += alpha_at((dx * dx + dy * dy) ** 0.5, thickness)
            a = acc / samples
            if a <= 0.0:
                continue
            r, g, b = rgb_for(a)
            px[x, y] = (r, g, b, int(round(255 * a)))
    return im


def main():
    out_dir = os.path.dirname(os.path.abspath(__file__))
    for t in STOPS:
        if t == 18:
            continue  # Ring_Main.tga is the 18 stop
        path = os.path.join(out_dir, "Ring_T%02d.tga" % t)
        render(t).save(path, rle=True)
        print("wrote", path)


if __name__ == "__main__":
    main()
