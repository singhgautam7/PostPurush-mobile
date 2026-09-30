import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/palette.dart';
import '../core/theme/tokens.dart';
import '../core/theme/typography.dart';

@immutable
class NavDestination {
  const NavDestination(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// Collections · Explore · Search · More. Four destinations, evenly spaced,
/// nothing between them. There is no centre action: New request is a floating
/// button on Collections, and the workspace belongs to Collections too.
const List<NavDestination> kDestinations = <NavDestination>[
  NavDestination(Icons.folder_open_rounded, 'Collections'),
  NavDestination(Icons.explore_outlined, 'Explore'),
  NavDestination(Icons.search_rounded, 'Search'),
  NavDestination(Icons.tune_rounded, 'More'),
];

/// The pill: 60dp tall, 8dp padding, radius full, `surface`, a 1px outline and
/// the one shadow. Inactive tabs are icon-only at 44dp; the active tab expands
/// into a labelled `primaryContainer` pill that travels on `navIndicator`.
class NavPill extends StatelessWidget {
  const NavPill({required this.index, required this.onSelect, super.key});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return RepaintBoundary(
      child: Container(
        height: NavSpec.height,
        padding: const EdgeInsets.all(NavSpec.padding),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: Radii.fullR,
          border: Border.all(color: c.outline),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: c.shadow,
              blurRadius: Elevations.navPillBlur,
              offset: const Offset(0, Elevations.navPill),
            ),
          ],
        ),
        child: Row(
          // Hugs its content rather than spanning the screen, so the four
          // destinations sit together instead of at the corners.
          mainAxisSize: MainAxisSize.min,
          spacing: NavSpec.gap,
          children: <Widget>[
            for (int i = 0; i < kDestinations.length; i++)
              _NavItem(
                destination: kDestinations[i],
                selected: i == index,
                onTap: () => onSelect(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    // Under a large OS text scale the label drops and the glyph stays, so the
    // pill never overflows its own row.
    final bool showLabel =
        selected && MediaQuery.textScalerOf(context).scale(14.5) <= 21;
    final Color fg = selected ? c.onPrimaryContainer : c.icon;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.navIndicator),
          // Decelerate, not the spring: an overshooting curve drives the
          // padding tween below zero on its way from 12 to 0, and EdgeInsets
          // asserts on a negative. The spring stays on the size below, where
          // the bounce is what reads as the indicator stretching.
          curve: Motion.curveOf(context, Motion.decelerate),
          height: NavSpec.item,
          constraints: const BoxConstraints(minWidth: NavSpec.item),
          alignment: Alignment.center,
          padding: EdgeInsets.only(
            left: showLabel ? Space.md : 0,
            right: showLabel ? Space.lg : 0,
          ),
          decoration: BoxDecoration(
            color: selected ? c.primaryContainer : Colors.transparent,
            borderRadius: Radii.fullR,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: showLabel ? Space.sm : 0,
            children: <Widget>[
              Icon(destination.icon, size: IconSpec.size, color: fg),
              AnimatedSize(
                duration: Motion.of(context, Motion.navIndicator),
                // Decelerate for the same reason as the padding: for the 220 ms
                // of a change both labels are laid out, the old one shrinking
                // and the new one growing, and an overshooting curve pushes the
                // incoming one past its resting width, overflowing the pill on
                // a narrow screen. The indicator still travels and grows; it
                // just does not bounce past where it is going.
                curve: Motion.curveOf(context, Motion.decelerate),
                alignment: Alignment.centerLeft,
                child: showLabel
                    ? Text(
                        destination.label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        style: AppType.titleMedium.copyWith(color: fg),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
