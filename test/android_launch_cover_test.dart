import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

Future<ui.Image> _decodePng(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  return (await codec.getNextFrame()).image;
}

void main() {
  group('Android launcher icon', () {
    test('release version is incremented so phones replace old icons', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final buildGradle = File('android/app/build.gradle.kts').readAsStringSync();

      expect(pubspec, contains('version: 1.0.1+2'));
      expect(buildGradle, contains('versionCode = 2'));
      expect(buildGradle, contains('versionName = "1.0.1"'));
    });

    test('manifest points launcher and round icons at app icon resources', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
      expect(manifest, contains('android:roundIcon="@mipmap/ic_launcher_round"'));
    });

    test('adaptive icons use the supplied artwork and transparent foreground', () {
      for (final name in ['ic_launcher.xml', 'ic_launcher_round.xml']) {
        final v26File = File(
          'android/app/src/main/res/mipmap-anydpi-v26/$name',
        );

        expect(v26File.existsSync(), isTrue);

        final v26 = v26File.readAsStringSync();
        expect(v26, contains('@drawable/ic_launcher_artwork'));
        expect(v26, contains('@drawable/ic_launcher_foreground'));
      }

      expect(
        File(
          'android/app/src/main/res/drawable-nodpi/ic_launcher_artwork.png',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          'android/app/src/main/res/drawable/ic_launcher_foreground.xml',
        ).existsSync(),
        isTrue,
      );
    });

    test('app does not ship an alternate monochrome launcher icon', () {
      expect(
        File(
          'android/app/src/main/res/drawable/ic_launcher_monochrome.xml',
        ).existsSync(),
        isFalse,
      );
      for (final name in ['ic_launcher.xml', 'ic_launcher_round.xml']) {
        expect(
          File(
            'android/app/src/main/res/mipmap-anydpi-v33/$name',
          ).existsSync(),
          isFalse,
        );
      }
    });

    test('color foreground does not redraw the supplied cover artwork', () {
      final foreground = File(
        'android/app/src/main/res/drawable/ic_launcher_foreground.xml',
      ).readAsStringSync();

      expect(foreground, contains('#00000000'));
      expect(foreground, isNot(contains('<path')));
    });

    test('legacy launcher icons use standard sizes and round alpha', () async {
      const sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
      };

      for (final entry in sizes.entries) {
        final base = 'android/app/src/main/res/${entry.key}';
        final square = await _decodePng('$base/ic_launcher.png');
        final round = await _decodePng('$base/ic_launcher_round.png');

        expect((square.width, square.height), (entry.value, entry.value));
        expect((round.width, round.height), (entry.value, entry.value));

        final rgba = await round.toByteData(format: ui.ImageByteFormat.rawRgba);
        expect(rgba!.getUint8(3), 0);
      }
    });

    test('app does not configure the cover image as a launch splash', () {
      final launchBackground = File(
        'android/app/src/main/res/drawable/launch_background.xml',
      ).readAsStringSync();
      final launchBackgroundV21 = File(
        'android/app/src/main/res/drawable-v21/launch_background.xml',
      ).readAsStringSync();

      expect(launchBackground, isNot(contains('launch_cover')));
      expect(launchBackgroundV21, isNot(contains('launch_cover')));
      expect(
        File('android/app/src/main/res/values-v31/styles.xml').existsSync(),
        isFalse,
      );
      expect(
        File('android/app/src/main/res/values-night-v31/styles.xml').existsSync(),
        isFalse,
      );
      expect(
        File('android/app/src/main/res/drawable-nodpi/launch_cover.png')
            .existsSync(),
        isFalse,
      );
      expect(
        File('android/app/src/main/res/drawable-nodpi/launch_cover_icon.png')
            .existsSync(),
        isFalse,
      );
    });
  });
}
