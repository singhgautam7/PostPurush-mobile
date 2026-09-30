import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/tokens.dart';

/// The push transition: Material's shared-axis Z.
///
/// The incoming page rises from 92% and fades in while the outgoing one sinks
/// away behind it and fades out, so a push reads as one surface replacing
/// another rather than a cut. Both halves matter: without the outgoing scale
/// the change is easy to miss, which is what "no animation" usually means.
///
/// Under reduced motion it is a 90 ms cross-fade and nothing moves.
CustomTransitionPage<T> appPage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: Motion.containerTransform,
    reverseTransitionDuration: Motion.containerTransform,
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondary,
          Widget child,
        ) => SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondary,
          child: child,
        ),
  );
}

/// Material's shared-axis Z, written out rather than pulled in: the package
/// would be one dependency for two tweens, and this way the curves come from
/// the token layer like everything else.
class SharedAxisTransition extends StatelessWidget {
  const SharedAxisTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    super.key,
  });

  /// This page arriving.
  final Animation<double> animation;

  /// The page above it arriving, which pushes this one away.
  final Animation<double> secondaryAnimation;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    final Animation<double> incoming = CurvedAnimation(
      parent: animation,
      curve: Motion.decelerate,
      reverseCurve: Curves.easeInCubic,
    );
    final Animation<double> outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Motion.decelerate,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      // The outgoing page fades out over the first half, so the two never both
      // sit at full opacity and the change never looks like a dissolve.
      opacity: Tween<double>(begin: 1, end: 0).animate(outgoing),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 1.06).animate(outgoing),
        child: FadeTransition(
          opacity: incoming,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(incoming),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A cross-fade for a region whose contents change in place: a pane swapping,
/// a list becoming an empty state, a figure being recomputed.
///
/// One wrapper so every such change has the same timing, and so none of them
/// is a hard cut.
class AppSwitcher extends StatelessWidget {
  const AppSwitcher({
    required this.child,
    this.duration,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  /// Needs a `key` that changes when the content does, or nothing animates.
  final Widget child;
  final Duration? duration;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: Motion.of(context, duration ?? Motion.lensSwap),
    switchInCurve: Motion.curveOf(context, Motion.decelerate),
    switchOutCurve: Motion.curveOf(context, Motion.decelerate),
    // The default lays the outgoing child on top of the incoming one, which
    // reads as a smear when both are full-width lists.
    layoutBuilder: (Widget? current, List<Widget> previous) => Stack(
      alignment: alignment,
      children: <Widget>[
        for (final Widget old in previous) old,
        ?current,
      ],
    ),
    transitionBuilder: (Widget child, Animation<double> value) {
      if (Motion.reduced(context)) {
        return FadeTransition(opacity: value, child: child);
      }
      return FadeTransition(
        opacity: value,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(value),
          child: child,
        ),
      );
    },
    child: child,
  );
}

/// Slides a region in from the bottom and fades it, for something that appears
/// beside what is already there: the dock, an inline error, a strip.
class AppReveal extends StatelessWidget {
  const AppReveal({
    required this.visible,
    required this.child,
    this.duration,
    this.from = const Offset(0, 0.25),
    super.key,
  });

  final bool visible;
  final Widget child;
  final Duration? duration;

  /// Where it comes from, as a fraction of its own size.
  final Offset from;

  @override
  Widget build(BuildContext context) {
    final Duration length = Motion.of(context, duration ?? Motion.sheet);
    return AnimatedSlide(
      offset: visible ? Offset.zero : from,
      duration: length,
      curve: Motion.curveOf(context, Motion.decelerate),
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: length,
        curve: Motion.curveOf(context, Motion.decelerate),
        child: IgnorePointer(ignoring: !visible, child: child),
      ),
    );
  }
}
