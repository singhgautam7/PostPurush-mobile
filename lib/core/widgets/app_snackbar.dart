import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// The undo strip (board 13): `inverseSurface`, radius 20, a 52dp row with the
/// message on the left and one action on the right.
///
/// Every toast in the app comes from here. It floats above the nav pill, so it
/// never covers the destination the user is about to tap.
abstract final class AppSnackbar {
  static const Duration _short = Duration(seconds: 3);
  static const Duration _undo = Duration(seconds: 5);

  static void info(BuildContext context, String message) =>
      _show(context, message: message);

  /// "Request deleted · Undo". The action gets five seconds, which is the
  /// board's own timing for the environment list.
  static void undo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
  }) => _show(
    context,
    message: message,
    actionLabel: 'Undo',
    onAction: onUndo,
    duration: _undo,
  );

  /// A snackbar with a different action, such as "Change" after adding an API
  /// to a collection (board 3.2).
  static void action(
    BuildContext context, {
    required String message,
    required String label,
    required VoidCallback onAction,
  }) => _show(
    context,
    message: message,
    actionLabel: label,
    onAction: onAction,
    duration: _undo,
  );

  static void _show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = _short,
  }) {
    final AppColors c = context.colors;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          behavior: SnackBarBehavior.floating,
          // Clears the nav pill, so the strip never sits on a destination.
          margin: const EdgeInsets.fromLTRB(
            Space.screen,
            0,
            Space.screen,
            NavSpec.height + NavSpec.bottom + Space.row,
          ),
          content: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.only(left: 18, right: Space.sm),
            decoration: BoxDecoration(
              color: c.inverseSurface,
              borderRadius: Radii.cardR,
            ),
            child: Row(
              spacing: Space.md,
              children: <Widget>[
                Expanded(
                  child: Text(
                    message,
                    style: AppType.titleMedium
                        .copyWith(color: c.onInverseSurface)
                        .weight(400),
                  ),
                ),
                if (actionLabel != null)
                  Semantics(
                    button: true,
                    label: actionLabel,
                    child: InkWell(
                      // The Android click sound belongs to the system, not to a tool.
                      enableFeedback: false,
                      onTap: () {
                        messenger.hideCurrentSnackBar();
                        onAction?.call();
                      },
                      borderRadius: Radii.fullR,
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          actionLabel,
                          style: AppType.titleMedium.copyWith(
                            color: c.onInverseSurface,
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
