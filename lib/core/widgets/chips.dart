import 'package:flutter/material.dart';

import '../models/api_response.dart';
import '../models/http_method.dart';
import '../theme/app_theme.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// The method colours: a foreground and a tinted well per method, re-derived
/// per tone. TRACE and CONNECT have no hue and fall back to neutral.
extension MethodColors on AppColors {
  Color methodFg(HttpMethod m) =>
      m.hue == null ? onSurfaceVariant : hue(m.hue!);

  Color methodBg(HttpMethod m) =>
      m.hue == null ? surfaceContainerHigh : hueContainer(m.hue!);
}

/// `GET` on its tinted well. Fixed 60dp wide so method names line up down a
/// list, which is the whole reason the board pins the width (13).
class MethodChip extends StatelessWidget {
  const MethodChip(this.method, {this.width = 60, this.height = 22, super.key});

  /// Null lets the chip size to its label, for the open-requests strip.
  const MethodChip.auto(this.method, {super.key})
    : width = null,
      height = 22;

  /// The larger chip on the method sheet.
  const MethodChip.large(this.method, {super.key}) : width = 76, height = 26;

  final HttpMethod method;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      padding: width == null
          ? const EdgeInsets.symmetric(horizontal: 6)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: c.methodBg(method),
        borderRadius: Radii.chipR,
      ),
      child: Text(
        method.label,
        style: (height >= 26 ? AppType.monoChip : AppType.monoLabelStrong)
            .copyWith(color: c.methodFg(method)),
      ),
    );
  }
}

/// `200 OK` with its dot, so colour is never the only signal. A send that
/// produced nothing gets a dashed danger outline instead of a fill.
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.status,
    required this.reasonPhrase,
    this.arrived = true,
    super.key,
  });

  StatusChip.of(ApiResponse response, {super.key})
    : status = response.statusCode,
      reasonPhrase = response.reasonPhrase,
      arrived = response.arrived;

  final int status;
  final String reasonPhrase;
  final bool arrived;

  /// The dot and fill for a status band. 2xx is success, 5xx is danger, and
  /// 3xx and 4xx take the two category hues the board assigns them.
  static (Color dot, Color fill, Color text) rolesFor(
    AppColors c,
    int status, {
    required bool arrived,
  }) {
    if (!arrived) {
      return (c.danger, Colors.transparent, c.onDangerContainer);
    }
    if (status >= 500) return (c.danger, c.dangerContainer, c.onDangerContainer);
    if (status >= 400) {
      return (c.hue(AppColors.catHues[3]), c.hueContainer(AppColors.catHues[3]), c.onSurface);
    }
    if (status >= 300) {
      return (c.hue(AppColors.catHues[1]), c.hueContainer(AppColors.catHues[1]), c.onSurface);
    }
    if (status >= 200) {
      return (c.success, c.successContainer, c.onSuccessContainer);
    }
    return (c.onSurfaceVariant, c.surfaceContainerHigh, c.onSurface);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final (Color dot, Color fill, Color text) = rolesFor(
      c,
      status,
      arrived: arrived,
    );
    final String label = arrived ? '$status $reasonPhrase' : 'No response';
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: Radii.fullR,
        border: arrived ? null : Border.all(color: c.danger),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: <Widget>[
          if (arrived)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
          Text(
            label,
            style: AppType.monoTabular.copyWith(
              color: text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A filter or choice chip. `primaryContainer` when selected, with an optional
/// leading check, which is how the board draws the Explore filters.
class PillChip extends StatelessWidget {
  const PillChip({
    required this.label,
    this.onTap,
    this.selected = false,
    this.icon,
    this.showCheck = false,
    this.count,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final IconData? icon;

  /// A leading check when selected, rather than a leading icon.
  final bool showCheck;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final Color fg = selected ? c.onPrimaryContainer : c.onSurface;
    final IconData? glyph = selected && showCheck
        ? Icons.check_rounded
        : (showCheck ? null : icon);
    return Semantics(
      button: onTap != null,
      selected: selected,
      child: Material(
        color: selected ? c.primaryContainer : c.surfaceContainerHigh,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // The Android click sound belongs to the system, not to a tool.
          enableFeedback: false,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: EdgeInsets.only(
              left: glyph == null ? 14 : 10,
              right: 14,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: <Widget>[
                if (glyph != null)
                  Icon(
                    glyph,
                    size: IconSpec.tiny,
                    color: selected ? fg : c.iconMuted,
                  ),
                Text(label, style: AppType.chipLabel.copyWith(color: fg)),
                if (count != null)
                  Text(
                    '$count',
                    style: AppType.monoLabel.copyWith(
                      color: selected
                          ? c.onPrimaryContainer
                          : c.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Params / Headers / Body / Auth, Requests / History / APIs, Assertions /
/// Load. A `surfaceContainerHigh` track with a `surface` thumb that carries a
/// 1px outline, and optional counts inside each label.
class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.badges = const <Object?, String>{},
    super.key,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  /// A count or a fraction shown after the label, as the board's `2/3`.
  final Map<Object?, String> badges;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.all(Space.xs),
      decoration: BoxDecoration(
        color: c.surfaceContainerHigh,
        borderRadius: Radii.fullR,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final (T value, String label) in options)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: value == selected,
                  child: InkWell(
                    // The Android click sound belongs to the system, not to a tool.
                    enableFeedback: false,
                    onTap: () => onChanged(value),
                    borderRadius: Radii.fullR,
                    child: AnimatedContainer(
                      duration: Motion.of(context, Motion.lensSwap),
                      curve: Motion.curveOf(context, Motion.spring),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: value == selected ? c.surface : Colors.transparent,
                        borderRadius: Radii.fullR,
                        border: Border.all(
                          color: value == selected
                              ? c.outline
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 5,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.titleMedium.copyWith(
                                color: value == selected
                                    ? c.onSurface
                                    : c.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (badges[value] != null)
                            Text(
                              badges[value]!,
                              style: AppType.monoLabel.copyWith(
                                color: c.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A small tinted square holding an environment's icon in its own hue: the
/// switcher chip, the environment list, the icon and colour sheets.
class EnvTile extends StatelessWidget {
  const EnvTile({
    required this.icon,
    required this.colourIndex,
    this.size = 28,
    this.radius = Radii.full,
    super.key,
  });

  /// No environment: a muted `public_off` on the neutral well.
  const EnvTile.none({this.size = 28, this.radius = Radii.full, super.key})
    : icon = Icons.public_off_rounded,
      colourIndex = null;

  final IconData icon;

  /// Null draws the neutral well, which is what "No environment" looks like.
  final int? colourIndex;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final Color fg = colourIndex == null
        ? c.iconMuted
        : c.cat(colourIndex!);
    final Color bg = colourIndex == null
        ? c.surfaceContainerHigh
        : c.catContainer(colourIndex!);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: size * 0.64, color: fg),
    );
  }
}
