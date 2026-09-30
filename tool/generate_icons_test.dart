import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:postpurush/features/about/app_mark.dart';

/// Draws the launcher and splash art from the icon board's brace monogram.
///
/// Not a test: a generator, run as one because `flutter test` is the only place
/// a Flutter canvas exists without a device. The adaptive icon itself is the
/// board's own vector drawable in `res/drawable/`, copied in verbatim and not
/// touched here; these PNGs are the legacy fallback for Android before adaptive
/// icons, the store listing, and the splash.
///
///     flutter test tool/generate_icons_test.dart
void main() {
  const String res = 'android/app/src/main/res';

  /// Paints [painter] into a square PNG of [size] pixels.
  ///
  /// The caller has to wrap this in `tester.runAsync`: `toImage` hands work to
  /// the engine's rasteriser, and the fake async a widget test runs under never
  /// lets that complete, so the await hangs forever.
  Future<Uint8List> render(CustomPainter painter, double size) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    painter.paint(canvas, Size(size, size));
    final ui.Image image = await recorder.endRecording().toImage(
      size.round(),
      size.round(),
    );
    final ByteData? bytes = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    return bytes!.buffer.asUint8List();
  }

  void write(String path, Uint8List bytes) {
    final File file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
  }

  testWidgets('draws the legacy launcher icon', (WidgetTester tester) async {
    // Android before 8 has no adaptive icon, so it gets the mark on its pista
    // ground as a flat square.
    const Map<String, double> densities = <String, double>{
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    for (final MapEntry<String, double> density in densities.entries) {
      final Uint8List png = (await tester.runAsync(
        () => render(const AppMarkPainter(), density.value),
      ))!;
      write('$res/mipmap-${density.key}/ic_launcher.png', png);
      write('$res/mipmap-${density.key}/ic_launcher_round.png', png);
    }
  });

  testWidgets('draws the store listing icon', (WidgetTester tester) async {
    // 512, square and opaque, which is what the Play console asks for.
    final Uint8List png = (await tester.runAsync(
      () => render(const AppMarkPainter(), 512),
    ))!;
    write('assets/icon/play_store_512.png', png);
  });

  testWidgets('draws the splash mark', (WidgetTester tester) async {
    // Android 12's splash masks its icon to a circle and shows only the middle
    // two thirds of it, so the art has to be the glyph alone on transparent,
    // drawn small enough to survive that crop. The pista ground comes from
    // `icon_background_color` instead of being baked in.
    final Uint8List android12 = (await tester.runAsync(
      () => render(
        const _Inset(
          AppMarkPainter(background: Colors.transparent),
          // The board's mark already sits in the 66dp safe circle of a 108dp
          // canvas; another two thirds keeps it clear of Android 12's mask.
          factor: 0.66,
        ),
        960,
      ),
    ))!;
    write('assets/icon/splash_android12.png', android12);

    // The legacy splash draws the whole icon, ground and all, centred on the
    // page colour, so it reads as the launcher icon sitting still.
    final Uint8List legacy = (await tester.runAsync(
      () => render(const _Rounded(AppMarkPainter()), 384),
    ))!;
    write('assets/icon/splash.png', legacy);
  });
}

/// Draws [child] centred at [factor] of the box, on transparent.
class _Inset extends CustomPainter {
  const _Inset(this.child, {required this.factor});

  final CustomPainter child;
  final double factor;

  @override
  void paint(Canvas canvas, Size size) {
    final double inner = size.width * factor;
    final double edge = (size.width - inner) / 2;
    canvas
      ..save()
      ..translate(edge, edge);
    child.paint(canvas, Size(inner, inner));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Inset old) => true;
}

/// Draws [child] clipped to a circle, which is how a launcher shows it.
class _Rounded extends CustomPainter {
  const _Rounded(this.child);

  final CustomPainter child;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..clipPath(
        Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    child.paint(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Rounded old) => true;
}
