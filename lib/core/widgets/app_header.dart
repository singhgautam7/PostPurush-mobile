import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'app_icon_button.dart';

/// The one header. Every tab root and pushed page uses this and nothing else.
///
/// Left: an optional 48dp circular back button, then the title. Right: up to
/// four identical circular actions. The board sets the screen margin at 20dp
/// and drops it to 16 on a side that carries a button, so the visual edge
/// still lands on 20.
class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.title,
    this.onBack,
    this.actions = const <Widget>[],
    this.backLabel = 'Back',
    this.collapsed = false,
    this.subtitle,
    this.leading,
    super.key,
  });

  final String title;

  /// Null on a tab root, which has nowhere to go back to.
  final VoidCallback? onBack;
  final List<Widget> actions;
  final String backLabel;

  /// Scrolled: the bar takes `surface` with a `divider` hairline under it.
  final bool collapsed;

  /// A `note` line under the title.
  final String? subtitle;

  /// Replaces the back button, for a sheet-like page that closes instead.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final Widget? lead = leading ??
        (onBack == null
            ? null
            : AppIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: onBack,
                semanticLabel: backLabel,
                filled: false,
              ));

    return AnimatedContainer(
      duration: Motion.of(context, Motion.fast),
      decoration: BoxDecoration(
        color: collapsed ? c.surface : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: collapsed ? c.divider : Colors.transparent),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          lead == null ? Space.screen : Space.md,
          Space.sm,
          actions.isEmpty ? Space.screen : Space.md,
          Space.sm,
        ),
        child: Row(
          children: <Widget>[
            if (lead != null) ...<Widget>[lead, const SizedBox(width: Space.xs)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.headerTitle.copyWith(color: c.onSurface),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 2,
                      style: AppType.bodyMedium.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

/// Reports whether a scroll view has moved past its first 24px, so the header
/// above it can collapse.
class CollapseOnScroll extends StatefulWidget {
  const CollapseOnScroll({required this.builder, super.key});

  final Widget Function(BuildContext context, bool collapsed) builder;

  @override
  State<CollapseOnScroll> createState() => _CollapseOnScrollState();
}

class _CollapseOnScrollState extends State<CollapseOnScroll> {
  bool _collapsed = false;

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical || n.depth != 0) return false;
    final bool next = n.metrics.pixels > 24;
    if (next != _collapsed) setState(() => _collapsed = next);
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: widget.builder(context, _collapsed),
      );
}

/// The standard pushed page: the one header with a back button over a
/// scrolling body, with the bottom padding that clears the nav pill.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    required this.title,
    required this.children,
    this.actions = const <Widget>[],
    this.subtitle,
    this.onBack,
    this.floating,
    this.bottomPadding = Space.bottomSafe,
    this.above,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget> actions;
  final VoidCallback? onBack;

  /// A primary action that floats where the nav would be (board 3.3).
  final Widget? floating;
  final double bottomPadding;

  /// Pinned under the header, above the scroll area: a search field, a
  /// segmented control, a filter row.
  final Widget? above;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: CollapseOnScroll(
        builder: (BuildContext context, bool collapsed) => Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppHeader(
                  title: title,
                  subtitle: subtitle,
                  onBack: onBack ?? () => Navigator.of(context).maybePop(),
                  actions: actions,
                  collapsed: collapsed,
                ),
                ?above,
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      Space.screen,
                      Space.md,
                      Space.screen,
                      bottomPadding,
                    ),
                    children: children,
                  ),
                ),
              ],
            ),
            if (floating != null)
              Positioned(
                left: Space.screen,
                right: Space.screen,
                bottom: Space.xl,
                child: SafeArea(top: false, child: floating!),
              ),
          ],
        ),
      ),
    ),
  );
}
