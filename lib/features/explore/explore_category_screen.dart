import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/explore_api.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/states.dart';
import 'explore_repository.dart';
import 'explore_screen.dart';

/// Board 3.2. The same filters as the browse list, with the count in the
/// subtitle, so the two never disagree about what is showing.
class ExploreCategoryScreen extends ConsumerWidget {
  const ExploreCategoryScreen({required this.category, super.key});

  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ExploreApi> all =
        ref.watch(exploreApisProvider).value ?? const <ExploreApi>[];
    final ExploreFilters filters = ref.watch(exploreFiltersProvider);
    final List<ExploreApi> inCategory = <ExploreApi>[
      for (final ExploreApi api in all)
        if (api.category == category) api,
    ];
    final List<ExploreApi> matching = <ExploreApi>[
      for (final ExploreApi api in inCategory)
        if (filters.accepts(api)) api,
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppHeader(
              title: category,
              subtitle: filters.any
                  ? '${matching.length} of ${inCategory.length} match filters'
                  : '${inCategory.length} '
                        '${inCategory.length == 1 ? 'API' : 'APIs'}',
              onBack: () => context.pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                Space.xs,
                Space.screen,
                Space.md,
              ),
              child: _CategoryFilters(),
            ),
            Expanded(
              child: matching.isEmpty
                  ? EmptyState(
                      icon: Icons.filter_alt_off_rounded,
                      title: 'Nothing here',
                      message:
                          'No API in $category matches the filters you have on.',
                      primaryLabel: 'Clear filters',
                      primaryIcon: Icons.close_rounded,
                      onPrimary: () =>
                          ref.read(exploreFiltersProvider.notifier).clear(),
                      topPadding: 40,
                    )
                  : CustomScrollView(
                      slivers: <Widget>[
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.screen,
                          ),
                          sliver: SliverRowGroup(
                            itemCount: matching.length,
                            itemBuilder: (BuildContext context, int i) =>
                                ApiRow(api: matching[i]),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: Space.bottomSafe),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilters extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ExploreFilters filters = ref.watch(exploreFiltersProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: Space.sm,
        children: <Widget>[
          PillChip(
            label: 'HTTPS',
            selected: filters.httpsOnly,
            showCheck: true,
            onTap: () =>
                ref.read(exploreFiltersProvider.notifier).toggleHttps(),
          ),
          PillChip(
            label: 'No auth',
            selected: filters.auths.contains(ApiAuth.none),
            showCheck: true,
            onTap: () => ref
                .read(exploreFiltersProvider.notifier)
                .toggleAuth(ApiAuth.none),
          ),
          if (filters.httpsOnly || filters.auths.isNotEmpty)
            PillChip(
              label: 'Clear',
              icon: Icons.close_rounded,
              onTap: () => ref.read(exploreFiltersProvider.notifier).clear(),
            ),
        ],
      ),
    );
  }
}
