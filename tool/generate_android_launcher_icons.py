from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "ChatGPT Image 2026年7月9日 00_43_02.png"
RES = ROOT / "android" / "app" / "src" / "main" / "res"
SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def save_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGBA").save(path, "PNG", optimize=True)


def icon_master(source: Image.Image) -> Image.Image:
    source = source.convert("RGB")
    crop_side = round(min(source.size) * 0.82)
    center_x = source.width / 2
    center_y = source.height * 0.48
    left = round(center_x - crop_side / 2)
    top = round(center_y - crop_side / 2)
    cropped = source.crop((left, top, left + crop_side, top + crop_side))
    cropped = ImageEnhance.Brightness(cropped).enhance(1.12)
    cropped = ImageEnhance.Contrast(cropped).enhance(1.08)
    cropped = ImageEnhance.Sharpness(cropped).enhance(1.08)
    return cropped.convert("RGBA")


def circle_mask(size: int) -> Image.Image:
    scale = 4
    mask = Image.new("L", (size * scale, size * scale), 0)
    ImageDraw.Draw(mask).ellipse(
        (0, 0, size * scale - 1, size * scale - 1),
        fill=255,
    )
    return mask.resize((size, size), Image.Resampling.LANCZOS)


def main() -> None:
    master = icon_master(Image.open(SOURCE))

    artwork = master.resize((1024, 1024), Image.Resampling.LANCZOS)
    save_png(artwork, ROOT / "assets" / "images" / "app_icon.png")
    save_png(artwork, RES / "drawable-nodpi" / "ic_launcher_artwork.png")
    save_png(
        master.resize((512, 512), Image.Resampling.LANCZOS),
        ROOT / "assets" / "icon_512.png",
    )

    for density, size in SIZES.items():
        square = master.resize((size, size), Image.Resampling.LANCZOS)
        save_png(square, RES / density / "ic_launcher.png")

        round_icon = square.copy()
        round_icon.putalpha(
            ImageChops.multiply(round_icon.getchannel("A"), circle_mask(size)),
        )
        save_png(round_icon, RES / density / "ic_launcher_round.png")


if __name__ == "__main__":
    main()
