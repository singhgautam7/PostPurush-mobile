import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'app_button.dart';

/// The empty state the board draws (1.2, 5.2, 10.3): a tinted 64dp tile with
/// one glyph, the display line, a sentence, then the ways in.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.primaryLabel,
    this.onPrimary,
    this.primaryIcon = Icons.bolt_rounded,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryIcon,
    this.danger = false,
    this.topPadding = 120,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final IconData primaryIcon;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final IconData? secondaryIcon;
  final bool danger;

  /// The board's empty states sit well down the page rather than centred.
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Space.screen,
        topPadding,
        Space.screen,
        Space.bottomSafe,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Space.lg,
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: danger ? c.dangerContainer : c.primaryContainer,
              borderRadius: Radii.cardR,
            ),
            child: Icon(
              icon,
              size: 32,
              color: danger ? c.onDangerContainer : c.onPrimaryContainer,
            ),
          ),
          Text(title, style: AppType.display.copyWith(color: c.onSurface)),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              message,
              style: AppType.body.copyWith(color: c.onSurfaceVariant),
            ),
          ),
          if (primaryLabel != null || secondaryLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: Wrap(
                spacing: Space.row,
                runSpacing: Space.row,
                children: <Widget>[
                  if (primaryLabel != null)
                    AppButton(
                      label: primaryLabel!,
                      onPressed: onPrimary,
                      icon: primaryIcon,
                      filledIcon: true,
                    ),
                  if (secondaryLabel != null)
                    AppButton(
                      label: secondaryLabel!,
                      onPressed: onSecondary,
                      icon: secondaryIcon,
                      type: AppButtonType.outlined,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The same shape, in danger, with one retry.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.error_outline_rounded,
    title: 'That did not load',
    message: message,
    danger: true,
    primaryLabel: onRetry == null ? null : 'Try again',
    primaryIcon: Icons.refresh_rounded,
    onPrimary: onRetry,
  );
}

/// An inline error well: a 20dp glyph and one sentence in `dangerContainer`
/// (board 13, "Inline errors").
class InlineError extends StatelessWidget {
  const InlineError({
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final IconData icon;

  /// The one-tap fix, such as "Add it" for a missing variable.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: EdgeInsets.only(
        left: 14,
        right: actionLabel == null ? 14 : 6,
      ),
      decoration: BoxDecoration(
        color: c.dangerContainer,
        borderRadius: Radii.cardR,
      ),
      child: Row(
        spacing: Space.row,
        children: <Widget>[
          Icon(icon, size: IconSpec.small, color: c.onDangerContainer),
          Expanded(
            child: Text(
              message,
              style: AppType.bodyMedium.copyWith(color: c.onDangerContainer),
            ),
          ),
          if (actionLabel != null)
            Semantics(
              button: true,
              label: actionLabel,
              child: InkWell(
                onTap: onAction,
                borderRadius: Radii.fullR,
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    actionLabel!,
                    style: AppType.titleMedium.copyWith(
                      color: c.onDangerContainer,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Nothing at all until [after] has passed, then [child].
///
/// A loader that flashes is worse than no loader. Work that finishes inside
/// the threshold shows [placeholder] (nothing, by default) and the screen
/// arrives whole. The board's rule is 250 ms, for work like opening a large
/// imported collection.
class Delayed extends StatefulWidget {
  const Delayed({
    required this.child,
    this.after = Motion.loadingThreshold,
    this.placeholder = const SizedBox.shrink(),
    super.key,
  });

  final Widget child;
  final Duration after;
  final Widget placeholder;

  @override
  State<Delayed> createState() => _DelayedState();
}

class _DelayedState extends State<Delayed> {
  Timer? _timer;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.after, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _shown ? widget.child : widget.placeholder;
}

/// A muted bar standing in for a line of text. Not shimmering: loading is
/// never the dominant impression.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({this.width, this.widthFactor, this.height = 12, super.key});

  final double? width;

  /// A fraction of the available width, which is how the board draws them.
  final double? widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final Widget bar = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: Radii.fullR,
      ),
    );
    if (widthFactor == null) return bar;
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: bar,
    );
  }
}

/// A request row's skeleton: the method chip's block and two lines.
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({this.titleFactor = 0.6, this.subtitleFactor = 0.85, super.key});

  final double titleFactor;
  final double subtitleFactor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: 14),
    child: Row(
      spacing: Space.md,
      children: <Widget>[
        Container(
          width: 60,
          height: 22,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHigh,
            borderRadius: Radii.chipR,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: <Widget>[
              SkeletonLine(widthFactor: titleFactor),
              SkeletonLine(widthFactor: subtitleFactor, height: 10),
            ],
          ),
        ),
      ],
    ),
  );
}
