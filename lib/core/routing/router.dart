import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/nav_shell.dart';
import '../../app/transitions.dart';
import '../../features/workspace/workspace_controller.dart';
import '../../features/about/about_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/api_docs/api_docs_screen.dart';
import '../../features/api_docs/doc_view_screen.dart';
import '../../features/collections/collections_screen.dart';
import '../../features/environments/environment_editor_screen.dart';
import '../../features/environments/environments_screen.dart';
import '../../features/environments/variables_screen.dart';
import '../../features/explore/explore_api_screen.dart';
import '../../features/explore/explore_category_screen.dart';
import '../../features/explore/explore_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/theme_screen.dart';
import '../../features/testing/testing_screen.dart';
import '../../features/welcome/welcome_screen.dart';
import '../../features/workspace/workspace_screen.dart';
import 'routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// The navigation map.
///
/// Two kinds of route, and the difference is the nav pill. The workspace and the
/// Explore category sit *inside* their branch, so the pill stays and the tab
/// stays lit. Everything else is a top-level push, where the pill leaves and a
/// primary action floats where it was, which is what the board draws.
GoRouter buildRouter({required bool onboarded}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: onboarded ? Routes.collections : Routes.welcome,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.welcome,
        builder: (BuildContext c, GoRouterState s) => const WelcomeScreen(),
      ),
      GoRoute(
        path: Routes.environments,
        pageBuilder: (BuildContext c, GoRouterState s) =>
            appPage<void>(state: s, child: const EnvironmentsScreen()),
        routes: <RouteBase>[
          GoRoute(
            path: 'new',
            pageBuilder: (BuildContext c, GoRouterState s) =>
                appPage<void>(state: s, child: const EnvironmentEditorScreen()),
          ),
          GoRoute(
            path: ':id',
            pageBuilder: (BuildContext c, GoRouterState s) => appPage<void>(
              state: s,
              child: VariablesScreen(
                environmentId: s.pathParameters['id']!,
              ),
            ),
            routes: <RouteBase>[
              GoRoute(
                path: 'edit',
                pageBuilder: (BuildContext c, GoRouterState s) => appPage<void>(
                  state: s,
                  child: EditEnvironmentLoader(id: s.pathParameters['id']!),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.history,
        pageBuilder: (BuildContext c, GoRouterState s) =>
            appPage<void>(state: s, child: const HistoryScreen()),
      ),
      GoRoute(
        path: Routes.analytics,
        pageBuilder: (BuildContext c, GoRouterState s) =>
            appPage<void>(state: s, child: const AnalyticsScreen()),
      ),
      GoRoute(
        path: Routes.testing,
        pageBuilder: (BuildContext c, GoRouterState s) =>
            appPage<void>(state: s, child: const TestingScreen()),
      ),
      GoRoute(
        path: Routes.apiDocs,
        pageBuilder: (BuildContext c, GoRouterState s) =>
            appPage<void>(state: s, child: const ApiDocsScreen()),
        routes: <RouteBase>[
          GoRoute(
            path: ':folderId',
            pageBuilder: (BuildContext c, GoRouterState s) => appPage<void>(
              state: s,
              child: DocViewScreen(folderId: s.pathParameters['folderId']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.settings,
        pageBuilder: (BuildContext c, GoRouterState s) =>
            appPage<void>(state: s, child: const SettingsScreen()),
        routes: <RouteBase>[
          GoRoute(
            path: 'theme',
            pageBuilder: (BuildContext c, GoRouterState s) =>
                appPage<void>(state: s, child: const ThemeScreen()),
          ),
          GoRoute(
            path: 'headers',
            pageBuilder: (BuildContext c, GoRouterState s) =>
                appPage<void>(state: s, child: const DefaultHeadersScreen()),
          ),
        ],
      ),
      GoRoute(
        path: Routes.about,
        pageBuilder: (BuildContext c, GoRouterState s) =>
            appPage<void>(state: s, child: const AboutScreen()),
      ),
      GoRoute(
        path: Routes.privacy,
        pageBuilder: (BuildContext c, GoRouterState s) =>
            appPage<void>(state: s, child: const PrivacyScreen()),
      ),
      GoRoute(
        path: Routes.permissions,
        pageBuilder: (BuildContext c, GoRouterState s) =>
            appPage<void>(state: s, child: const PermissionsScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell shell,
            ) => Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? _) =>
                  NavShell(
                    index: shell.currentIndex,
                    tabCount: shell.route.branches.length,
                    onSelect: (int i) => shell.goBranch(
                      i,
                      initialLocation: i == shell.currentIndex,
                    ),
                    // New request is the app's one primary action, so it
                    // stands on every destination rather than only on Folders.
                    // The workspace opens on the root navigator, so composing
                    // from Explore comes back to Explore.
                    onAdd: () {
                      ref.read(workspaceProvider.notifier).openBlank();
                      context.push(Routes.workspace);
                    },
                    onAddLongPress: () => quickActions(context, ref),
                    child: shell,
                  ),
            ),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.collections,
                builder: (BuildContext c, GoRouterState s) =>
                    const CollectionsScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'workspace',
                    // Root, not this branch: the button that opens it stands
                    // on every destination, and a page pushed onto branch 0
                    // from another branch is pushed where nobody can see it.
                    parentNavigatorKey: rootNavigatorKey,
                    pageBuilder: (BuildContext c, GoRouterState s) =>
                        appPage<void>(state: s, child: const WorkspaceScreen()),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.explore,
                builder: (BuildContext c, GoRouterState s) =>
                    const ExploreScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'category/:name',
                    pageBuilder: (BuildContext c, GoRouterState s) =>
                        appPage<void>(
                          state: s,
                          child: ExploreCategoryScreen(
                            category: Uri.decodeComponent(
                              s.pathParameters['name']!,
                            ),
                          ),
                        ),
                  ),
                  GoRoute(
                    path: 'api/:name',
                    parentNavigatorKey: rootNavigatorKey,
                    pageBuilder: (BuildContext c, GoRouterState s) =>
                        appPage<void>(
                          state: s,
                          child: ExploreApiScreen(
                            name: Uri.decodeComponent(
                              s.pathParameters['name']!,
                            ),
                          ),
                        ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.search,
                builder: (BuildContext c, GoRouterState s) =>
                    const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.more,
                builder: (BuildContext c, GoRouterState s) =>
                    const MoreScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
