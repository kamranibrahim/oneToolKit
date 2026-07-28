#!/usr/bin/env python3
"""Generate professional App Store marketing screenshots (1242×2688)."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1242, 2688
OUT = Path(__file__).resolve().parent / "marketing"
SRC = Path(__file__).resolve().parent

# Fonts
BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
REG = "/System/Library/Fonts/Supplemental/Arial.ttf"
HELV_BOLD = ("/System/Library/Fonts/Helvetica.ttc", 1)  # Bold


def font(path: str | tuple, size: int) -> ImageFont.FreeTypeFont:
    if isinstance(path, tuple):
        return ImageFont.truetype(path[0], size, index=path[1])
    return ImageFont.truetype(path, size)


def lerp(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))  # type: ignore


def vertical_gradient(
    size: tuple[int, int],
    top: tuple[int, int, int],
    bottom: tuple[int, int, int],
) -> Image.Image:
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(size[1]):
        c = lerp(top, bottom, y / max(size[1] - 1, 1))
        for x in range(size[0]):
            px[x, y] = c
    return img


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=255)
    return mask


def draw_centered_text(
    draw: ImageDraw.ImageDraw,
    text: str,
    y: int,
    fnt: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int],
    max_width: int,
) -> int:
    """Draw wrapped centered text; returns bottom y."""
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        trial = f"{current} {word}".strip()
        if draw.textlength(trial, font=fnt) <= max_width:
            current = trial
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)

    line_h = int(fnt.size * 1.15)
    for i, line in enumerate(lines):
        tw = draw.textlength(line, font=fnt)
        x = (W - tw) / 2
        draw.text((x, y + i * line_h), line, font=fnt, fill=fill)
    return y + len(lines) * line_h


def phone_frame(screen: Image.Image, frame_w: int) -> Image.Image:
    """Wrap screenshot in a thin black iPhone-style bezel.

    Screenshots already include the status bar, so we do not draw a
    fake Dynamic Island on top of the UI.
    """
    aspect = screen.height / screen.width
    bezel = 14
    screen_w = frame_w - bezel * 2
    screen_h = int(screen_w * aspect)
    frame_h = screen_h + bezel * 2
    frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))

    # Outer body (graphite)
    body = Image.new("RGBA", (frame_w, frame_h), (28, 28, 30, 255))
    body_mask = rounded_mask((frame_w, frame_h), 86)
    frame.paste(body, (0, 0), body_mask)

    # Subtle highlight rim
    rim = Image.new("RGBA", (frame_w - 4, frame_h - 4), (55, 55, 58, 255))
    rim_mask = rounded_mask((frame_w - 4, frame_h - 4), 84)
    frame.paste(rim, (2, 2), rim_mask)

    # Screen (screenshots already have status bar)
    screen_resized = screen.convert("RGBA").resize((screen_w, screen_h), Image.Resampling.LANCZOS)
    screen_mask = rounded_mask((screen_w, screen_h), 72)
    frame.paste(screen_resized, (bezel, bezel), screen_mask)

    return frame


def drop_shadow(img: Image.Image, blur: int = 40, offset: tuple[int, int] = (0, 28), opacity: int = 90) -> Image.Image:
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    alpha = img.split()[-1]
    shadow_layer = Image.new("RGBA", img.size, (0, 0, 0, opacity))
    shadow.paste(shadow_layer, (0, 0), alpha)
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    canvas = Image.new("RGBA", (img.width + abs(offset[0]) + blur * 2, img.height + abs(offset[1]) + blur * 2), (0, 0, 0, 0))
    ox = blur + max(offset[0], 0)
    oy = blur + max(offset[1], 0)
    canvas.paste(shadow, (ox + offset[0], oy + offset[1]), shadow)
    canvas.paste(img, (ox, oy), img)
    return canvas


SCREENS = [
    {
        "file": "01_home.png",
        "out": "01_home_marketing.png",
        "headline": "85+ Tools.\nOne Private App.",
        "sub": "PDF, images, QR & utilities — offline by default",
        "colors": ((10, 90, 220), (0, 55, 160)),
    },
    {
        "file": "02_tools.png",
        "out": "02_tools_marketing.png",
        "headline": "Every Tool\nIn One Place",
        "sub": "Browse categories. Find what you need fast",
        "colors": ((55, 65, 90), (25, 30, 50)),
    },
    {
        "file": "03_pdf.png",
        "out": "03_pdf_marketing.png",
        "headline": "PDF Tools\nThat Just Work",
        "sub": "Merge, split, compress, protect & scan",
        "colors": ((220, 45, 55), (150, 20, 35)),
    },
    {
        "file": "04_ai_tools.png",
        "out": "04_ai_tools_marketing.png",
        "headline": "AI That Stays\nOn Your Device",
        "sub": "OCR, translate & summarize — privately",
        "colors": ((230, 40, 95), (160, 15, 60)),
    },
    {
        "file": "05_developer.png",
        "out": "05_developer_marketing.png",
        "headline": "Built for\nDevelopers",
        "sub": "JWT, UUID, converters, passwords & more",
        "colors": ((40, 160, 210), (15, 90, 140)),
    },
    {
        "file": "06_qr_barcode.png",
        "out": "06_qr_barcode_marketing.png",
        "headline": "QR & Barcodes\nIn Seconds",
        "sub": "Generate, scan, Wi‑Fi, contacts & email",
        "colors": ((40, 170, 90), (15, 110, 55)),
    },
]


def compose(spec: dict) -> Image.Image:
    top, bottom = spec["colors"]
    bg = vertical_gradient((W, H), top, bottom).convert("RGBA")

    # Soft vignette / light orb for depth
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.ellipse([-200, -400, W + 200, 900], fill=(255, 255, 255, 28))
    bg = Image.alpha_composite(bg, overlay)

    draw = ImageDraw.Draw(bg)
    headline_font = font(HELV_BOLD, 92)
    sub_font = font(REG, 36)

    # Headline block
    headline_top = 150
    max_text_w = W - 120

    # Draw multi-line headline (explicit \n)
    y = headline_top
    for line in spec["headline"].split("\n"):
        tw = draw.textlength(line, font=headline_font)
        draw.text(((W - tw) / 2, y), line, font=headline_font, fill=(255, 255, 255))
        y += int(headline_font.size * 1.12)

    y += 28
    # Subtitle
    sub = spec["sub"]
    # wrap subtitle
    words = sub.split()
    lines: list[str] = []
    cur = ""
    for w in words:
        trial = f"{cur} {w}".strip()
        if draw.textlength(trial, font=sub_font) <= max_text_w:
            cur = trial
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    for line in lines:
        tw = draw.textlength(line, font=sub_font)
        draw.text(((W - tw) / 2, y), line, font=sub_font, fill=(255, 255, 255, 220))
        y += int(sub_font.size * 1.35)

    # Phone
    screen = Image.open(SRC / spec["file"])
    frame_w = 980
    phone = phone_frame(screen, frame_w)
    phone_shadowed = drop_shadow(phone, blur=48, offset=(0, 36), opacity=110)

    # Position: centered horizontally, hanging toward bottom
    px = (W - phone_shadowed.width) // 2
    # Align so phone starts below text and extends past bottom slightly
    phone_top = 560
    py = phone_top

    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    canvas.paste(bg, (0, 0))
    canvas.paste(phone_shadowed, (px, py), phone_shadowed)

    # Crop to exact canvas (phone may extend below)
    final = canvas.crop((0, 0, W, H))
    return final.convert("RGB")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for spec in SCREENS:
        print(f"Rendering {spec['out']}…")
        img = compose(spec)
        assert img.size == (W, H), img.size
        path = OUT / spec["out"]
        img.save(path, "PNG", optimize=True)
        print(f"  → {path} ({img.size[0]}×{img.size[1]})")
    print("Done.")


if __name__ == "__main__":
    main()
