import 'package:flutter/material.dart';

/// The type ramp from the design board.
///
/// One typeface carries the interface: Instrument Sans (variable), bundled.
/// A tabular mono carries anything you would type: URLs, JSON, keys, counts,
/// figures and section headers.
///
/// Instrument Sans is a variable font, so every weight sets `fontVariations`
/// alongside `fontWeight`. The axis is what actually moves the glyphs.
abstract final class AppType {
  static const String sans = 'Instrument Sans';

  /// The platform's own monospace, `ui-monospace` on the board.
  static const String mono = 'monospace';

  /// Display sizes take weight 600 and `letter-spacing: -0.022em`.
  static const double _displayTracking = -0.022;

  static FontWeight _fw(int weight) => FontWeight.values[weight ~/ 100 - 1];

  static TextStyle _sans(
    double size,
    double height,
    int weight, {
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: sans,
      fontSize: size,
      height: height,
      fontWeight: _fw(weight),
      fontVariations: <FontVariation>[FontVariation('wght', weight.toDouble())],
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle _display(double size, double height) =>
      _sans(size, height, 600, letterSpacing: size * _displayTracking);

  static TextStyle _mono(
    double size,
    int weight, {
    double height = 1.3,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: mono,
      fontSize: size,
      height: height,
      fontWeight: _fw(weight),
      letterSpacing: letterSpacing,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }

  /// Empty states: "No requests yet".
  static TextStyle get display => _display(40, 1.05);

  /// Screen title on a tab root or a pushed page, and the request name.
  static TextStyle get headerTitle => _sans(22, 1.25, 600, letterSpacing: -0.2);

  /// Sheet titles. Regular weight, tighter leading than the header.
  static TextStyle get sheetTitle => _sans(22, 1.1, 400);

  /// Section titles inside a page, and a doc endpoint's name.
  static TextStyle get title => _sans(20, 1.25, 600, letterSpacing: -0.2);

  /// Stat figures on an analytics card.
  static TextStyle get figure => _sans(28, 1.05, 600, letterSpacing: -0.5);

  /// Body copy and a doc paragraph.
  static TextStyle get body => _sans(15, 1.55, 400);

  /// Every list row, button label and nav label.
  static TextStyle get titleMedium => _sans(14.5, 1.3, 600);

  /// Notes and secondary body.
  static TextStyle get note => _sans(13.5, 1.65, 400);

  /// A row's secondary line, a chip label, a tab label.
  static TextStyle get bodyMedium => _sans(13.5, 1.45, 400);

  /// A chip that carries a label rather than a value.
  static TextStyle get chipLabel => _sans(13.5, 1.3, 600);

  static TextStyle get bodySmall => _sans(12, 1.5, 400);

  /// Field labels.
  static TextStyle get label => _sans(12, 1.3, 500);

  /// The URL bar and a header value: anything you would type.
  static TextStyle get monoBody => _mono(13.5, 400, height: 1.6);

  /// The JSON viewer and the code-export sheet.
  static TextStyle get monoCode => _mono(13, 400, height: 1.75);

  /// Counts and values in a row.
  static TextStyle get monoTabular => _mono(13, 500);

  /// The method chip inside the method sheet.
  static TextStyle get monoChip => _mono(12, 600);

  /// Metadata under a name, and the method chip in a list.
  static TextStyle get monoLabel => _mono(11, 500);

  static TextStyle get monoLabelStrong => _mono(11, 600);

  /// ALL-CAPS section headers: `600 11px · letter-spacing .08em`.
  static TextStyle get sectionHeader =>
      _mono(11, 600, letterSpacing: 0.88);

  /// Chart axis text.
  static TextStyle get monoAxis => _mono(9, 500);

  static TextTheme textTheme(Color onSurface, Color onSurfaceVariant) {
    return TextTheme(
      displayLarge: display.copyWith(color: onSurface),
      headlineSmall: headerTitle.copyWith(color: onSurface),
      titleLarge: title.copyWith(color: onSurface),
      titleMedium: titleMedium.copyWith(color: onSurface),
      titleSmall: titleMedium.copyWith(color: onSurface),
      bodyLarge: body.copyWith(color: onSurface),
      bodyMedium: note.copyWith(color: onSurface),
      bodySmall: bodySmall.copyWith(color: onSurfaceVariant),
      labelLarge: titleMedium.copyWith(color: onSurface),
      labelMedium: label.copyWith(color: onSurfaceVariant),
      labelSmall: monoLabel.copyWith(color: onSurfaceVariant),
    );
  }
}

extension AppTextStyle on TextStyle {
  /// Sets the weight on a variable-font style. Plain `copyWith(fontWeight:)`
  /// does nothing for Instrument Sans; the `wght` axis has to move too.
  TextStyle weight(int w) => copyWith(
    fontWeight: AppType._fw(w),
    fontVariations: fontFamily == AppType.sans
        ? <FontVariation>[FontVariation('wght', w.toDouble())]
        : null,
  );
}
