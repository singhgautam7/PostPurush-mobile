import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/collections_repository.dart';
import '../../core/models/api_request.dart';
import '../../core/models/folder.dart';
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
import '../../core/widgets/states.dart';

/// Board 12.1. Nothing is picked yet, so the page asks for a collection and
/// lists them right below.
class ApiDocsScreen extends ConsumerWidget {
  const ApiDocsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors c = context.colors;
    final List<Folder> folders = ref.watch(foldersProvider).value ??
        const <Folder>[];
    final List<ApiRequest> requests = ref.watch(requestsProvider).value ??
        const <ApiRequest>[];
    final List<Folder> top = <Folder>[
      for (final Folder f in folders) if (f.parentId == null) f,
    ];

    if (top.isEmpty) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppHeader(title: 'API docs', onBack: () => context.pop()),
              const Expanded(
                child: EmptyState(
                  icon: Icons.description_outlined,
                  title: 'No collections',
                  message:
                      'Docs are generated from a collection, so make one and '
                      'save a few requests into it first.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PageScaffold(
      title: 'API docs',
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(Space.screen),
          decoration: BoxDecoration(
            color: c.surfaceContainer,
            borderRadius: Radii.cardR,
            border: Border.all(color: c.outline),
          ),
          child: Row(
            spacing: Space.md,
            children: <Widget>[
              Icon(
                Icons.description_outlined,
                size: 32,
                color: c.iconMuted,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Space.xs,
                  children: <Widget>[
                    Text(
                      'Pick a collection to generate docs.',
                      style: AppType.titleMedium.copyWith(color: c.onSurface),
                    ),
                    Text(
                      "Built from each request's description, parameters and "
                      'last response.',
                      style: AppType.bodyMedium.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.section),
        SectionHeader(label: 'Collections · ${top.length}'),
        const SizedBox(height: Space.row),
        RowGroup(
          children: <Widget>[
            for (final Folder folder in top)
              AppRow(
                title: folder.name,
                subtitle: Fmt.count(
                  CollectionsRepository.countIn(folder.id, folders, requests),
                  'request',
                ),
                minHeight: 60,
                leading: Icon(
                  Icons.folder_rounded,
                  size: IconSpec.size,
                  color: c.iconMuted,
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: IconSpec.size,
                  color: c.iconMuted,
                ),
                onTap: () => context.push(Routes.apiDoc(folder.id)),
              ),
          ],
        ),
      ],
    );
  }
}
