import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';

/// Back, save, code, overflow, close, resend: every icon action is this
/// button. One place decides the hit area, the shape, the fill and the tint.
///
/// The board draws it at 48dp on a `surfaceContainerHigh` circle with a 24dp
/// glyph in `icon`, and that is the default here.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.size = IconSpec.tapTarget,
    this.glyphSize = IconSpec.size,
    this.filled = true,
    this.active = false,
    this.tint,
    this.background,
    this.badge = false,
    super.key,
  });

  final IconData icon;

  /// Null disables the button, which the board draws at 38% opacity.
  final VoidCallback? onPressed;

  /// Required: an icon-only control is invisible to a screen reader without it.
  final String semanticLabel;

  final double size;
  final double glyphSize;

  /// False for a quiet action that sits on a tinted row.
  final bool filled;

  /// A toggled state: bookmarked, or an open menu.
  final bool active;
  final Color? tint;
  final Color? background;

  /// The `primary` dot on Save that means there are unsaved edits (board 2.2).
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final bool disabled = onPressed == null;
    final Color fg = tint ?? (active ? c.onPrimaryContainer : c.icon);
    final Color bg = background ??
        (active
            ? c.primaryContainer
            : (filled ? c.surfaceContainerHigh : Colors.transparent));
    final double target = size < IconSpec.tapTarget ? IconSpec.tapTarget : size;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel,
        child: SizedBox(
          width: target,
          height: target,
          child: Center(
            child: Opacity(
              opacity: disabled ? 0.38 : 1,
              child: Material(
                color: bg,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onPressed,
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: Stack(
                      children: <Widget>[
                        Center(child: Icon(icon, size: glyphSize, color: fg)),
                        if (badge)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: c.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: bg, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
