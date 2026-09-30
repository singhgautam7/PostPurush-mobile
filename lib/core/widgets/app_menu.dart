import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// One line of an anchored menu.
@immutable
class AppMenuEntry<T> {
  const AppMenuEntry({
    required this.value,
    required this.label,
    this.icon,
    this.note,
    this.danger = false,
    this.selected = false,
    this.leading,
  });

  /// A divider between groups.
  const AppMenuEntry.divider()
    : value = null,
      label = '',
      icon = null,
      note = null,
      danger = false,
      selected = false,
      leading = null;

  final T? value;
  final String label;
  final IconData? icon;

  /// A mono line on the right: `2 / 2 resolved`.
  final String? note;
  final bool danger;
  final bool selected;

  /// An environment tile instead of a glyph.
  final Widget? leading;

  bool get isDivider => value == null && label.isEmpty;
}

/// An anchored menu: the overflow button, the environment switcher, the
/// per-row actions. `surfaceContainer`, radius 20, a 1px outline.
Future<T?> showAppMenu<T>({
  required BuildContext context,
  required List<AppMenuEntry<T>> entries,
  String? header,
  double width = 260,
}) {
  final AppColors c = context.colors;
  final RenderBox button = context.findRenderObject()! as RenderBox;
  final RenderBox overlay =
      Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
  final Offset topLeft = button.localToGlobal(
    Offset.zero,
    ancestor: overlay,
  );
  final Offset bottomRight = button.localToGlobal(
    button.size.bottomRight(Offset.zero),
    ancestor: overlay,
  );

  return showMenu<T>(
    context: context,
    // Anchored to the control, which is what the board's switcher does.
    position: RelativeRect.fromLTRB(
      topLeft.dx,
      bottomRight.dy + Space.xs,
      overlay.size.width - bottomRight.dx,
      overlay.size.height - bottomRight.dy,
    ),
    color: c.surfaceContainer,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: Radii.cardR,
      side: BorderSide(color: c.outline),
    ),
    constraints: BoxConstraints(minWidth: width, maxWidth: width + 60),
    items: <PopupMenuEntry<T>>[
      if (header != null)
        PopupMenuItem<T>(
          enabled: false,
          height: 32,
          child: Text(
            header.toUpperCase(),
            style: AppType.sectionHeader.copyWith(color: c.onSurfaceVariant),
          ),
        ),
      for (final AppMenuEntry<T> entry in entries)
        if (entry.isDivider)
          PopupMenuDivider(height: 9, color: c.divider)
        else
          PopupMenuItem<T>(
            value: entry.value,
            height: IconSpec.tapTarget,
            child: _MenuRow<T>(entry: entry),
          ),
    ],
  );
}

class _MenuRow<T> extends StatelessWidget {
  const _MenuRow({required this.entry});

  final AppMenuEntry<T> entry;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final Color fg = entry.danger ? c.danger : c.onSurface;
    return Row(
      spacing: Space.md,
      children: <Widget>[
        if (entry.leading != null)
          entry.leading!
        else if (entry.icon != null)
          Icon(
            entry.icon,
            size: IconSpec.small,
            color: entry.danger ? c.danger : c.icon,
          ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 1,
            children: <Widget>[
              Text(
                entry.label,
                style: AppType.titleMedium.copyWith(color: fg),
              ),
              if (entry.note != null)
                Text(
                  entry.note!,
                  style: AppType.monoLabel.copyWith(
                    color: c.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (entry.selected)
          Icon(Icons.check_rounded, size: IconSpec.small, color: c.primary),
      ],
    );
  }
}
