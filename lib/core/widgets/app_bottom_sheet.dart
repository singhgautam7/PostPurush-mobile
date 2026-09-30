import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'section_header.dart';

/// The one sheet shell: a 32x4 handle, 28dp top radius, the sheet's own
/// `surfaceContainer` fill, a scrollable body and optional pinned actions.
///
/// The fill matters: a sheet is `surfaceContainer`, so a card *inside* one is
/// `surface`. Every group in a sheet passes `onSurface: true` for that reason.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    required this.child,
    this.title,
    this.note,
    this.subtitle,
    this.actions,
    this.scrollable = true,
    this.expand = false,
    super.key,
  });

  final Widget child;
  final String? title;

  /// The mono count at the right of the title.
  final String? note;

  /// A mono line under the title.
  final String? subtitle;

  /// Pinned under the body, outside the scroll area.
  final Widget? actions;
  final bool scrollable;

  /// A tall sheet whose body is the only thing that scrolls.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final double height = MediaQuery.sizeOf(context).height;
    final Widget body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.screen),
      child: child,
    );

    return Container(
      constraints: expand
          ? BoxConstraints(minHeight: height * 0.9, maxHeight: height * 0.9)
          : BoxConstraints(maxHeight: height * 0.9),
      decoration: BoxDecoration(
        color: c.surfaceContainer,
        borderRadius: Radii.sheetR,
        border: Border(
          top: BorderSide(color: c.outline),
          left: BorderSide(color: c.outline),
          right: BorderSide(color: c.outline),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: Space.row),
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: c.onSurfaceVariant,
                  borderRadius: Radii.fullR,
                ),
              ),
            ),
            if (title != null) ...<Widget>[
              const SizedBox(height: Space.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.screen),
                child: SheetTitle(
                  title: title!,
                  note: note,
                  subtitle: subtitle,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Flexible(
              fit: expand ? FlexFit.tight : FlexFit.loose,
              child: scrollable ? SingleChildScrollView(child: body) : body,
            ),
            if (actions != null) ...<Widget>[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.screen),
                child: actions!,
              ),
            ],
            const SizedBox(height: Space.xxl),
          ],
        ),
      ),
    );
  }
}

/// Opens [builder] in the shared shell. Everything that presents a sheet goes
/// through here so none of them drift apart.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  String? note,
  String? subtitle,
  Widget? actions,
  bool expand = false,
  bool scrollable = true,
}) {
  final AppColors c = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    // The root navigator, so a sheet covers the floating nav.
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: c.scrim,
    sheetAnimationStyle: AnimationStyle(
      duration: Motion.of(context, Motion.sheet),
      curve: Motion.curveOf(context, Motion.decelerate),
    ),
    builder: (BuildContext context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AppBottomSheet(
        title: title,
        note: note,
        subtitle: subtitle,
        actions: actions,
        expand: expand,
        scrollable: scrollable,
        child: Builder(builder: builder),
      ),
    ),
  );
}

/// A confirmation that names what will be lost. Returns true on confirm.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
}) async {
  final AppColors c = context.colors;
  final bool? ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierColor: c.scrim,
    builder: (BuildContext ctx) => Dialog(
      backgroundColor: c.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sheet),
        side: BorderSide(color: c.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Space.md,
          children: <Widget>[
            Text(title, style: AppType.sheetTitle.copyWith(color: c.onSurface)),
            Text(
              message,
              style: AppType.body.copyWith(color: c.onSurfaceVariant),
            ),
            const SizedBox(height: Space.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: Space.sm,
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(
                    cancelLabel,
                    style: AppType.titleMedium.copyWith(color: c.onSurface),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(
                    confirmLabel,
                    style: AppType.titleMedium.copyWith(color: c.danger),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return ok ?? false;
}

/// A three-way question: Save, Discard or Cancel, which is what closing an
/// unsaved request asks (board 2.8).
enum SaveChoice { save, discard, cancel }

Future<SaveChoice> askToSave(
  BuildContext context, {
  required String name,
}) async {
  final AppColors c = context.colors;
  final SaveChoice? choice = await showDialog<SaveChoice>(
    context: context,
    useRootNavigator: true,
    barrierColor: c.scrim,
    builder: (BuildContext ctx) => Dialog(
      backgroundColor: c.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sheet),
        side: BorderSide(color: c.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Space.md,
          children: <Widget>[
            Text(
              'Save $name?',
              style: AppType.sheetTitle.copyWith(color: c.onSurface),
            ),
            Text(
              'It has edits that are not saved yet.',
              style: AppType.body.copyWith(color: c.onSurfaceVariant),
            ),
            const SizedBox(height: Space.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: Space.sm,
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(SaveChoice.cancel),
                  child: Text(
                    'Cancel',
                    style: AppType.titleMedium.copyWith(color: c.onSurface),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(SaveChoice.discard),
                  child: Text(
                    'Discard',
                    style: AppType.titleMedium.copyWith(color: c.danger),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(SaveChoice.save),
                  child: Text(
                    'Save',
                    style: AppType.titleMedium.copyWith(color: c.accent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return choice ?? SaveChoice.cancel;
}
