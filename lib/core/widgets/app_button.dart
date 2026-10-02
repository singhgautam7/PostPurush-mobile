import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'dashed_border.dart';

enum AppButtonType {
  /// Accent fill. One per surface.
  primary,

  /// Filled, quiet; sits next to a primary.
  secondary,

  /// 1px outline on the page surface, which is the board's Cancel.
  outlined,

  /// Dashed: "add another one of these".
  dotted,

  /// The danger well. There are no filled red buttons.
  danger,

  /// Label only, in the accent: "Add header", "Add parameter".
  text,
}

/// The one button. Height, radius, padding and label all come from tokens, so
/// a button in a sheet can never drift from a button on a page.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.icon,
    this.fullWidth = false,
    this.compact = false,
    this.filledIcon = false,
    this.iconTrails = false,
    super.key,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool fullWidth;

  /// The 36dp inline form the board uses for a quick action chip.
  final bool compact;

  /// A filled glyph, as the board draws Send and the Try bolt.
  final bool filledIcon;

  /// The glyph sits after the label rather than before it, which is how the
  /// board draws a forward action: "Next →", "Get started →".
  final bool iconTrails;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final bool disabled = onPressed == null;
    final _Skin skin = _skin(c);
    final double height = compact ? 36 : 48;

    final Widget glyph = Icon(
      icon,
      size: compact ? IconSpec.tiny : IconSpec.small,
      color: skin.fg,
      fill: filledIcon ? 1 : 0,
    );
    final Widget content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: Space.sm,
      children: <Widget>[
        if (icon != null && !iconTrails) glyph,
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (compact ? AppType.chipLabel : AppType.titleMedium)
                .copyWith(color: skin.fg),
          ),
        ),
        if (icon != null && iconTrails) glyph,
      ],
    );

    final bool dashed = type == AppButtonType.dotted;
    Widget button = ConstrainedBox(
      // A minimum, not a fixed height: the pill grows with its text.
      constraints: BoxConstraints(
        minHeight: height,
        minWidth: fullWidth ? double.infinity : 0,
      ),
      child: Material(
        color: skin.bg,
        shape: StadiumBorder(
          side: skin.border == null || dashed
              ? BorderSide.none
              : BorderSide(color: skin.border!),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // The Android click sound belongs to the system, not to a tool.
          enableFeedback: false,
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              icon == null || iconTrails
                  ? (compact ? 14 : 22)
                  : (compact ? 10 : 16),
              Space.xs,
              icon != null && iconTrails
                  ? (compact ? 10 : 16)
                  : (compact ? 14 : 22),
              Space.xs,
            ),
            child: content,
          ),
        ),
      ),
    );
    if (dashed && !disabled) {
      button = CustomPaint(
        foregroundPainter: DashedBorderPainter(skin.border!),
        child: button,
      );
    }
    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      // The board draws every disabled control at 38%, buttons included.
      child: Opacity(opacity: disabled ? 0.38 : 1, child: button),
    );
  }

  _Skin _skin(AppColors c) => switch (type) {
    AppButtonType.primary => _Skin(bg: c.primary, fg: c.onPrimary),
    AppButtonType.secondary => _Skin(
      bg: c.surfaceContainerHigh,
      fg: c.onSurface,
      border: c.outline,
    ),
    AppButtonType.outlined => _Skin(
      bg: Colors.transparent,
      fg: c.onSurface,
      border: c.outline,
    ),
    AppButtonType.dotted => _Skin(
      bg: Colors.transparent,
      fg: c.onSurfaceVariant,
      border: c.outline,
    ),
    AppButtonType.danger => _Skin(
      bg: c.dangerContainer,
      fg: c.onDangerContainer,
    ),
    AppButtonType.text => _Skin(bg: Colors.transparent, fg: c.accent),
  };
}

class _Skin {
  const _Skin({required this.bg, required this.fg, this.border});

  final Color bg;
  final Color fg;
  final Color? border;
}

/// The full-width accent row that closes a card: "Add header", "Add parameter",
/// "Add variable", "New folder". 52dp, a 24dp glyph and an accent label.
class AddRowButton extends StatelessWidget {
  const AddRowButton({
    required this.label,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        // The Android click sound belongs to the system, not to a tool.
        enableFeedback: false,
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          alignment: Alignment.centerLeft,
          child: Row(
            spacing: Space.sm,
            children: <Widget>[
              Icon(icon, size: IconSpec.size, color: c.accent),
              Text(
                label,
                style: AppType.titleMedium.copyWith(color: c.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The New request button on Folders: 56dp tall, radius 20, `primary`, the
/// one shadow besides the nav pill. Long-press keeps the quick actions.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.onLongPress,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: c.primary,
        borderRadius: Radii.cardR,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // The Android click sound belongs to the system, not to a tool.
          enableFeedback: false,
          onTap: onPressed,
          onLongPress: onLongPress,
          child: Container(
            height: 56,
            padding: const EdgeInsets.only(left: Space.lg, right: Space.screen),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: Space.row,
              children: <Widget>[
                Icon(icon, size: IconSpec.size, color: c.onPrimary),
                Text(
                  label,
                  style: AppType.titleMedium.copyWith(color: c.onPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
