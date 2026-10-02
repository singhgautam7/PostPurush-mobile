import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/key_value.dart';
import '../../core/providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/util/ids.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/key_value_editor.dart';
import '../../core/widgets/section_header.dart';
import 'settings_controller.dart';

/// Board 7. Everything that changes what gets sent is grouped together. Mode,
/// true black and colour all live on the Theme page.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors c = context.colors;
    final AppSettings s = ref.watch(settingsProvider);
    final SettingsController controller = ref.read(settingsProvider.notifier);

    return PageScaffold(
      title: 'Settings',
      children: <Widget>[
        const SectionHeader(label: 'Appearance'),
        const SizedBox(height: Space.row),
        RowGroup(
          children: <Widget>[
            AppRow(
              title: 'Theme',
              count: s.dynamicColor ? 'Wallpaper' : s.family.name,
              leading: Icon(
                Icons.palette_outlined,
                size: IconSpec.small,
                color: c.icon,
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                size: IconSpec.small,
                color: c.onSurfaceMuted,
              ),
              onTap: () => context.push(Routes.theme),
            ),
          ],
        ),
        const SizedBox(height: Space.section),
        const SectionHeader(
          label: 'Requests',
          note: 'what goes on the wire',
        ),
        const SizedBox(height: Space.row),
        RowGroup(
          children: <Widget>[
            AppRow(
              title: 'Timeout',
              count: '${s.timeoutSeconds} s',
              leading: Icon(
                Icons.timer_outlined,
                size: IconSpec.small,
                color: c.icon,
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                size: IconSpec.small,
                color: c.onSurfaceMuted,
              ),
              onTap: () => _pickTimeout(context, ref, s),
            ),
            AppRow(
              title: 'Default headers',
              count: s.defaultHeaders.isEmpty
                  ? 'none'
                  : '${s.defaultHeaders.length} on every request',
              leading: Icon(
                Icons.list_alt_rounded,
                size: IconSpec.small,
                color: c.icon,
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                size: IconSpec.small,
                color: c.onSurfaceMuted,
              ),
              onTap: () => context.push(Routes.defaultHeaders),
            ),
            SwitchRow(
              label: 'Follow redirects',
              icon: Icons.call_split_rounded,
              value: s.followRedirects,
              onChanged: (bool value) =>
                  controller.setFollowRedirects(value: value),
            ),
            SwitchRow(
              label: 'Verify SSL certificates',
              note: 'turn off for self-signed local servers',
              icon: Icons.lock_outline_rounded,
              value: s.verifySsl,
              onChanged: (bool value) async {
                if (value) {
                  await controller.setVerifySsl(value: true);
                  return;
                }
                // Turning verification off is the one setting here that can
                // expose a request, so it is confirmed and says why.
                final bool ok = await confirmDialog(
                  context,
                  title: 'Stop verifying certificates?',
                  message:
                      'A request could then be intercepted without warning. '
                      'Only do this for a local server with a self-signed '
                      'certificate, and turn it back on afterwards.',
                  confirmLabel: 'Turn off',
                );
                if (ok) await controller.setVerifySsl(value: false);
              },
            ),
          ],
        ),
        const SizedBox(height: Space.section),
        const SectionHeader(label: 'History'),
        const SizedBox(height: Space.row),
        RowGroup(
          children: <Widget>[
            AppRow(
              title: 'Keep history',
              count: '${s.historyDays} days',
              leading: Icon(
                Icons.schedule_rounded,
                size: IconSpec.small,
                color: c.icon,
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                size: IconSpec.small,
                color: c.onSurfaceMuted,
              ),
              onTap: () => _pickRetention(context, ref, s),
            ),
            AppRow(
              title: 'Clear history',
              leading: Icon(
                Icons.delete_outline_rounded,
                size: IconSpec.small,
                color: c.danger,
              ),
              onTap: () async {
                final bool ok = await confirmDialog(
                  context,
                  title: 'Clear history?',
                  message:
                      'Every entry goes. Saved requests and folders are '
                      'not touched.',
                  confirmLabel: 'Clear',
                );
                if (ok) await ref.read(historyRepositoryProvider).clear();
              },
            ),
          ],
        ),
        const SizedBox(height: Space.section),
        const SectionHeader(label: 'Time'),
        const SizedBox(height: Space.row),
        SegmentedToggle<TimeStyle>(
          options: const <(TimeStyle, String)>[
            (TimeStyle.relative, 'Relative'),
            (TimeStyle.absolute, 'Absolute'),
          ],
          badges: const <Object?, String>{
            TimeStyle.relative: '2 min ago',
            TimeStyle.absolute: '14:07',
          },
          selected: s.timeStyle,
          onChanged: controller.setTimeStyle,
        ),
        const SizedBox(height: Space.section),
        Row(
          spacing: Space.sm,
          children: <Widget>[
            Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: c.onSurfaceMuted,
            ),
            Expanded(
              child: Text(
                'No account, no sync. Your data stays on this device.',
                style: AppType.bodySmall.copyWith(color: c.onSurfaceMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickTimeout(
    BuildContext context,
    WidgetRef ref,
    AppSettings s,
  ) async {
    final int? chosen = await showAppSheet<int>(
      context: context,
      title: 'Timeout',
      subtitle: 'how long to wait before giving up',
      builder: (BuildContext context) => RowGroup(
        onSurface: true,
        children: <Widget>[
          for (final int seconds in AppSettings.timeoutChoices)
            AppRow(
              title: '$seconds seconds',
              minHeight: 52,
              selected: s.timeoutSeconds == seconds,
              trailing: SizedBox(
                width: IconSpec.tapTarget,
                height: IconSpec.tapTarget,
                child: Center(
                  child: Icon(
                    s.timeoutSeconds == seconds
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: IconSpec.size,
                  ),
                ),
              ),
              onTap: () => Navigator.of(context).pop(seconds),
            ),
        ],
      ),
    );
    if (chosen != null) {
      await ref.read(settingsProvider.notifier).setTimeout(chosen);
    }
  }

  Future<void> _pickRetention(
    BuildContext context,
    WidgetRef ref,
    AppSettings s,
  ) async {
    final int? chosen = await showAppSheet<int>(
      context: context,
      title: 'Keep history',
      subtitle: 'older entries are deleted on launch',
      builder: (BuildContext context) => RowGroup(
        onSurface: true,
        children: <Widget>[
          for (final int days in AppSettings.historyChoices)
            AppRow(
              title: days == 365 ? 'One year' : '$days days',
              minHeight: 52,
              selected: s.historyDays == days,
              trailing: SizedBox(
                width: IconSpec.tapTarget,
                height: IconSpec.tapTarget,
                child: Center(
                  child: Icon(
                    s.historyDays == days
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: IconSpec.size,
                  ),
                ),
              ),
              onTap: () => Navigator.of(context).pop(days),
            ),
        ],
      ),
    );
    if (chosen != null) {
      await ref.read(settingsProvider.notifier).setHistoryDays(chosen);
    }
  }
}

/// The default-headers page. The same key/value editor as the request tabs, so
/// it behaves identically, including bulk edit.
class DefaultHeadersScreen extends ConsumerStatefulWidget {
  const DefaultHeadersScreen({super.key});

  @override
  ConsumerState<DefaultHeadersScreen> createState() =>
      _DefaultHeadersScreenState();
}

class _DefaultHeadersScreenState extends ConsumerState<DefaultHeadersScreen> {
  late List<KeyValueRow> _rows = <KeyValueRow>[
    for (final MapEntry<String, String> e
        in ref.read(settingsProvider).defaultHeaders.entries)
      KeyValueRow(id: newId(), key: e.key, value: e.value),
  ];

  Future<void> _save(List<KeyValueRow> rows) async {
    setState(() => _rows = rows);
    await ref.read(settingsProvider.notifier).setDefaultHeaders(
      <String, String>{
        for (final KeyValueRow r in rows.active) r.key: r.value,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return PageScaffold(
      title: 'Default headers',
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: Space.lg),
          child: Text(
            'Added to every request, unless the request sets the same name '
            'itself.',
            style: AppType.note.copyWith(color: c.onSurfaceVariant),
          ),
        ),
        KeyValueEditor(
          rows: _rows,
          addLabel: 'Add header',
          emptyNote: 'Nothing is added to your requests at the moment.',
          reorderable: false,
          onChanged: _save,
        ),
      ],
    );
  }
}
