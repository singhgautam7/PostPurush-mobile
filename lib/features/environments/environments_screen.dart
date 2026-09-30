import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/environment.dart';
import '../../core/providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/util/ids.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_icon_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/states.dart';

/// Board 4.1. Tap the radio to make one active, tap the row to open its
/// variables. Swipe a row to delete it, with an undo strip.
class EnvironmentsScreen extends ConsumerWidget {
  const EnvironmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors c = context.colors;
    final AsyncValue<List<Environment>> environments = ref.watch(
      environmentsProvider,
    );
    final String? activeId = ref.watch(activeEnvironmentProvider)?.id;
    final List<Environment> list = environments.value ?? const <Environment>[];

    if (!environments.isLoading && list.isEmpty) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppHeader(
                title: 'Environments',
                onBack: () => context.pop(),
              ),
              Expanded(
                child: EmptyState(
                  icon: Icons.public_rounded,
                  title: 'No environments',
                  message:
                      'An environment is a set of variables for one stage of '
                      'your work. The active one fills them in across every '
                      'request.',
                  primaryLabel: 'New environment',
                  primaryIcon: Icons.add_rounded,
                  onPrimary: () => context.push(Routes.newEnvironment),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PageScaffold(
      title: 'Environments',
      actions: <Widget>[
        AppIconButton(
          icon: Icons.add_rounded,
          onPressed: () => context.push(Routes.newEnvironment),
          semanticLabel: 'New environment',
        ),
      ],
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: Space.lg),
          child: Text(
            'Sets of variables for each stage of your work. The active one '
            'fills in variables across every request.',
            style: AppType.note.copyWith(color: c.onSurfaceVariant),
          ),
        ),
        if (environments.isLoading && list.isEmpty)
          const Delayed(
            child: RowGroup(children: <Widget>[SkeletonRow(), SkeletonRow()]),
          )
        else
          RowGroup(
            children: <Widget>[
              for (final Environment env in list)
                Dismissible(
                  key: ValueKey<String>('env-${env.id}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _delete(context, ref, env),
                  background: Container(
                    color: c.dangerContainer,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: Space.xl),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: <Widget>[
                        Icon(
                          Icons.delete_outline_rounded,
                          size: IconSpec.size,
                          color: c.onDangerContainer,
                        ),
                        Text(
                          'Delete',
                          style: AppType.titleMedium.copyWith(
                            color: c.onDangerContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: AppRow(
                    title: env.name,
                    subtitle: env.summary,
                    minHeight: 64,
                    leading: EnvTile(
                      icon: env.icon.glyph,
                      colourIndex: env.colour,
                      size: 36,
                      radius: Radii.thumb,
                    ),
                    titleTrailing: env.id == activeId
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: c.primaryContainer,
                              borderRadius: Radii.chipR,
                            ),
                            child: Text(
                              'ACTIVE',
                              style: AppType.sectionHeader.copyWith(
                                color: c.onPrimaryContainer,
                              ),
                            ),
                          )
                        : null,
                    trailing: AppIconButton(
                      icon: env.id == activeId
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      onPressed: () => ref
                          .read(environmentsRepositoryProvider)
                          .setActiveId(env.id == activeId ? null : env.id),
                      semanticLabel: env.id == activeId
                          ? 'Deactivate ${env.name}'
                          : 'Make ${env.name} active',
                      filled: false,
                      tint: env.id == activeId ? c.primary : c.iconMuted,
                    ),
                    onTap: () => context.push(Routes.environment(env.id)),
                    onLongPress: () => _duplicate(context, ref, env, list.length),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Environment env,
  ) async {
    await ref.read(environmentsRepositoryProvider).delete(env.id);
    if (!context.mounted) return;
    AppSnackbar.undo(
      context,
      message: '${env.name} deleted',
      onUndo: () => ref.read(environmentsRepositoryProvider).save(env),
    );
  }

  Future<void> _duplicate(
    BuildContext context,
    WidgetRef ref,
    Environment env,
    int order,
  ) async {
    await ref.read(environmentsRepositoryProvider).save(
      env.copyWith(id: newId(), name: '${env.name} copy', order: order),
    );
    if (context.mounted) AppSnackbar.info(context, '${env.name} duplicated');
  }
}
