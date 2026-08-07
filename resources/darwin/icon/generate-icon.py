# Generates resources/darwin/code.icns (the Dex app icon) from mark-source.png.
#
# The source is used as-is — the photographed paper triangle on its dark
# backdrop, shadow and texture included. This script only cleans two artifacts,
# crops to centre the mark, and rounds the corners for macOS.
#
#   python3 generate-icon.py
#   iconutil -c icns Dex.iconset -o ../code.icns
#
# Requires pillow, numpy, scipy.

from PIL import Image
import numpy as np, os, shutil
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.join(HERE, 'mark-source.png')

# Gemini's sparkle watermark in the source, with a few px of margin
WATERMARK = (1750, 1750, 1865, 1865)

# Vertical centring, 0 = bounding box, 1 = centre of mass.
#
# A downward triangle carries its mass in the wide top bar and tapers to a
# point, so its centroid sits ~150px above its bbox centre in the source. Bbox
# centring therefore reads low, and centroid centring reads high — the apex ends
# up nearer the bottom edge than the top bar is to the top. Splitting the
# difference is what actually looks centred.
CENTRING = 0.5

MARK_LUM = 140  # the paper reads ~241, the backdrop ~18


def clean_source():
    """The source photo with its two rendering artifacts removed."""
    img = np.array(Image.open(SOURCE).convert('RGB'))

    # the last row is a bright artifact (mean luminance 154 against a ~18
    # backdrop); carry the row above it down
    img[-1] = img[-2]

    # patch the watermark with clean backdrop from the same rows further left.
    # The mark ends at y=1485, so that band is pure background.
    x0, y0, x1, y1 = WATERMARK
    w = x1 - x0
    img[y0:y1, x0:x1] = img[y0:y1, x0 - 2 * w:x1 - 2 * w]

    return img


def crop_centred(img):
    """Largest square crop that centres the mark per CENTRING."""
    lum = img.mean(axis=2)

    # largest bright component: the mark itself, not backdrop speckle
    lab, n = ndimage.label(lum > MARK_LUM)
    sizes = ndimage.sum(lum > MARK_LUM, lab, range(1, n + 1))
    ys, xs = np.nonzero(lab == int(np.argmax(sizes)) + 1)

    cx = (xs.min() + xs.max()) / 2
    cy_bbox = (ys.min() + ys.max()) / 2
    cy = cy_bbox + (ys.mean() - cy_bbox) * CENTRING

    h, w, _ = img.shape
    half = int(min(cx, w - cx, cy, h - cy))
    return img[int(cy) - half:int(cy) + half, int(cx) - half:int(cx) + half]


def squircle_alpha(size, n=5.0, ss=4):
    """Apple-style superellipse (squircle), antialiased via supersampling."""
    big = size * ss
    r = big / 2.0
    y, x = np.mgrid[0:big, 0:big]
    v = np.abs((x + 0.5 - r) / r)**n + np.abs((y + 0.5 - r) / r)**n
    return (v <= 1.0).astype(np.float64).reshape(size, ss, size, ss).mean(axis=(1, 3))


PLATE = Image.fromarray(crop_centred(clean_source()), 'RGB')


def make(size):
    # macOS grid: the plate occupies 824/1024 of the canvas
    plate_px = int(round(size * 824 / 1024))
    inset = (size - plate_px) // 2

    plate = PLATE.resize((plate_px, plate_px), Image.LANCZOS)
    plate.putalpha(Image.fromarray((squircle_alpha(plate_px) * 255).astype(np.uint8), 'L'))

    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    canvas.paste(plate, (inset, inset))
    return canvas


for s in (16, 32, 64, 128, 256, 512, 1024):
    make(s).save(f'dex_{s}.png')
    print('wrote', s)

# assemble the iconset iconutil expects: each @2x is the next size up
os.makedirs('Dex.iconset', exist_ok=True)
for src, names in (
    (16, ('icon_16x16.png',)),
    (32, ('icon_16x16@2x.png', 'icon_32x32.png')),
    (64, ('icon_32x32@2x.png',)),
    (128, ('icon_128x128.png',)),
    (256, ('icon_128x128@2x.png', 'icon_256x256.png')),
    (512, ('icon_256x256@2x.png', 'icon_512x512.png')),
    (1024, ('icon_512x512@2x.png',)),
):
    for name in names:
        shutil.copyfile(f'dex_{src}.png', os.path.join('Dex.iconset', name))
print('wrote Dex.iconset')
