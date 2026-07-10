# StudyFlow Android Launcher Icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the black Huawei launcher result with a conventional Android launcher icon set derived from the supplied StudyFlow artwork.

**Architecture:** Keep the edited artwork as a color background layer, add a transparent vector foreground and an explicit monochrome vector, and generate standard legacy density PNGs. Regression tests inspect Manifest/XML structure, PNG dimensions, and alpha behavior before the release APK is built and inspected with `aapt2`.

**Tech Stack:** Flutter test, Android adaptive icon XML, VectorDrawable, Python/Pillow for deterministic resizing, Android `aapt2`.

---

## File map

- Modify `test/android_launch_cover_test.dart`: launcher resource regression tests.
- Create `tool/generate_android_launcher_icons.py`: reproducible sRGB conversion and density export.
- Replace `assets/images/app_icon.png` and `assets/icon_512.png`: icon-ready artwork derived from the supplied PNG.
- Replace `android/app/src/main/res/mipmap-*/ic_launcher*.png`: legacy launcher bitmaps.
- Create `android/app/src/main/res/drawable-nodpi/ic_launcher_artwork.png`: adaptive color artwork.
- Create `android/app/src/main/res/drawable/ic_launcher_foreground.xml`: transparent color foreground mark.
- Create `android/app/src/main/res/drawable/ic_launcher_monochrome.xml`: themed icon mark.
- Modify `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher*.xml`: color adaptive icon layers.
- Create `android/app/src/main/res/mipmap-anydpi-v33/ic_launcher*.xml`: adaptive icons with monochrome layers.

### Task 1: Add a failing launcher resource regression

**Files:**
- Modify: `test/android_launch_cover_test.dart`

- [ ] **Step 1: Replace the file-size foreground assertion with structural tests**

Add checks that v26 uses drawable artwork/foreground, v33 contains a monochrome layer, and legacy PNG dimensions are 48/72/96/144/192 pixels. Decode PNGs with `dart:ui` and require round icons to have transparent corners.

```dart
import 'dart:io';
import 'dart:ui' as ui;

Future<ui.Image> decodePng(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  return (await codec.getNextFrame()).image;
}

test('adaptive icons provide color and monochrome layers', () {
  for (final name in ['ic_launcher.xml', 'ic_launcher_round.xml']) {
    final v26 = File('android/app/src/main/res/mipmap-anydpi-v26/$name')
        .readAsStringSync();
    final v33 = File('android/app/src/main/res/mipmap-anydpi-v33/$name')
        .readAsStringSync();
    expect(v26, contains('@drawable/ic_launcher_artwork'));
    expect(v26, contains('@drawable/ic_launcher_foreground'));
    expect(v33, contains('@drawable/ic_launcher_monochrome'));
  }
});

test('legacy launcher icons have standard dimensions and round alpha', () async {
  const sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };
  for (final entry in sizes.entries) {
    final base = 'android/app/src/main/res/${entry.key}';
    final square = await decodePng('$base/ic_launcher.png');
    final round = await decodePng('$base/ic_launcher_round.png');
    expect((square.width, square.height), (entry.value, entry.value));
    expect((round.width, round.height), (entry.value, entry.value));
    final rgba = await round.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(rgba!.getUint8(3), 0);
  }
});
```

- [ ] **Step 2: Run the focused test and verify RED**

Run: `cmd /c call F:\Phone\flutter\bin\flutter.bat test test\android_launch_cover_test.dart`

Expected: FAIL because `mipmap-anydpi-v33` and drawable launcher layers do not exist and current round icons have opaque corners.

### Task 2: Prepare the icon-ready color artwork

**Files:**
- Replace: `assets/images/app_icon.png`

- [ ] **Step 1: Prepare the supplied image deterministically**

Use `ChatGPT Image 2026年7月9日 00_43_02.png` directly. The generator in Task 3 takes a centered 82% crop biased slightly upward, applies brightness `1.12`, contrast `1.08`, and sharpness `1.08`, then writes the icon-ready result to `assets/images/app_icon.png`. No content is generated or replaced.

### Task 3: Add deterministic Android icon generation

**Files:**
- Create: `tool/generate_android_launcher_icons.py`
- Generate: `assets/icon_512.png`
- Generate: `android/app/src/main/res/drawable-nodpi/ic_launcher_artwork.png`
- Generate: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- Generate: `android/app/src/main/res/mipmap-*/ic_launcher_round.png`

- [ ] **Step 1: Create the generator**

Create `tool/generate_android_launcher_icons.py` with this implementation:

```python
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageOps


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


def circle_mask(size: int) -> Image.Image:
    scale = 4
    mask = Image.new("L", (size * scale, size * scale), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size * scale - 1, size * scale - 1), fill=255)
    return mask.resize((size, size), Image.Resampling.LANCZOS)


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    side = min(source.size)
    master = ImageOps.fit(
        source,
        (side, side),
        method=Image.Resampling.LANCZOS,
        centering=(0.5, 0.5),
    )

    artwork = master.resize((1024, 1024), Image.Resampling.LANCZOS)
    save_png(artwork, RES / "drawable-nodpi" / "ic_launcher_artwork.png")
    save_png(master.resize((512, 512), Image.Resampling.LANCZOS), ROOT / "assets" / "icon_512.png")

    for density, size in SIZES.items():
        square = master.resize((size, size), Image.Resampling.LANCZOS)
        save_png(square, RES / density / "ic_launcher.png")

        round_icon = square.copy()
        round_icon.putalpha(ImageChops.multiply(round_icon.getchannel("A"), circle_mask(size)))
        save_png(round_icon, RES / density / "ic_launcher_round.png")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Run the generator**

Run: `python tool\generate_android_launcher_icons.py`

Expected: all listed PNGs are regenerated; legacy images have the requested dimensions and round variants have transparent corners.

### Task 4: Add conventional adaptive and themed icon layers

**Files:**
- Create: `android/app/src/main/res/drawable/ic_launcher_foreground.xml`
- Create: `android/app/src/main/res/drawable/ic_launcher_monochrome.xml`
- Modify: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
- Modify: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml`
- Create: `android/app/src/main/res/mipmap-anydpi-v33/ic_launcher.xml`
- Create: `android/app/src/main/res/mipmap-anydpi-v33/ic_launcher_round.xml`

- [ ] **Step 1: Create the vector marks**

Create `ic_launcher_foreground.xml` with the following 108 dp VectorDrawable. Its geometry stays inside the central 66 dp safe zone:

```xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#00000000"
        android:pathData="M22,68 C32,62 43,62 54,68 L54,85 C43,79 32,79 22,84 Z M54,68 C65,62 76,62 86,68 L86,84 C76,79 65,79 54,85 Z"
        android:strokeColor="#D9DDF7FF"
        android:strokeLineCap="round"
        android:strokeLineJoin="round"
        android:strokeWidth="2.6" />
    <path
        android:fillColor="#1A9DEBFF"
        android:pathData="M29,36 L55,36 L55,64 L29,64 Z"
        android:strokeColor="#D9DDF7FF"
        android:strokeLineJoin="round"
        android:strokeWidth="2.4" />
    <path
        android:fillColor="#00000000"
        android:pathData="M34,44 L37,47 L42,41 M46,44 L51,44 M34,52 L37,55 L42,49 M46,52 L51,52"
        android:strokeColor="#F2FFFFFF"
        android:strokeLineCap="round"
        android:strokeLineJoin="round"
        android:strokeWidth="2.2" />
    <path
        android:fillColor="#269DEBFF"
        android:pathData="M77,28 C86.4,28 94,35.6 94,45 C94,54.4 86.4,62 77,62 C67.6,62 60,54.4 60,45 C60,35.6 67.6,28 77,28 Z"
        android:strokeColor="#E6DDF7FF"
        android:strokeWidth="2.6" />
    <path
        android:fillColor="#00000000"
        android:pathData="M77,34 L77,46 L85,41"
        android:strokeColor="#F2FFFFFF"
        android:strokeLineCap="round"
        android:strokeLineJoin="round"
        android:strokeWidth="2.6" />
</vector>
```

Create `ic_launcher_monochrome.xml` with the same geometry and opaque white strokes/fills so launcher tinting produces a recognizable mark:

```xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="#00000000" android:pathData="M22,68 C32,62 43,62 54,68 L54,85 C43,79 32,79 22,84 Z M54,68 C65,62 76,62 86,68 L86,84 C76,79 65,79 54,85 Z" android:strokeColor="#FFFFFFFF" android:strokeLineCap="round" android:strokeLineJoin="round" android:strokeWidth="4" />
    <path android:fillColor="#FFFFFFFF" android:pathData="M29,36 L55,36 L55,64 L29,64 Z" />
    <path android:fillColor="#00000000" android:pathData="M34,44 L37,47 L42,41 M46,44 L51,44 M34,52 L37,55 L42,49 M46,52 L51,52" android:strokeColor="#FF000000" android:strokeLineCap="round" android:strokeLineJoin="round" android:strokeWidth="2.2" />
    <path android:fillColor="#FFFFFFFF" android:pathData="M77,28 C86.4,28 94,35.6 94,45 C94,54.4 86.4,62 77,62 C67.6,62 60,54.4 60,45 C60,35.6 67.6,28 77,28 Z" />
    <path android:fillColor="#00000000" android:pathData="M77,34 L77,46 L85,41" android:strokeColor="#FF000000" android:strokeLineCap="round" android:strokeLineJoin="round" android:strokeWidth="2.6" />
</vector>
```

- [ ] **Step 2: Wire the adaptive XML resources**

The v26 files must contain:

```xml
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_artwork" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
```

The v33 files must additionally contain:

```xml
<monochrome android:drawable="@drawable/ic_launcher_monochrome" />
```

- [ ] **Step 3: Run the focused test and verify GREEN**

Run: `cmd /c call F:\Phone\flutter\bin\flutter.bat test test\android_launch_cover_test.dart`

Expected: PASS with all launcher resource tests green.

### Task 5: Verify the complete application and APK

**Files:**
- Verify all modified files; do not change unrelated working-tree edits.

- [ ] **Step 1: Run all Flutter tests**

Run: `cmd /c call F:\Phone\flutter\bin\flutter.bat test`

Expected: all tests pass with zero failures.

- [ ] **Step 2: Run static analysis**

Run: `cmd /c call F:\Phone\flutter\bin\flutter.bat analyze`

Expected: exit code 0 and no errors.

- [ ] **Step 3: Build release APK**

Run: `cmd /c call F:\Phone\flutter\bin\flutter.bat build apk --release`

Expected: exit code 0 and `build/app/outputs/apk/release/StudyFlow.apk` exists.

- [ ] **Step 4: Inspect packaged resources**

Run: `F:\Phone\android-sdk\build-tools\36.0.0\aapt2.exe dump resources build\app\outputs\apk\release\StudyFlow.apk`

Expected: `mipmap/ic_launcher`, `mipmap/ic_launcher_round`, v26 adaptive XML, v33 adaptive XML, `drawable/ic_launcher_artwork`, `drawable/ic_launcher_foreground`, and `drawable/ic_launcher_monochrome` are present.

- [ ] **Step 5: Review the final diff**

Run: `git diff --check` and `git status --short`.

Expected: no whitespace errors; pre-existing unrelated changes remain intact and uncommitted.
