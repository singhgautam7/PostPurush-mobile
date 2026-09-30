import 'package:flutter/material.dart';

/// Design tokens from the board (`specs/.../PostPurush Android.dc.html`).
///
/// Nothing in a feature names a raw colour, size, radius or duration. It comes
/// from here or from [AppColors].

/// 4 · 8 · 12 · 16 · 24 · 32, plus the screen-level values.
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Screen margin. Every frame on the board is 20dp in from each edge.
  static const double screen = 20;

  /// Gap between rows in a list.
  static const double row = 10;

  /// Gap between sections on a screen.
  static const double section = 20;

  /// Bottom padding on a scrollable so content clears the floating nav.
  static const double bottomSafe = 108;

  /// Bottom padding on the workspace, which carries the 64dp dock above the
  /// nav as well: 24 + 60 + 16 + 64, and a gap.
  static const double bottomSafeDock = 196;
}

/// 8 · chip, 14 · thumb, 20 · card, 28 · sheet and the dock, full · pill.
abstract final class Radii {
  static const double chip = 8;
  static const double thumb = 14;
  static const double card = 20;
  static const double sheet = 28;
  static const double full = 999;

  static const BorderRadius chipR = BorderRadius.all(Radius.circular(chip));
  static const BorderRadius thumbR = BorderRadius.all(Radius.circular(thumb));
  static const BorderRadius cardR = BorderRadius.all(Radius.circular(card));
  static const BorderRadius dockR = BorderRadius.all(Radius.circular(sheet));
  static const BorderRadius sheetR = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
  static const BorderRadius fullR = BorderRadius.all(Radius.circular(full));
}

/// One rounded outline set, 24dp glyphs, 48dp tap target.
abstract final class IconSpec {
  static const double size = 24;
  static const double small = 20;
  static const double tiny = 18;

  /// Nav glyph and its 44dp target inside the pill.
  static const double navTarget = 44;
  static const double tapTarget = 48;
}

/// Board 00, "spring for the finger, decelerate for the system".
abstract final class Motion {
  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration navIndicator = Duration(milliseconds: 220);
  static const Duration containerTransform = Duration(milliseconds: 240);
  static const Duration lensSwap = Duration(milliseconds: 240);
  static const Duration sheet = Duration(milliseconds: 260);
  static const Duration navHide = Duration(milliseconds: 160);
  static const Duration snackEnter = Duration(milliseconds: 180);
  static const Duration snackExit = Duration(milliseconds: 140);

  /// The dock hairline appears only if a request runs past this.
  static const Duration sendHairline = Duration(milliseconds: 120);

  /// Skeletons are only for work that runs past this.
  static const Duration loadingThreshold = Duration(milliseconds: 250);

  /// Anything the finger caused.
  static const Curve spring = Curves.easeOutBack;

  /// Anything the system caused.
  static const Curve decelerate = Curves.easeOutCubic;
  static const Curve standard = Curves.easeInOut;

  /// Under OS reduced motion: transforms become cross-fades, springs go linear.
  static const Duration reducedFade = Duration(milliseconds: 90);
  static const Duration reducedSpring = Duration(milliseconds: 120);

  static bool reduced(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    return mq.disableAnimations || mq.accessibleNavigation;
  }

  /// Duration to actually use, honouring reduced motion.
  static Duration of(BuildContext context, Duration full) =>
      reduced(context) ? reducedFade : full;

  static Curve curveOf(BuildContext context, Curve full) =>
      reduced(context) ? Curves.linear : full;
}

/// Depth lives in 1px outlines. Shadow exists on the nav pill and the New
/// request button, and nowhere else.
abstract final class Elevations {
  static const double navPill = 6;
  static const double navPillBlur = 18;
}

/// Board 00, "Pill geometry": 60 tall, inset 28 from each edge, 24 above the
/// gesture bar, 44dp items spread evenly.
abstract final class NavSpec {
  static const double height = 60;
  static const double inset = 28;
  static const double bottom = 24;
  static const double item = 44;
  static const double padding = 8;

  /// Between two destinations inside the pill.
  static const double gap = 2;

  /// How far the pill travels when it hides.
  static const double hideTravel = 96;
}
