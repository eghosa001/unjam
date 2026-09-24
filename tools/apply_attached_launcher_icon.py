from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "store_assets" / "unjam_google_play_icon_512.png"
MAIN = ROOT / "assets" / "icon_user_512.png"
ADAPTIVE = ROOT / "assets" / "icon_user_adaptive_432.png"
PROJECT = ROOT / "project.godot"
PRESET = ROOT / "export_presets.cfg"
ICON_TEST = ROOT / "tests" / "validate_launcher_icon_safe_zone.gd"
RELEASE_CHECK = ROOT / "tools" / "validate_release_contract.py"


def make_background(size: int) -> Image.Image:
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            nx = x / max(1, size - 1)
            ny = y / max(1, size - 1)
            # Bright royal-blue upper field with a deep indigo lower edge.
            top = (14, 102, 224)
            bottom = (31, 17, 119)
            t = min(1.0, max(0.0, ny * 0.92 + abs(nx - 0.5) * 0.08))
            r = int(top[0] * (1.0 - t) + bottom[0] * t)
            g = int(top[1] * (1.0 - t) + bottom[1] * t)
            b = int(top[2] * (1.0 - t) + bottom[2] * t)
            # Cyan center glow similar to the supplied artwork.
            dx = nx - 0.5
            dy = ny - 0.30
            glow = max(0.0, 1.0 - (dx * dx / 0.18 + dy * dy / 0.24))
            r = min(255, int(r + 10 * glow))
            g = min(255, int(g + 58 * glow))
            b = min(255, int(b + 36 * glow))
            px[x, y] = (r, g, b)
    return img


def feather_mask(size: int, feather: int) -> Image.Image:
    mask = Image.new("L", (size, size), 255)
    draw = ImageDraw.Draw(mask)
    for i in range(feather):
        alpha = int(255 * (i + 1) / feather)
        draw.rectangle((i, i, size - 1 - i, size - 1 - i), outline=alpha)
    return mask.filter(ImageFilter.GaussianBlur(radius=1.2))


src = Image.open(SOURCE).convert("RGB")
if src.size != (512, 512):
    src = src.resize((512, 512), Image.Resampling.LANCZOS)

# The approved attached artwork is the detailed U itself, without the old
# UNJAM wordmark. The wordmark starts below the glossy U in this source.
# Preserve the complete U through y=373, then fill the square with that mark.
icon = src.crop((0, 0, 512, 374)).resize((512, 512), Image.Resampling.LANCZOS)
icon = icon.filter(ImageFilter.UnsharpMask(radius=0.9, percent=135, threshold=2))
MAIN.parent.mkdir(parents=True, exist_ok=True)
icon.save(MAIN, "PNG", optimize=True)

# Keep the Play listing icon synchronized with the launcher artwork.
icon.save(SOURCE, "PNG", optimize=True)

# Samsung/Android adaptive icon: keep the complete glossy composition inside a
# comfortable safe region and feather its blue field into a matching background.
adaptive = make_background(432).convert("RGBA")
safe = icon.resize((380, 380), Image.Resampling.LANCZOS).convert("RGBA")
mask = feather_mask(380, 18)
adaptive.alpha_composite(Image.composite(safe, Image.new("RGBA", safe.size, (0, 0, 0, 0)), mask), (26, 26))
adaptive.save(ADAPTIVE, "PNG", optimize=True)

project = PROJECT.read_text(encoding="utf-8")
project = project.replace(
    'config/icon="res://assets/icon.svg"',
    'config/icon="res://assets/icon_user_512.png"',
)
PROJECT.write_text(project, encoding="utf-8")

preset = PRESET.read_text(encoding="utf-8")
preset = preset.replace(
    'launcher_icons/main_192x192="res://assets/icon.svg"',
    'launcher_icons/main_192x192="res://assets/icon_user_512.png"',
)
preset = preset.replace(
    'launcher_icons/adaptive_foreground_432x432="res://assets/icon_adaptive_foreground.svg"',
    'launcher_icons/adaptive_foreground_432x432="res://assets/icon_user_adaptive_432.png"',
)
PRESET.write_text(preset, encoding="utf-8")

ICON_TEST.write_text(
    '''extends SceneTree

func _initialize() -> void:
    var failures: Array[String] = []
    var project := FileAccess.get_file_as_string("res://project.godot")
    var preset := FileAccess.get_file_as_string("res://export_presets.cfg")
    var main := load("res://assets/icon_user_512.png") as Texture2D
    var adaptive := load("res://assets/icon_user_adaptive_432.png") as Texture2D

    if main == null or main.get_width() != 512 or main.get_height() != 512:
        failures.append("Main launcher icon must be a crisp 512x512 PNG")
    if adaptive == null or adaptive.get_width() != 432 or adaptive.get_height() != 432:
        failures.append("Adaptive launcher foreground must be 432x432")
    if 'config/icon="res://assets/icon_user_512.png"' not in project:
        failures.append("project.godot is not wired to the supplied glossy U icon")
    for token in [
        'launcher_icons/main_192x192="res://assets/icon_user_512.png"',
        'launcher_icons/adaptive_foreground_432x432="res://assets/icon_user_adaptive_432.png"',
        'launcher_icons/adaptive_background_432x432="res://assets/icon_adaptive_background.svg"',
    ]:
        if token not in preset:
            failures.append("Android launcher preset missing: %s" % token)

    if not failures.is_empty():
        for failure in failures:
            push_error(failure)
        quit(1)
        return
    print("Launcher icon PNG wiring validated.")
    quit(0)
''',
    encoding="utf-8",
)

release = RELEASE_CHECK.read_text(encoding="utf-8")
release = release.replace(
    "    icon_path = root / 'assets' / 'icon.svg'\n"
    "    adaptive_bg_path = root / 'assets' / 'icon_adaptive_background.svg'\n"
    "    adaptive_fg_path = root / 'assets' / 'icon_adaptive_foreground.svg'",
    "    icon_path = root / 'assets' / 'icon_user_512.png'\n"
    "    adaptive_bg_path = root / 'assets' / 'icon_adaptive_background.svg'\n"
    "    adaptive_fg_path = root / 'assets' / 'icon_user_adaptive_432.png'",
)
release = release.replace(
    "    icon = icon_path.read_text(encoding='utf-8')\n"
    "    adaptive_bg = adaptive_bg_path.read_text(encoding='utf-8')\n"
    "    adaptive_fg = adaptive_fg_path.read_text(encoding='utf-8')",
    "    adaptive_bg = adaptive_bg_path.read_text(encoding='utf-8')",
)
start_token = "    for token in (\n        'viewBox=\"0 0 512 512\"'"
end_token = "            errors.append(f'Android launcher icon is not wired to the current SVG source: {token}')"
start = release.find(start_token)
end = release.find(end_token, start)
if start < 0 or end < 0:
    raise RuntimeError("Could not locate legacy launcher validation block")
end += len(end_token)
new_block = '''    if not icon_path.exists():
        errors.append('512x512 supplied glossy U launcher PNG is missing')
    if not adaptive_fg_path.exists():
        errors.append('432x432 adaptive glossy U foreground PNG is missing')
    if 'viewBox="0 0 432 432"' not in adaptive_bg:
        errors.append('adaptive icon background must remain a 432x432 Android layer')

    if 'config/icon="res://assets/icon_user_512.png"' not in project:
        errors.append('project launcher icon is not wired to the supplied glossy U PNG')

    for token in (
        'launcher_icons/main_192x192="res://assets/icon_user_512.png"',
        'launcher_icons/adaptive_foreground_432x432="res://assets/icon_user_adaptive_432.png"',
        'launcher_icons/adaptive_background_432x432="res://assets/icon_adaptive_background.svg"',
    ):
        if token not in preset:
            errors.append(f'Android launcher icon is not wired to current PNG assets: {token}')'''
release = release[:start] + new_block + release[end:]
RELEASE_CHECK.write_text(release, encoding="utf-8")

# Fast, exact sanity checks only.
assert Image.open(MAIN).size == (512, 512)
assert Image.open(ADAPTIVE).size == (432, 432)
assert 'icon_user_512.png' in PROJECT.read_text(encoding="utf-8")
assert 'icon_user_adaptive_432.png' in PRESET.read_text(encoding="utf-8")
print("Glossy U launcher assets generated and wired.")
