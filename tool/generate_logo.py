#!/usr/bin/env python3
"""Pale profile card for the FormPocket launcher and splash."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SIZE = 1024
PAGE = (244, 247, 251, 255)
WHITE = (255, 255, 255, 255)
BLUE = (47, 107, 255, 255)
INK = (22, 24, 29, 255)
MUTED = (176, 188, 204, 255)


def _shadow(canvas: Image.Image, box: tuple[int, int, int, int], radius: int) -> None:
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    x0, y0, x1, y1 = box
    ImageDraw.Draw(layer).rounded_rectangle(
        (x0, y0 + 16, x1, y1 + 22),
        radius=radius,
        fill=(20, 32, 51, 36),
    )
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(22)))


def draw_card(canvas: Image.Image, box: tuple[int, int, int, int]) -> None:
    x0, y0, x1, y1 = box
    width = x1 - x0
    height = y1 - y0
    radius = int(height * 0.22)
    _shadow(canvas, box, radius)
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle(box, radius=radius, fill=WHITE)

    circle = int(height * 0.46)
    cx0 = x0 + int(width * 0.09)
    cy0 = y0 + (height - circle) // 2
    draw.ellipse((cx0, cy0, cx0 + circle, cy0 + circle), fill=BLUE)

    line_h = max(18, int(height * 0.075))
    gap = int(height * 0.07)
    text_x = cx0 + circle + int(width * 0.07)
    name_w = int(width * 0.38)
    detail_w = int(width * 0.26)
    block_h = line_h * 2 + gap
    name_y = y0 + (height - block_h) // 2
    draw.rounded_rectangle(
        (text_x, name_y, text_x + name_w, name_y + line_h),
        radius=line_h // 2,
        fill=INK,
    )
    detail_y = name_y + line_h + gap
    draw.rounded_rectangle(
        (text_x, detail_y, text_x + detail_w, detail_y + line_h),
        radius=line_h // 2,
        fill=MUTED,
    )


def main() -> None:
    assets = ROOT / "assets"
    assets.mkdir(exist_ok=True)

    logo = Image.new("RGBA", (SIZE, SIZE), PAGE)
    card_w, card_h = 760, 500
    left = (SIZE - card_w) // 2
    top = (SIZE - card_h) // 2
    draw_card(logo, (left, top, left + card_w, top + card_h))
    logo.convert("RGB").save(assets / "logo.png", optimize=True)

    splash = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    splash_w, splash_h = 520, 360
    s_left = (SIZE - splash_w) // 2
    s_top = (SIZE - splash_h) // 2
    draw_card(splash, (s_left, s_top, s_left + splash_w, s_top + splash_h))
    splash_path = ROOT / "android/app/src/main/res/drawable-nodpi/splash_icon.png"
    splash_path.parent.mkdir(parents=True, exist_ok=True)
    splash.save(splash_path, optimize=True)
    print(f"wrote {assets / 'logo.png'}")
    print(f"wrote {splash_path}")


if __name__ == "__main__":
    main()
