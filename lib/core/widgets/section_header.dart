import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// `OPEN · 3` on the left in mono caps, a note or a count on the right:
/// `swipe up to close`, `hold to reorder`, `last used`.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.label,
    this.note,
    this.trailing,
    this.accent = false,
    this.inset = false,
    super.key,
  });

  final String label;

  /// The mono note the board puts at the right of most section headers.
  final String? note;

  /// A control instead of a note.
  final Widget? trailing;
  final bool accent;

  /// True when the header sits directly on a page rather than inside a column
  /// that already carries the screen margin.
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Padding(
      padding: inset
          ? const EdgeInsets.symmetric(horizontal: Space.screen)
          : EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.sectionHeader.copyWith(
                color: accent ? c.accent : c.onSurfaceVariant,
              ),
            ),
          ),
          if (trailing != null)
            Flexible(child: trailing!)
          else if (note != null)
            Flexible(
              child: Text(
                note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: AppType.monoLabel.copyWith(color: c.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

/// The 22/1.1 title at the top of a sheet, with its mono count on the right.
class SheetTitle extends StatelessWidget {
  const SheetTitle({required this.title, this.note, this.subtitle, super.key});

  final String title;

  /// `10 methods`, `3 open · 1 unsaved`.
  final String? note;

  /// A mono line under the title: `POST · {{baseUrl}}/posts`.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final Widget line = Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: AppType.sheetTitle.copyWith(color: c.onSurface),
          ),
        ),
        if (note != null)
          Text(
            note!,
            style: AppType.monoLabel.copyWith(color: c.onSurfaceVariant),
          ),
      ],
    );
    if (subtitle == null) return line;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Space.xs,
      children: <Widget>[
        line,
        Text(
          subtitle!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppType.monoLabel.copyWith(color: c.onSurfaceVariant),
        ),
      ],
    );
  }
}
