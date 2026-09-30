import 'package:flutter/material.dart';

import 'oklch.dart';

/// How dark a variant is. True black is not a mode. It is a toggle that only
/// applies while dark is in effect.
enum Tone { light, dark, amoled }

/// The role tokens from the design board's `:root` block. Nothing in a screen
/// names a raw colour, so a theme swap is a single map replacement, which is
/// what [ThemeFamily] does.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.surface,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.outline,
    required this.divider,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.onSurfaceMuted,
    required this.icon,
    required this.iconMuted,
    required this.primary,
    required this.primaryPressed,
    required this.primaryContainer,
    required this.onPrimary,
    required this.onPrimaryContainer,
    required this.accent,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.danger,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.shadow,
    required this.scrim,
    required this.tone,
    required this.accentHue,
  });

  /// Page background.
  final Color surface;

  /// Cards, rows, sheets, the dock.
  final Color surfaceContainer;

  /// Chips, fields, segmented tracks, icon buttons.
  final Color surfaceContainerHigh;

  /// 1px borders. Depth lives here.
  final Color outline;

  /// Hairline between rows inside one container.
  final Color divider;

  final Color onSurface;
  final Color onSurfaceVariant;
  final Color onSurfaceMuted;

  /// Top-bar icon actions and inactive nav glyphs.
  final Color icon;
  final Color iconMuted;

  final Color primary;
  final Color primaryPressed;

  /// The active nav pill, the resolved-variable well, a selected chip.
  final Color primaryContainer;

  final Color onPrimary;
  final Color onPrimaryContainer;

  /// Accent-coloured text and icons sitting directly on a surface.
  final Color accent;

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;

  final Color danger;

  /// The tinted well behind a missing variable or a failed assertion.
  final Color dangerContainer;
  final Color onDangerContainer;

  /// The undo strip: dark in a light theme, light in a dark one.
  final Color inverseSurface;
  final Color onInverseSurface;

  /// The nav pill and the New request button cast one. Nothing else does.
  final Color shadow;

  /// Behind a sheet.
  final Color scrim;

  final Tone tone;

  /// The family's accent hue, so a derived role stays in the same family.
  final double accentHue;

  bool get isDark => tone != Tone.light;

  // The seven fixed category hues, re-derived per tone so an environment
  // colour or a method chip stays legible in light, dark and true black.
  // A stored value is an index into this list, never an ARGB value.
  static const List<double> catHues = <double>[265, 200, 150, 55, 25, 340, 300];
  static const List<String> catNames = <String>[
    'Indigo',
    'Cyan',
    'Green',
    'Amber',
    'Red',
    'Pink',
    'Violet',
  ];

  double get _catL => isDark ? 0.74 : 0.55;
  double get _catC => isDark ? 0.13 : 0.14;
  double get _catContainerL => isDark ? 0.30 : 0.95;
  double get _catContainerC => isDark ? 0.05 : 0.035;

  /// Foreground for a fixed hue.
  Color hue(double h) => Oklch(_catL, _catC, h).toColor();

  /// The tinted well for a fixed hue.
  Color hueContainer(double h) =>
      Oklch(_catContainerL, _catContainerC, h).toColor();

  /// `environment.colour` holds an index into [catHues]; out of range takes
  /// the theme accent.
  Color cat(int index) => hue(catHues[index.abs() % catHues.length]);
  Color catContainer(int index) =>
      hueContainer(catHues[index.abs() % catHues.length]);

  // Syntax highlighting. `syn-key` is the accent so a JSON key and a resolved
  // variable read as the same kind of thing.
  double get _synL => isDark ? 0.8 : 0.5;
  Color get synKey => accent;
  Color get synString => Oklch(_synL, 0.12, 150).toColor();
  Color get synNumber => Oklch(_synL, 0.13, 55).toColor();
  Color get synLiteral => Oklch(_synL, 0.13, 300).toColor();
  Color get synPunctuation => onSurfaceVariant;

  @override
  AppColors copyWith({
    Color? surface,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? outline,
    Color? divider,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? onSurfaceMuted,
    Color? icon,
    Color? iconMuted,
    Color? primary,
    Color? primaryPressed,
    Color? primaryContainer,
    Color? onPrimary,
    Color? onPrimaryContainer,
    Color? accent,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? danger,
    Color? dangerContainer,
    Color? onDangerContainer,
    Color? inverseSurface,
    Color? onInverseSurface,
    Color? shadow,
    Color? scrim,
    Tone? tone,
    double? accentHue,
  }) {
    return AppColors(
      surface: surface ?? this.surface,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      outline: outline ?? this.outline,
      divider: divider ?? this.divider,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
      icon: icon ?? this.icon,
      iconMuted: iconMuted ?? this.iconMuted,
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimary: onPrimary ?? this.onPrimary,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
      inverseSurface: inverseSurface ?? this.inverseSurface,
      onInverseSurface: onInverseSurface ?? this.onInverseSurface,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
      tone: tone ?? this.tone,
      accentHue: accentHue ?? this.accentHue,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      surface: l(surface, other.surface),
      surfaceContainer: l(surfaceContainer, other.surfaceContainer),
      surfaceContainerHigh: l(
        surfaceContainerHigh,
        other.surfaceContainerHigh,
      ),
      outline: l(outline, other.outline),
      divider: l(divider, other.divider),
      onSurface: l(onSurface, other.onSurface),
      onSurfaceVariant: l(onSurfaceVariant, other.onSurfaceVariant),
      onSurfaceMuted: l(onSurfaceMuted, other.onSurfaceMuted),
      icon: l(icon, other.icon),
      iconMuted: l(iconMuted, other.iconMuted),
      primary: l(primary, other.primary),
      primaryPressed: l(primaryPressed, other.primaryPressed),
      primaryContainer: l(primaryContainer, other.primaryContainer),
      onPrimary: l(onPrimary, other.onPrimary),
      onPrimaryContainer: l(onPrimaryContainer, other.onPrimaryContainer),
      accent: l(accent, other.accent),
      success: l(success, other.success),
      successContainer: l(successContainer, other.successContainer),
      onSuccessContainer: l(onSuccessContainer, other.onSuccessContainer),
      danger: l(danger, other.danger),
      dangerContainer: l(dangerContainer, other.dangerContainer),
      onDangerContainer: l(onDangerContainer, other.onDangerContainer),
      inverseSurface: l(inverseSurface, other.inverseSurface),
      onInverseSurface: l(onInverseSurface, other.onInverseSurface),
      shadow: l(shadow, other.shadow),
      scrim: l(scrim, other.scrim),
      tone: t < 0.5 ? tone : other.tone,
      accentHue: t < 0.5 ? accentHue : other.accentHue,
    );
  }
}

/// One accent family. The board ships PostPurush plus the six web presets,
/// each a set of numbers on the same formulas.
@immutable
class ThemeFamily {
  const ThemeFamily({
    required this.id,
    required this.name,
    required this.blurb,
    required this.neutralHue,
    required this.neutralChroma,
    required this.primaryHue,
    required this.primaryLightness,
    required this.primaryChroma,
    required this.primaryContainerChroma,
    required this.hasAmoled,
    this.lightSurfaceSink = 0,
    this.lightOnPrimary,
    double? darkNeutralChroma,
  }) : darkNeutralChroma = darkNeutralChroma ?? neutralChroma;

  final String id;
  final String name;
  final String blurb;

  /// Hue for the near-grey surfaces and text.
  final double neutralHue;

  /// Multiplier on the reference neutral chromas (`--nc`).
  final double neutralChroma;

  final double primaryHue;
  final double primaryLightness;
  final double primaryChroma;
  final double primaryContainerChroma;
  final bool hasAmoled;

  /// `--sink`: how far below the shared construction the light surfaces sit.
  /// The three surface steps sink by 1x, 1.6x and 2.2x of this.
  final double lightSurfaceSink;

  /// Overrides pure white on a family whose primary is too light for it
  /// (the board does this for clapchat-yellow).
  final Oklch? lightOnPrimary;

  /// `--dnc`: the neutral multiplier in dark.
  final double darkNeutralChroma;

  /// The app's own accent is its icon's green.
  ///
  /// The main board specified indigo at hue 272, but the icon board's brace
  /// monogram is green, and an app whose accent disagrees with its own launcher
  /// icon looks like two products. Measured from the icon's bowl, `#417843` is
  /// `oklch(0.521 0.100 144.7)`, so the family is that, rounded.
  static const ThemeFamily postpurush = ThemeFamily(
    id: 'postpurush',
    name: 'PostPurush',
    blurb: 'default',
    neutralHue: 145,
    neutralChroma: 0.9,
    primaryHue: 145,
    primaryLightness: 0.52,
    primaryChroma: 0.10,
    primaryContainerChroma: 0.045,
    hasAmoled: true,
  );

  /// The indigo the main board originally specified, kept as a choice.
  static const ThemeFamily indigo = ThemeFamily(
    id: 'indigo',
    name: 'Indigo',
    blurb: 'the board default',
    neutralHue: 272,
    neutralChroma: 0.9,
    primaryHue: 272,
    primaryLightness: 0.5,
    primaryChroma: 0.13,
    primaryContainerChroma: 0.045,
    hasAmoled: true,
  );

  static const ThemeFamily shadcn = ThemeFamily(
    id: 'og-shadcn',
    name: 'og-shadcn',
    blurb: 'mono',
    neutralHue: 265,
    neutralChroma: 0.35,
    primaryHue: 265,
    primaryLightness: 0.24,
    primaryChroma: 0.012,
    primaryContainerChroma: 0.006,
    hasAmoled: false,
  );

  static const ThemeFamily hostman = ThemeFamily(
    id: 'hostman-orange',
    name: 'hostman-orange',
    blurb: 'warm',
    neutralHue: 55,
    neutralChroma: 1.1,
    primaryHue: 45,
    primaryLightness: 0.58,
    primaryChroma: 0.16,
    primaryContainerChroma: 0.05,
    hasAmoled: false,
    darkNeutralChroma: 1,
  );

  static const ThemeFamily cutube = ThemeFamily(
    id: 'cutube-red',
    name: 'cutube-red',
    blurb: 'red',
    neutralHue: 20,
    neutralChroma: 1,
    primaryHue: 25,
    primaryLightness: 0.54,
    primaryChroma: 0.18,
    primaryContainerChroma: 0.045,
    hasAmoled: false,
  );

  static const ThemeFamily lithub = ThemeFamily(
    id: 'lithub-blue',
    name: 'lithub-blue',
    blurb: 'blue',
    neutralHue: 255,
    neutralChroma: 1,
    primaryHue: 255,
    primaryLightness: 0.52,
    primaryChroma: 0.15,
    primaryContainerChroma: 0.045,
    hasAmoled: true,
  );

  static const ThemeFamily shotsapp = ThemeFamily(
    id: 'shotsapp-green',
    name: 'shotsapp-green',
    blurb: 'green',
    neutralHue: 155,
    neutralChroma: 1.1,
    primaryHue: 150,
    primaryLightness: 0.54,
    primaryChroma: 0.13,
    primaryContainerChroma: 0.045,
    hasAmoled: false,
    darkNeutralChroma: 1,
  );

  static const ThemeFamily clapchat = ThemeFamily(
    id: 'clapchat-yellow',
    name: 'clapchat-yellow',
    blurb: 'yellow',
    neutralHue: 90,
    neutralChroma: 1.25,
    primaryHue: 88,
    primaryLightness: 0.66,
    primaryChroma: 0.13,
    primaryContainerChroma: 0.06,
    hasAmoled: false,
    lightSurfaceSink: 0.01,
    lightOnPrimary: Oklch(0.22, 0.03, 88),
    darkNeutralChroma: 1.1,
  );

  static const List<ThemeFamily> all = <ThemeFamily>[
    postpurush,
    indigo,
    shadcn,
    hostman,
    cutube,
    lithub,
    shotsapp,
    clapchat,
  ];

  static ThemeFamily byId(String id) =>
      all.firstWhere((ThemeFamily f) => f.id == id, orElse: () => postpurush);

  /// Android hands over one wallpaper seed; every other role is derived
  /// exactly as a bundled family's is. Chroma is pinned to 0.11 so a
  /// wallpaper scheme sits in the same register as the bundled families.
  static ThemeFamily fromSeed(Color seed) {
    final double hue = Oklch.hueOf(seed);
    return ThemeFamily(
      id: 'dynamic',
      name: 'Dynamic',
      blurb: 'wallpaper',
      neutralHue: hue,
      neutralChroma: 1,
      primaryHue: hue,
      primaryLightness: 0.52,
      primaryChroma: 0.11,
      primaryContainerChroma: 0.04,
      hasAmoled: true,
    );
  }

  AppColors colors(Tone tone) =>
      tone == Tone.light ? _light() : _dark(amoled: tone == Tone.amoled);

  Oklch _n(double l, double c, {bool dark = false}) =>
      Oklch(l, c * (dark ? darkNeutralChroma : neutralChroma), neutralHue);
  Oklch _nd(double l, double c) => _n(l, c, dark: true);
  Oklch _p(double l, double c) => Oklch(l, c, primaryHue);

  AppColors _light() {
    final double pc = primaryChroma;
    final double sink = lightSurfaceSink;
    return AppColors(
      surface: _n(0.99 - sink, 0.004).toColor(),
      surfaceContainer: _n(0.965 - 1.6 * sink, 0.008).toColor(),
      surfaceContainerHigh: _n(0.935 - 2.2 * sink, 0.011).toColor(),
      outline: _n(0.885 - 2.2 * sink, 0.012).toColor(),
      divider: _n(0.92 - 1.6 * sink, 0.008).toColor(),
      onSurface: _n(0.20, 0.02).toColor(),
      onSurfaceVariant: _n(0.52, 0.02).toColor(),
      onSurfaceMuted: _n(0.62, 0.02).toColor(),
      icon: _n(0.30, 0.02).toColor(),
      iconMuted: _n(0.45, 0.02).toColor(),
      primary: _p(primaryLightness, pc).toColor(),
      primaryPressed: _p(primaryLightness - 0.07, pc - 0.01).toColor(),
      primaryContainer: _p(0.92, primaryContainerChroma).toColor(),
      onPrimary: (lightOnPrimary ?? const Oklch(1, 0, 0)).toColor(),
      onPrimaryContainer: _p(0.38, pc).toColor(),
      accent: _p(0.45, pc).toColor(),
      success: const Oklch(0.55, 0.10, 145).toColor(),
      successContainer: const Oklch(0.95, 0.035, 145).toColor(),
      onSuccessContainer: const Oklch(0.42, 0.10, 145).toColor(),
      danger: const Oklch(0.55, 0.16, 25).toColor(),
      dangerContainer: const Oklch(0.97, 0.02, 25).toColor(),
      onDangerContainer: const Oklch(0.48, 0.17, 25).toColor(),
      inverseSurface: _n(0.22, 0.02).toColor(),
      onInverseSurface: _n(0.97, 0.004).toColor(),
      shadow: const Oklch(0.35, 0.06, 265, 0.09).toColor(),
      scrim: Oklch(0.20, 0.02, neutralHue, 0.42).toColor(),
      tone: Tone.light,
      accentHue: primaryHue,
    );
  }

  AppColors _dark({required bool amoled}) {
    // True black drops the page to black and sinks the containers under it;
    // everything else keeps its dark value.
    final double pcd = primaryChroma * 0.81;
    return AppColors(
      surface: amoled
          ? const Oklch(0, 0, 0).toColor()
          : _nd(0.205, 0.012).toColor(),
      surfaceContainer: _nd(
        amoled ? 0.13 : 0.255,
        amoled ? 0.012 : 0.014,
      ).toColor(),
      surfaceContainerHigh: _nd(
        amoled ? 0.15 : 0.30,
        amoled ? 0.012 : 0.016,
      ).toColor(),
      outline: _nd(amoled ? 0.30 : 0.36, amoled ? 0.014 : 0.016).toColor(),
      divider: _nd(amoled ? 0.24 : 0.30, 0.014).toColor(),
      onSurface: _nd(0.96, 0.005).toColor(),
      onSurfaceVariant: _nd(0.72, 0.012).toColor(),
      onSurfaceMuted: _nd(0.60, 0.012).toColor(),
      icon: _nd(0.90, 0.008).toColor(),
      iconMuted: _nd(0.72, 0.012).toColor(),
      primary: _p(0.74, pcd).toColor(),
      primaryPressed: _p(0.68, pcd).toColor(),
      primaryContainer: _p(0.28, pcd * 0.46).toColor(),
      onPrimary: _nd(0.14, 0.01).toColor(),
      onPrimaryContainer: _p(0.90, pcd * 0.46).toColor(),
      accent: _p(0.85, pcd * 0.69).toColor(),
      success: const Oklch(0.72, 0.11, 145).toColor(),
      successContainer: const Oklch(0.28, 0.05, 145).toColor(),
      onSuccessContainer: const Oklch(0.84, 0.10, 145).toColor(),
      danger: const Oklch(0.72, 0.14, 25).toColor(),
      dangerContainer: Oklch(amoled ? 0.20 : 0.26, 0.05, 25).toColor(),
      onDangerContainer: const Oklch(0.82, 0.11, 25).toColor(),
      inverseSurface: _nd(0.93, 0.008).toColor(),
      onInverseSurface: _nd(0.20, 0.02).toColor(),
      shadow: const Oklch(0, 0, 0, 0.5).toColor(),
      scrim: const Oklch(0, 0, 0, 0.55).toColor(),
      tone: amoled ? Tone.amoled : Tone.dark,
      accentHue: primaryHue,
    );
  }
}
