import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/http/request_builder.dart';
import '../../core/http/variable_resolver.dart';
import '../../core/models/api_request.dart';
import '../../core/models/environment.dart';
import '../../core/providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_menu.dart';
import '../../core/widgets/chips.dart';

/// The chip that opens the switcher. 40dp, `surfaceContainer`, the environment's
/// own tile on the left.
class EnvironmentChip extends ConsumerWidget {
  const EnvironmentChip({required this.request, super.key});

  /// The request whose variables the menu counts.
  final ApiRequest? request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors c = context.colors;
    final Environment? active = ref.watch(activeEnvironmentProvider);
    return Builder(
      builder: (BuildContext anchor) => Semantics(
        button: true,
        label: 'Environment, ${active?.name ?? 'none'}',
        child: Material(
          color: c.surfaceContainer,
          shape: StadiumBorder(side: BorderSide(color: c.outline)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _open(anchor, ref),
            child: Container(
              height: 40,
              padding: const EdgeInsets.only(left: 6, right: Space.row),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: Space.sm,
                children: <Widget>[
                  if (active == null)
                    const EnvTile.none()
                  else
                    EnvTile(icon: active.icon.glyph, colourIndex: active.colour),
                  // The label swaps on `lensSwap`, and the variable highlights
                  // re-resolve in the same frame because both read the one
                  // active-environment provider. It is flexible because a long
                  // environment name must not push the top bar's actions off
                  // the edge on a narrow screen.
                  Flexible(
                    child: AnimatedSize(
                      duration: Motion.of(context, Motion.lensSwap),
                      curve: Motion.curveOf(context, Motion.spring),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        active?.name ?? 'No environment',
                        key: ValueKey<String>(active?.id ?? 'none'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.titleMedium.copyWith(color: c.onSurface),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    size: IconSpec.small,
                    color: c.iconMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext anchor, WidgetRef ref) async {
    final List<Environment> all = ref.read(environmentsProvider).value ??
        const <Environment>[];
    final String? activeId = ref.read(activeEnvironmentProvider)?.id;
    // The names this request refers to, so each row can say how many of them
    // it would resolve. Seeing what is missing before switching is the point.
    final List<String> names = request == null
        ? const <String>[]
        : <String>{
            for (final String template in RequestBuilder.templateStrings(request!))
              ...VariableResolver.namesIn(template),
          }.toList(growable: false);

    final String? choice = await showAppMenu<String>(
      context: anchor,
      width: 280,
      entries: <AppMenuEntry<String>>[
        for (final Environment env in all)
          AppMenuEntry<String>(
            value: env.id,
            label: env.name,
            note: names.isEmpty
                ? env.summary
                : '${VariableResolver.resolvedCount(names, env)} / ${names.length} resolved'
                    '${_missingNote(names, env)}',
            leading: EnvTile(
              icon: env.icon.glyph,
              colourIndex: env.colour,
              size: 24,
            ),
            selected: env.id == activeId,
          ),
        AppMenuEntry<String>(
          value: '',
          label: 'No environment',
          icon: Icons.public_off_rounded,
          selected: activeId == null,
        ),
        const AppMenuEntry<String>.divider(),
        const AppMenuEntry<String>(
          value: 'manage',
          label: 'Manage environments',
          icon: Icons.tune_rounded,
        ),
      ],
    );
    if (choice == null) return;
    if (choice == 'manage') {
      if (anchor.mounted) unawaited(anchor.push<void>(Routes.environments));
      return;
    }
    await ref
        .read(environmentsRepositoryProvider)
        .setActiveId(choice.isEmpty ? null : choice);
  }

  /// Names the first thing missing, which is more use than a bare count.
  static String _missingNote(List<String> names, Environment env) {
    final List<String> missing = <String>[
      for (final String n in names) if (env.lookup(n) == null) n,
    ];
    if (missing.isEmpty) return '';
    return ' · ${missing.first} missing';
  }
}
