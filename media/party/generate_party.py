"""Generate the party frames' circle textures (the player, 2026-10-09).

The cursor rings' art (media/Ring_Main.tga, media/rings/) is a deliberately
soft band: alpha fades over ~14 of 256 pixels on each side, so a ring drawn
from it has a blurry edge, most visible as the fill animates. The player
wants the party frames' resource ring clean, with a defined edge. These are
hard-edged: full alpha inside, zero outside, with one source pixel of
anti-aliasing (supersampled) so the edge is smooth but sharp, at 512 pixels
so it stays sharp when shown large.

  Disc.tga        a filled circle (the health fill and the dark background)
  Ring_Tnn.tga    a ring touching the edge, nn = thickness in percent of the
                  diameter; the slider in ui/pages/PartyFrames.lua picks one

Run from the addon root with Pillow installed:
    python media/party/generate_party.py
"""
import os
from PIL import Image

SIZE = 512
SUPER = 4
CENTER = SIZE / 2.0
OUTER = SIZE / 2.0 - 1.0          # one pixel clear of the edge, so nothing clips
THICKNESSES = (6, 10, 14, 18, 24)  # must match PartyFrames.RING_THICKNESSES


def coverage(px, py, inner, outer):
    """Fraction of the pixel's SUPER x SUPER samples inside inner <= r <= outer."""
    hit = 0
    for sy in range(SUPER):
        for sx in range(SUPER):
            x = px + (sx + 0.5) / SUPER - CENTER
            y = py + (sy + 0.5) / SUPER - CENTER
            r = (x * x + y * y) ** 0.5
            if inner <= r <= outer:
                hit += 1
    return hit / float(SUPER * SUPER)


def make(inner, outer, path):
    img = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 0))
    px = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            # Only pixels near an edge need sampling; the rest are 0 or 1.
            dx, dy = x + 0.5 - CENTER, y + 0.5 - CENTER
            r = (dx * dx + dy * dy) ** 0.5
            if r > outer + 1 or r < inner - 1:
                a = 0.0
            elif inner + 1 < r < outer - 1:
                a = 1.0
            else:
                a = coverage(x, y, inner, outer)
            px[x, y] = (255, 255, 255, int(round(a * 255)))
    img.save(path)


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    make(-1.0, OUTER, os.path.join(here, "Disc.tga"))
    for t in THICKNESSES:
        width = SIZE * t / 100.0
        make(OUTER - width, OUTER, os.path.join(here, "Ring_T%02d.tga" % t))
    print("ok")


if __name__ == "__main__":
    main()
