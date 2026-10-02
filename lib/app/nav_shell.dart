import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/tokens.dart';
import 'nav_bar.dart';

/// True while a full-screen surface wants the pill gone: an expanded response
/// sheet, the API doc reading view. The pill leaves downward on `navHide`.
final NotifierProvider<NavHidden, bool> navHiddenProvider =
    NotifierProvider<NavHidden, bool>(NavHidden.new);

class NavHidden extends Notifier<bool> {
  @override
  bool build() => false;

  void set({required bool hidden}) {
    if (state != hidden) state = hidden;
  }
}

/// Hosts the four destinations and the floating pill.
///
/// The pill hides on a scroll down past 24px and comes back on any scroll up,
/// and a horizontal fling anywhere on the page moves to the next destination.
class NavShell extends ConsumerStatefulWidget {
  const NavShell({
    required this.child,
    required this.index,
    required this.onSelect,
    this.tabCount = 4,
    this.onAdd,
    this.onAddLongPress,
    super.key,
  });

  final Widget child;
  final int index;
  final ValueChanged<int> onSelect;
  final int tabCount;

  /// When set, a circular action button sits beside the pill, on the same line.
  /// Null on destinations that have no primary action.
  final VoidCallback? onAdd;
  final VoidCallback? onAddLongPress;

  @override
  ConsumerState<NavShell> createState() => _NavShellState();
}

class _NavShellState extends ConsumerState<NavShell>
    with TickerProviderStateMixin {
  late final AnimationController _hide = AnimationController(
    vsync: this,
    duration: Motion.navHide,
  );
  late final AnimationController _page = AnimationController(
    vsync: this,
    duration: Motion.containerTransform,
    value: 1,
  );
  double _lastOffset = 0;
  bool _forward = true;
  bool _navHidden = false;

  @override
  void didUpdateWidget(NavShell old) {
    super.didUpdateWidget(old);
    if (widget.index != old.index) {
      _forward = widget.index > old.index;
      _page.forward(from: 0);
      _hide.reverse();
    }
  }

  @override
  void dispose() {
    _hide.dispose();
    _page.dispose();
    super.dispose();
  }

  /// Only a decisive horizontal fling counts; vertical drags belong to the list.
  ///
  /// It is ignored entirely while the pill is hidden, because the pill is
  /// hidden exactly when a page has taken over the shell (the workspace, a
  /// response sheet, the keyboard), and swiping to another destination from
  /// under a page is not something anyone means to do.
  void _onFling(DragEndDetails details) {
    if (_navHidden) return;
    final double velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 240) return;
    final int next = velocity < 0 ? widget.index + 1 : widget.index - 1;
    if (next < 0 || next >= widget.tabCount) return;
    widget.onSelect(next);
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical || n is! ScrollUpdateNotification) {
      return false;
    }
    final double offset = n.metrics.pixels;
    final double delta = offset - _lastOffset;
    if (delta.abs() < 2) return false;
    _lastOffset = offset;
    if (delta > 0 && offset > 24) {
      _hide.forward();
    } else if (delta < 0) {
      _hide.reverse();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bool reduced = Motion.reduced(context);
    final bool keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bool hidden = keyboardUp || ref.watch(navHiddenProvider);
    _navHidden = hidden;
    final Animation<double> page = CurvedAnimation(
      parent: _page,
      curve: Motion.curveOf(context, Motion.decelerate),
    );
    return PopScope(
      canPop: widget.index == 0,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) widget.onSelect(0);
      },
      child: Scaffold(
        // Not resizing here is what lets the screens below see the keyboard;
        // each of them has its own Scaffold, which does resize. The pill is
        // hidden while the keyboard is up, so it has nothing to move out of.
        resizeToAvoidBottomInset: false,
        body: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: Stack(
            children: <Widget>[
              GestureDetector(
                onHorizontalDragEnd: _onFling,
                behavior: HitTestBehavior.translucent,
                child: ClipRect(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: page,
                      builder: (BuildContext context, Widget? child) {
                        final double t = page.value;
                        if (t == 1 || reduced) return child!;
                        return FractionalTranslation(
                          translation: Offset(
                            _forward ? 1 - t : -(1 - t),
                            0,
                          ),
                          child: child,
                        );
                      },
                      child: widget.child,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: NavSpec.bottom,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _hide,
                    builder: (BuildContext context, Widget? child) {
                      final double t = hidden ? 1 : _hide.value;
                      return Opacity(
                        opacity: 1 - t,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            reduced ? 0 : NavSpec.hideTravel * t,
                          ),
                          child: IgnorePointer(ignoring: t > 0.5, child: child),
                        ),
                      );
                    },
                    child: SafeArea(
                      top: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: Space.row,
                        children: <Widget>[
                          NavPill(
                            index: widget.index,
                            onSelect: widget.onSelect,
                          ),
                          if (widget.onAdd != null)
                            NavFab(
                              onTap: widget.onAdd!,
                              onLongPress: widget.onAddLongPress,
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
      ),
    );
  }
}
