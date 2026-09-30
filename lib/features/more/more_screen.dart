import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/environment.dart';
import '../../core/models/folder.dart';
import '../../core/models/history_entry.dart';
import '../../core/providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/util/format.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/section_header.dart';
import '../settings/settings_controller.dart';

/// Board 6. General holds the tools that are not tabs; Settings and About
/// follow. Each row answers its own question in mono on the right, so most of
/// them never need opening.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors c = context.colors;
    final AppSettings settings = ref.watch(settingsProvider);
    final List<Environment> environments = ref.watch(environmentsProvider).value ??
        const <Environment>[];
    final Environment? active = ref.watch(activeEnvironmentProvider);
    final List<HistoryEntry> history = ref.watch(historyProvider).value ??
        const <HistoryEntry>[];
    final List<Folder> folders = ref.watch(foldersProvider).value ??
        const <Folder>[];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CollapseOnScroll(
          builder: (BuildContext context, bool collapsed) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppHeader(title: 'More', collapsed: collapsed),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    Space.screen,
                    Space.md,
                    Space.screen,
                    Space.bottomSafe,
                  ),
                  children: <Widget>[
                    const SectionHeader(label: 'General'),
                    const SizedBox(height: Space.row),
                    RowGroup(
                      children: <Widget>[
                        _Row(
                          icon: Icons.public_rounded,
                          label: 'Environments',
                          value: environments.isEmpty
                              ? 'none yet'
                              : '${environments.length} · '
                                  '${active?.name ?? 'none active'}',
                          onTap: () => context.push(Routes.environments),
                        ),
                        _Row(
                          icon: Icons.bar_chart_rounded,
                          label: 'Analytics',
                          value: history.isEmpty
                              ? 'no history yet'
                              : '${Fmt.thousands(history.length)} sent',
                          onTap: () => context.push(Routes.analytics),
                        ),
                        _Row(
                          icon: Icons.science_outlined,
                          label: 'Testing',
                          value: 'assertions · load',
                          onTap: () => context.push(Routes.testing),
                        ),
                        _Row(
                          icon: Icons.description_outlined,
                          label: 'API docs',
                          value: folders.isEmpty
                              ? 'no collections'
                              : Fmt.count(
                                  folders
                                      .where((Folder f) => f.parentId == null)
                                      .length,
                                  'collection',
                                ),
                          onTap: () => context.push(Routes.apiDocs),
                        ),
                        _Row(
                          icon: Icons.history_rounded,
                          label: 'History',
                          value: history.isEmpty
                              ? 'nothing yet'
                              : '${history.length} · '
                                  '${settings.historyDays} days',
                          onTap: () => context.push(Routes.history),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.section),
                    const SectionHeader(label: 'App'),
                    const SizedBox(height: Space.row),
                    RowGroup(
                      children: <Widget>[
                        _Row(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          value: _themeSummary(settings),
                          onTap: () => context.push(Routes.settings),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.section),
                    const SectionHeader(label: 'About PostPurush'),
                    const SizedBox(height: Space.row),
                    RowGroup(
                      children: <Widget>[
                        _Row(
                          icon: Icons.shield_outlined,
                          label: 'Privacy',
                          value: 'On device only',
                          onTap: () => context.push(Routes.privacy),
                        ),
                        _Row(
                          icon: Icons.info_outline_rounded,
                          label: 'About',
                          value: 'v${AboutInfo.version}',
                          onTap: () => context.push(Routes.about),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.xl),
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
                            'No account, no sync. Your data stays on this '
                            'device.',
                            style: AppType.bodySmall.copyWith(
                              color: c.onSurfaceMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _themeSummary(AppSettings s) {
    final String colour = s.dynamicColor ? 'Wallpaper' : s.family.name;
    final String mode = switch (s.themeMode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };
    return '$colour · $mode';
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return AppRow(
      title: label,
      count: value,
      leading: Icon(icon, size: IconSpec.small, color: c.icon),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: IconSpec.small,
        color: c.onSurfaceMuted,
      ),
      onTap: onTap,
    );
  }
}

/// The one place the version lives, so About and More agree.
abstract final class AboutInfo {
  static const String version = '1.0.0';
  static const String build = '100';
  static const String repository = 'https://github.com/grs/postpurush';
}
