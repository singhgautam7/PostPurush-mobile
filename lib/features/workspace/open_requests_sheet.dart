import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/api_request.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/util/format.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_icon_button.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/chips.dart';
import 'save_request_sheet.dart';
import 'workspace_controller.dart';

/// Board 2.8. Opens from the title's chevron. Closing one with unsaved edits
/// asks whether to save or discard.
Future<void> showOpenRequestsSheet(BuildContext context, WidgetRef ref) =>
    showAppSheet<void>(
      context: context,
      title: 'Open requests',
      note: _note(ref.read(workspaceProvider)),
      builder: (BuildContext context) => const _OpenRequestsBody(),
    );

String _note(WorkspaceState state) {
  final int unsaved = state.unsavedCount;
  final String open = '${state.tabs.length} open';
  return unsaved == 0 ? open : '$open · $unsaved unsaved';
}

class _OpenRequestsBody extends ConsumerWidget {
  const _OpenRequestsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors c = context.colors;
    final WorkspaceState state = ref.watch(workspaceProvider);
    final WorkspaceController controller = ref.read(
      workspaceProvider.notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Space.lg,
      children: <Widget>[
        RowGroup(
          onSurface: true,
          children: <Widget>[
            for (int i = 0; i < state.tabs.length; i++)
              _TabRow(
                tab: state.tabs[i],
                active: i == state.activeIndex,
                onTap: () {
                  controller.focus(i);
                  Navigator.of(context).pop();
                },
                onClose: () => _close(context, ref, state.tabs[i]),
              ),
          ],
        ),
        Row(
          spacing: Space.row,
          children: <Widget>[
            Expanded(
              child: AppButton(
                label: 'Close saved',
                onPressed: state.tabs.any((WorkspaceTab t) => !t.dirty)
                    ? () {
                        controller.closeSaved();
                        Navigator.of(context).pop();
                      }
                    : null,
                type: AppButtonType.outlined,
                fullWidth: true,
              ),
            ),
            Expanded(
              child: AppButton(
                label: 'New request',
                icon: Icons.bolt_rounded,
                filledIcon: true,
                onPressed: () {
                  controller.openBlank();
                  Navigator.of(context).pop();
                },
                fullWidth: true,
              ),
            ),
          ],
        ),
        if (state.tabs.isEmpty)
          Text(
            'Nothing is open.',
            style: AppType.bodyMedium.copyWith(color: c.onSurfaceVariant),
          ),
      ],
    );
  }

  Future<void> _close(
    BuildContext context,
    WidgetRef ref,
    WorkspaceTab tab,
  ) async {
    final WorkspaceController controller = ref.read(
      workspaceProvider.notifier,
    );
    if (!tab.dirty) {
      controller.close(tab.id);
      return;
    }
    final SaveChoice choice = await askToSave(
      context,
      name: tab.draft.displayName,
    );
    if (!context.mounted) return;
    switch (choice) {
      case SaveChoice.cancel:
        return;
      case SaveChoice.discard:
        controller.close(tab.id);
      case SaveChoice.save:
        controller.focusId(tab.id);
        if (tab.saved == null) {
          final SaveTarget? target = await showSaveRequestSheet(
            context,
            ref,
            request: tab.draft,
          );
          if (target == null) return;
          await controller.save(name: target.name, folderId: target.folderId);
        } else {
          await controller.save();
        }
        controller.close(tab.id);
    }
  }
}

class _TabRow extends StatelessWidget {
  const _TabRow({
    required this.tab,
    required this.active,
    required this.onTap,
    required this.onClose,
  });

  final WorkspaceTab tab;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final (String line, Color colour) = _status(context, tab);
    return AppRow(
      title: tab.draft.displayName,
      subtitle: line,
      subtitleColor: active ? c.onPrimaryContainer : colour,
      selected: active,
      leading: MethodChip(tab.draft.method),
      titleTrailing: tab.dirty
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? c.primary : c.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
      trailing: AppIconButton(
        icon: Icons.close_rounded,
        onPressed: onClose,
        semanticLabel: 'Close ${tab.draft.displayName}',
        filled: false,
        tint: active ? c.onPrimaryContainer : c.iconMuted,
      ),
      onTap: onTap,
      minHeight: 64,
    );
  }

  static (String, Color) _status(BuildContext context, WorkspaceTab tab) {
    final AppColors c = context.colors;
    final List<String> parts = <String>[];
    Color colour = c.onSurfaceVariant;
    if (tab.sending) {
      parts.add('sending');
    } else if (tab.response != null) {
      final int status = tab.response!.statusCode;
      parts.add(status == 0 ? 'no response' : '$status');
      if (status >= 400 || status == 0) colour = c.danger;
    } else if (tab.dirty) {
      parts.add('unsaved');
    } else {
      parts.add('saved');
    }
    if (tab.sentAt != null) parts.add(Fmt.relative(tab.sentAt!));
    return (parts.join(' · '), colour);
  }
}
