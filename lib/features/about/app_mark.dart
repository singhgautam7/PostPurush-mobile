import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';

/// The app mark: the brace monogram from the icon board, "1a Brace monogram,
/// final".
///
/// The stem of the P is a curly brace and the bowl springs from its top hook
/// and stops short of the brace point. Code and request in one letter.
///
/// Drawn rather than shipped as an image, from the same two paths as
/// `res/drawable/ic_launcher_foreground.xml`, so the launcher icon and the
/// in-app mark cannot drift apart.
class AppMark extends StatelessWidget {
  const AppMark({this.size = 64, this.monochrome = false, super.key})
    : _themed = false;

  /// The welcome flow's brand mark tile: the same glyph in role tokens, so it
  /// follows dynamic colour and the presets. Brace on `onPrimaryContainer`,
  /// bowl on `primary`, on a `primaryContainer` tile.
  const AppMark.tile({this.size = 120, super.key}) : monochrome = false,
        _themed = true;

  final double size;

  /// The silhouette in one colour, for a notification or a dense row.
  final bool monochrome;

  /// Role tokens instead of the icon's fixed greens.
  final bool _themed;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final Widget mark = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: monochrome
            ? AppMarkPainter(
                background: Colors.transparent,
                brace: c.onSurface,
                bowl: c.onSurface,
              )
            : _themed
                ? AppMarkPainter(
                    background: c.primaryContainer,
                    brace: c.onPrimaryContainer,
                    bowl: c.primary,
                  )
                : const AppMarkPainter(),
      ),
    );
    // Always rounded: the mark carries its own pista background, and a hard
    // square of it beside the app name reads as an unfinished asset. The
    // radius is the launcher's, scaled to whatever size is asked for.
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.26),
      child: mark,
    );
  }
}

/// Paints the mark inside its own box, in the icon board's 108-unit space.
class AppMarkPainter extends CustomPainter {
  const AppMarkPainter({
    this.background = pista,
    this.brace = darkGreen,
    this.bowl = midGreen,
  });

  /// The icon board's own colours. Fixed, not theme roles: a launcher icon
  /// does not follow the app's accent, and these are what the board specifies.
  static const Color pista = Color(0xFFCCE6CC);
  static const Color darkGreen = Color(0xFF1E4120);
  static const Color midGreen = Color(0xFF417843);

  final Color background;

  /// The stem, drawn as a curly brace.
  final Color brace;

  /// The bowl springing from the brace's top hook.
  final Color bowl;

  /// The adaptive-icon canvas the paths are authored on.
  static const double canvas = 108;

  /// The board's group transform: the mark sits inside the 66dp safe circle.
  static const double _scale = 0.86;
  static const double _strokeWidth = 8.5;

  @override
  void paint(Canvas canvas_, Size size) {
    if (background.a > 0) {
      canvas_.drawRect(
        Offset.zero & size,
        Paint()..color = background,
      );
    }

    canvas_.save();
    canvas_.scale(size.width / canvas, size.height / canvas);
    // pivotX/pivotY 54 with scale 0.86, exactly as the vector drawable's group.
    canvas_
      ..translate(54, 54)
      ..scale(_scale)
      ..translate(-54, -54);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // M52 28 H50 C45 28 42 31 42 36 V46 C42 51 39 54 34 54
    //                C39 54 42 57 42 62 V72 C42 77 45 80 50 80
    final Path stem = Path()
      ..moveTo(52, 28)
      ..lineTo(50, 28)
      ..cubicTo(45, 28, 42, 31, 42, 36)
      ..lineTo(42, 46)
      ..cubicTo(42, 51, 39, 54, 34, 54)
      ..cubicTo(39, 54, 42, 57, 42, 62)
      ..lineTo(42, 72)
      ..cubicTo(42, 77, 45, 80, 50, 80);
    canvas_.drawPath(stem, paint..color = brace);

    // M52 28 H58 C68 28 74 34 74 42 C74 50 68 56 58 56 H51
    final Path arc = Path()
      ..moveTo(52, 28)
      ..lineTo(58, 28)
      ..cubicTo(68, 28, 74, 34, 74, 42)
      ..cubicTo(74, 50, 68, 56, 58, 56)
      ..lineTo(51, 56);
    canvas_.drawPath(arc, paint..color = bowl);

    canvas_.restore();
  }

  @override
  bool shouldRepaint(AppMarkPainter old) =>
      old.background != background ||
      old.brace != brace ||
      old.bowl != bowl;
}
