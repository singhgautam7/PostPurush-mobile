import 'package:flutter/material.dart';

import '../http/variable_resolver.dart';
import '../models/environment.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';

/// Draws `{{variable}}` the way the board does: a resolved one in the accent
/// on a tinted well, a missing one in a danger well with a wavy underline.
///
/// One builder for the URL bar, header values, the body editor, the code view
/// and the generated docs, so a variable can never look resolved in one place
/// and missing in another.
abstract final class VariableText {
  /// The spans for [text]. [base] carries the font; only colour and decoration
  /// change, so the layout is identical to the plain text's.
  static List<InlineSpan> spans({
    required String text,
    required Environment? env,
    required AppColors colors,
    required TextStyle base,
  }) {
    final List<VariableSpan> found = VariableResolver.scan(text, env);
    if (found.isEmpty) {
      return <InlineSpan>[TextSpan(text: text, style: base)];
    }
    final List<InlineSpan> out = <InlineSpan>[];
    int at = 0;
    for (final VariableSpan v in found) {
      if (v.start > at) {
        out.add(TextSpan(text: text.substring(at, v.start), style: base));
      }
      out.add(
        TextSpan(
          text: text.substring(v.start, v.end),
          style: base.copyWith(
            color: v.resolved ? colors.accent : colors.onDangerContainer,
            decoration: v.resolved ? null : TextDecoration.underline,
            decorationStyle: v.resolved ? null : TextDecorationStyle.wavy,
            decorationColor: v.resolved ? null : colors.danger,
          ),
        ),
      );
      at = v.end;
    }
    if (at < text.length) {
      out.add(TextSpan(text: text.substring(at), style: base));
    }
    return out;
  }

  /// The wells behind those spans, as (range, colour) pairs for the painter.
  static List<VariableWell> wells({
    required String text,
    required Environment? env,
    required AppColors colors,
  }) => <VariableWell>[
    for (final VariableSpan v in VariableResolver.scan(text, env))
      VariableWell(
        start: v.start,
        end: v.end,
        colour: v.resolved ? colors.primaryContainer : colors.dangerContainer,
      ),
  ];

  /// A read-only run of text with its variables highlighted, wells included.
  static Widget display({
    required String text,
    required Environment? env,
    required AppColors colors,
    required TextStyle base,
    int? maxLines,
    TextOverflow overflow = TextOverflow.clip,
  }) => _WelledText(
    text: text,
    env: env,
    colors: colors,
    base: base,
    maxLines: maxLines,
    overflow: overflow,
  );
}

/// One rounded well, expressed as a character range so the painter can ask the
/// text layout where it actually landed.
@immutable
class VariableWell {
  const VariableWell({
    required this.start,
    required this.end,
    required this.colour,
  });

  final int start;
  final int end;
  final Color colour;

  @override
  bool operator ==(Object other) =>
      other is VariableWell &&
      other.start == start &&
      other.end == end &&
      other.colour == colour;

  @override
  int get hashCode => Object.hash(start, end, colour);
}

/// Paints the tinted wells under the variable spans.
///
/// The wells cannot be a `TextStyle.background`, because that paints a square
/// box and the board's well has an 8dp radius. Measuring the same span tree
/// with a [TextPainter] and drawing the boxes it reports gives the exact
/// geometry, and leaves the text itself as ordinary editable text.
class VariableWellPainter extends CustomPainter {
  const VariableWellPainter({
    required this.spans,
    required this.wells,
    required this.textDirection,
    required this.textScaler,
    this.maxLines,
  });

  final List<InlineSpan> spans;
  final List<VariableWell> wells;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final int? maxLines;

  /// How far the well extends past the glyphs, which is the board's 3dp
  /// horizontal padding.
  static const double _padX = 3;
  static const double _padY = 1;

  @override
  void paint(Canvas canvas, Size size) {
    if (wells.isEmpty) return;
    final TextPainter painter = TextPainter(
      text: TextSpan(children: spans),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: maxLines,
    )..layout(maxWidth: size.width);

    final Paint paint = Paint();
    for (final VariableWell well in wells) {
      paint.color = well.colour;
      final List<TextBox> boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: well.start, extentOffset: well.end),
      );
      for (final TextBox box in boxes) {
        final Rect rect = Rect.fromLTRB(
          box.left - _padX,
          box.top - _padY,
          box.right + _padX,
          box.bottom + _padY,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(Radii.chip)),
          paint,
        );
      }
    }
    painter.dispose();
  }

  @override
  bool shouldRepaint(VariableWellPainter old) =>
      old.wells != wells ||
      old.textScaler != textScaler ||
      old.maxLines != maxLines ||
      !_sameSpans(old.spans, spans);

  static bool _sameSpans(List<InlineSpan> a, List<InlineSpan> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _WelledText extends StatelessWidget {
  const _WelledText({
    required this.text,
    required this.env,
    required this.colors,
    required this.base,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  final String text;
  final Environment? env;
  final AppColors colors;
  final TextStyle base;
  final int? maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final List<InlineSpan> spans = VariableText.spans(
      text: text,
      env: env,
      colors: colors,
      base: base,
    );
    final List<VariableWell> wells = VariableText.wells(
      text: text,
      env: env,
      colors: colors,
    );
    final Widget label = Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
    if (wells.isEmpty) return label;
    return CustomPaint(
      painter: VariableWellPainter(
        spans: spans,
        wells: wells,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: maxLines,
      ),
      child: label,
    );
  }
}

/// A [TextEditingController] that highlights variables as they are typed.
class VariableEditingController extends TextEditingController {
  VariableEditingController({super.text, this.env, this.colors});

  Environment? env;
  AppColors? colors;

  /// Re-highlights against a new environment without losing the caret, which
  /// is what "highlights re-resolve in the same frame" means (board 00).
  void retheme({Environment? environment, AppColors? palette}) {
    env = environment;
    colors = palette;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final AppColors? palette = colors;
    if (palette == null) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    return TextSpan(
      children: VariableText.spans(
        text: text,
        env: env,
        colors: palette,
        base: style ?? const TextStyle(),
      ),
    );
  }
}
