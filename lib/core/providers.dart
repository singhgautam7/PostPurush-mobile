import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/settings_controller.dart';
import 'db/app_db.dart';
import 'db/app_state_repository.dart';
import 'db/collections_repository.dart';
import 'db/environments_repository.dart';
import 'db/history_repository.dart';
import 'http/api_client.dart';
import 'http/load_tester.dart';
import 'models/api_request.dart';
import 'models/environment.dart';
import 'models/folder.dart';
import 'models/history_entry.dart';

/// Overridden in `main` with the instance opened during bootstrap.
final Provider<AppDatabase> databaseProvider = Provider<AppDatabase>(
  (Ref ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

final Provider<CollectionsRepository> collectionsRepositoryProvider =
    Provider<CollectionsRepository>(
      (Ref ref) => CollectionsRepository(ref.watch(databaseProvider)),
    );

final Provider<EnvironmentsRepository> environmentsRepositoryProvider =
    Provider<EnvironmentsRepository>(
      (Ref ref) => EnvironmentsRepository(ref.watch(databaseProvider)),
    );

final Provider<HistoryRepository> historyRepositoryProvider =
    Provider<HistoryRepository>(
      (Ref ref) => HistoryRepository(ref.watch(databaseProvider)),
    );

final Provider<AppStateRepository> appStateRepositoryProvider =
    Provider<AppStateRepository>(
      (Ref ref) => AppStateRepository(ref.watch(databaseProvider)),
    );

/// The one HTTP client. Reconfigured, never rebuilt, when a send setting
/// changes, so a keep-alive connection survives a visit to Settings.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((Ref ref) {
  final ApiClient client = ApiClient()
    ..configure(ref.read(settingsProvider).sendOptions);
  ref.listen<AppSettings>(
    settingsProvider,
    (AppSettings? previous, AppSettings next) =>
        client.configure(next.sendOptions),
  );
  ref.onDispose(client.close);
  return client;
});

final Provider<LoadTester> loadTesterProvider = Provider<LoadTester>(
  (Ref ref) => LoadTester(ref.watch(apiClientProvider)),
);

final StreamProvider<List<Folder>> foldersProvider =
    StreamProvider<List<Folder>>(
      (Ref ref) => ref.watch(collectionsRepositoryProvider).watchFolders(),
    );

final StreamProvider<List<ApiRequest>> requestsProvider =
    StreamProvider<List<ApiRequest>>(
      (Ref ref) => ref.watch(collectionsRepositoryProvider).watchRequests(),
    );

final StreamProvider<List<Environment>> environmentsProvider =
    StreamProvider<List<Environment>>(
      (Ref ref) => ref.watch(environmentsRepositoryProvider).watchAll(),
    );

final StreamProvider<String?> activeEnvironmentIdProvider =
    StreamProvider<String?>(
      (Ref ref) => ref.watch(environmentsRepositoryProvider).watchActiveId(),
    );

/// The environment variables are resolved from, or null for "No environment".
///
/// Everything that resolves a variable selects on this one provider, so a
/// switch re-resolves the URL bar, the headers and the code sheet in the same
/// frame.
final Provider<Environment?> activeEnvironmentProvider = Provider<Environment?>(
  (Ref ref) {
    final String? id = ref.watch(activeEnvironmentIdProvider).value;
    if (id == null) return null;
    final List<Environment> all = ref.watch(environmentsProvider).value ??
        const <Environment>[];
    for (final Environment env in all) {
      if (env.id == id) return env;
    }
    return null;
  },
);

final StreamProvider<List<HistoryEntry>> historyProvider =
    StreamProvider<List<HistoryEntry>>(
      (Ref ref) => ref.watch(historyRepositoryProvider).watchRecent(),
    );
