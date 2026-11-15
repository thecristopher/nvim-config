#!/usr/bin/env python3
"""Crops images/<name>.* into images/portraits/<name>.jpg with the face in the middle, and
writes images/portraits/<name>_figure.jpg, the whole photo, for the names in FIGURES.

Each portrait is 276x336. FACES says where the face sits in the original and how much of its
height the crop takes, so a face near an edge or a small figure still lands centered and big
enough to read in the stage and the HUD. Only the standard library is needed, plus ffmpeg.

Usage:
    python3 scripts/portraits.py              # every portrait
    python3 scripts/portraits.py claire ada   # just these

Figures are 331x593, the shape of a phone photo, for the views that show someone whole, like
the dressing room mirror.
"""

import glob
import os
import shutil
import subprocess
import sys

IMAGES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "images")
WIDTH = 276
HEIGHT = 336
FIGURE_WIDTH = 331
FIGURE_HEIGHT = 593
# contrast, color and sharpness lifted so the portraits survive half block rendering
LIFT = "eq=contrast=1.15:saturation=1.25,unsharp=5:5:0.8"

# name: (face x, face y, crop height), all as fractions of the original image
FACES = {
    "ada": (0.58, 0.25, 0.50),
    "claire": (0.50, 0.43, 0.90),
    # the whole width of her photos, so the costume shows and not only her face
    "elizabeth_ada": (0.50, 0.43, 1.0),
    "elizabeth_psylocke": (0.50, 0.46, 1.0),
    "elizabeth_scarlet_witch": (0.50, 0.42, 1.0),
    "elizabeth_shadowheart": (0.50, 0.39, 1.0),
    "jill": (0.61, 0.225, 0.45),
    "leon": (0.41, 0.175, 0.38),
    "malenia": (0.59, 0.263, 0.32),
    "maliketh": (0.45, 0.45, 0.50),
    "marika": (0.51, 0.415, 0.40),
    "melina": (0.48, 0.24, 0.45),
    "mohgwyn": (0.365, 0.45, 0.35),
    "ranni": (0.425, 0.233, 0.32),
    "wesker": (0.50, 0.36, 0.60),
}


# names whose whole photo is also kept as a figure
FIGURES = ["elizabeth_ada", "elizabeth_psylocke", "elizabeth_scarlet_witch", "elizabeth_shadowheart"]


def crop_box(size, face, aspect=(WIDTH, HEIGHT)):
    """Returns the crop around a face, kept inside the image.

    Args:
        size: (width, height) of the original.
        face: (x, y, crop height) as fractions of the original.
        aspect: (width, height) the crop takes the shape of.

    Returns:
        (width, height, left, top) in pixels, with the given aspect.
    """
    image_width, image_height = size
    x, y, share = face
    height = min(image_height, round(image_height * share))
    width = round(height * aspect[0] / aspect[1])
    if width > image_width:
        width = image_width
        height = round(width * aspect[1] / aspect[0])
    # near an edge the face moves off center rather than the crop leaving the image
    left = min(max(0, round(image_width * x - width / 2)), image_width - width)
    top = min(max(0, round(image_height * y - height / 2)), image_height - height)
    return width, height, left, top


def source_of(name):
    """Returns the original image for a portrait, whatever its extension."""
    found = sorted(glob.glob(os.path.join(IMAGES, name + ".*")))
    if not found:
        sys.exit(f"no original for {name} in images/")
    return found[0]


def size_of(path):
    """Returns (width, height) of an image, read by ffprobe."""
    output = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
         "stream=width,height", "-of", "csv=p=0", path],
        check=True, capture_output=True, text=True,
    ).stdout
    width, height = output.strip().split(",")
    return int(width), int(height)


def render(source, box, size, target):
    """Crops a box out of the original, scales it to size and lifts it into target."""
    width, height, left, top = box
    subprocess.run(
        ["ffmpeg", "-loglevel", "error", "-y", "-i", source, "-vf",
         f"crop={width}:{height}:{left}:{top},scale={size[0]}:{size[1]}:flags=lanczos,{LIFT}",
         "-frames:v", "1", "-q:v", "2", target],
        check=True,
    )


def build(name):
    """Writes images/portraits/<name>.jpg from its original, and its figure when it has one."""
    source = source_of(name)
    size = size_of(source)
    portraits = os.path.join(IMAGES, "portraits")
    render(source, crop_box(size, FACES[name]), (WIDTH, HEIGHT), os.path.join(portraits, name + ".jpg"))
    if name in FIGURES:
        figure = (FIGURE_WIDTH, FIGURE_HEIGHT)
        box = crop_box(size, (0.5, 0.5, 1.0), figure)
        render(source, box, figure, os.path.join(portraits, name + "_figure.jpg"))


def main():
    if not shutil.which("ffmpeg"):
        sys.exit("ffmpeg is needed: brew install ffmpeg")
    for name in sys.argv[1:] or list(FACES):
        build(name)
        print(f"portraits/{name}.jpg ok")


if __name__ == "__main__":
    main()
