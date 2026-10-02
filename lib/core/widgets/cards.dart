import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// The one card: `surfaceContainer`, radius 20, a 1px `outline`, no shadow.
/// Depth lives in the outline, so nothing here takes an elevation.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(Space.lg),
    this.onTap,
    this.selected = false,
    this.danger = false,
    this.radius = Radii.card,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// `primaryContainer` fill, for the open request you are looking at.
  final bool selected;
  final bool danger;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final Color fill = danger
        ? c.dangerContainer
        : selected
        ? c.primaryContainer
        : c.surfaceContainer;
    final Widget body = Padding(padding: padding, child: child);
    // The shape carries the radius. Material asserts if both are given, and
    // the outline is what the card's depth is made of, so the shape wins.
    return Material(
      color: fill,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: danger ? c.dangerContainer : c.outline),
      ),
      child: onTap == null
          ? body
          : InkWell(enableFeedback: false, onTap: onTap, child: body),
    );
  }
}

/// A run of rows drawn as one rounded container with `divider` hairlines
/// between them: the folders list, headers, variables, methods, assertions.
///
/// [onSurface] inverts the fill for a card that sits inside a sheet, where the
/// sheet already owns `surfaceContainer`.
class RowGroup extends StatelessWidget {
  const RowGroup({
    required this.children,
    this.onSurface = false,
    this.radius = Radii.card,
    super.key,
  });

  final List<Widget> children;
  final bool onSurface;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    if (children.isEmpty) return const SizedBox.shrink();
    // Material, not Container: a Container clips its child to the outer edge of
    // its border, so a filled row paints under the outline and the outline
    // reads as a second line floating inside the group. Material's shape clips
    // to the inside of the side, which is what the board draws.
    return Material(
      color: onSurface ? c.surface : c.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: c.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) Divider(color: c.divider, height: 1),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// [RowGroup] for a list long enough that building it all at once is felt.
///
/// A group of a dozen rows is cheaper as a Column than as a sliver. A group of
/// two hundred, rebuilt on every keystroke of a search, is not: this one keeps
/// the group's fill, outline and hairlines but builds only the rows on screen.
class SliverRowGroup extends StatelessWidget {
  const SliverRowGroup({
    required this.itemCount,
    required this.itemBuilder,
    this.onSurface = false,
    this.radius = Radii.card,
    super.key,
  });

  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;
  final bool onSurface;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    if (itemCount == 0) return const SliverToBoxAdapter();
    // The fill and the outline are painted behind the rows rather than
    // clipping them, because a sliver has no single box to clip to. Rows carry
    // no fill of their own, so the rounded corners read the same as the
    // Column version.
    return DecoratedSliver(
      decoration: BoxDecoration(
        color: onSurface ? c.surface : c.surfaceContainer,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.outline),
      ),
      sliver: SliverList.builder(
        itemCount: itemCount,
        itemBuilder: (BuildContext context, int i) {
          final Widget? row = itemBuilder(context, i);
          if (row == null) return null;
          return i == 0
              ? row
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Divider(color: c.divider, height: 1),
                    row,
                  ],
                );
        },
      ),
    );
  }
}

/// One row inside a [RowGroup]: a leading glyph or chip, a title with an
/// optional second line, a count, and a trailing control.
class AppRow extends StatelessWidget {
  const AppRow({
    required this.title,
    this.leading,
    this.subtitle,
    this.subtitleColor,
    this.trailing,
    this.count,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.indent = 0,
    this.minHeight = 56,
    this.titleTrailing,
    super.key,
  });

  final String title;
  final Widget? leading;
  final String? subtitle;

  /// A failed status in `danger`, which the open-requests sheet does.
  final Color? subtitleColor;
  final Widget? trailing;

  /// The mono count on the right of a folder row.
  final String? count;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  /// 24dp per level, which is what the board's subfolder row uses.
  final double indent;
  final double minHeight;

  /// A glyph right after the title, such as the unsaved dot.
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final Color fg = selected ? c.onPrimaryContainer : c.onSurface;
    final Color sub =
        subtitleColor ?? (selected ? c.onPrimaryContainer : c.onSurfaceVariant);

    final Widget content = Container(
      color: selected ? c.primaryContainer : null,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: EdgeInsets.only(left: Space.lg + indent, right: Space.xs),
      child: Row(
        spacing: Space.md,
        children: <Widget>[
          ?leading,
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.titleMedium.copyWith(color: fg),
                      ),
                    ),
                    ?titleTrailing,
                  ],
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.monoLabel.copyWith(color: sub),
                  ),
              ],
            ),
          ),
          if (count != null)
            Text(count!, style: AppType.monoLabel.copyWith(color: sub)),
          ?trailing,
        ],
      ),
    );

    if (onTap == null && onLongPress == null) return content;
    return Semantics(
      button: true,
      selected: selected,
      label: subtitle == null ? title : '$title, $subtitle',
      child: InkWell(
        enableFeedback: false,
        onTap: onTap,
        onLongPress: onLongPress,
        child: content,
      ),
    );
  }
}

/// A figure on a label: `Requests 1,284`, `Success 94.2%`. Four across on the
/// analytics overview, so the label wraps rather than the figure shrinking.
class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    this.unit,
    this.tint,
    super.key,
  });

  final String label;
  final String value;

  /// `%` or `ms`, drawn smaller after the figure.
  final String? unit;

  /// `danger` for an error rate, `success` for a success rate.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.monoLabel.copyWith(color: c.onSurfaceVariant),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 2,
            children: <Widget>[
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.figure.copyWith(color: tint ?? c.onSurface),
                ),
              ),
              if (unit != null)
                Text(
                  unit!,
                  style: AppType.monoLabel.copyWith(color: c.onSurfaceVariant),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
