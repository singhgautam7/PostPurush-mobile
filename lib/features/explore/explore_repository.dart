import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/api_request.dart';
import '../../core/models/explore_api.dart';
import '../../core/models/http_method.dart';
import '../../core/models/key_value.dart';
import '../../core/util/ids.dart';

/// The bundled catalogue. Read once from the asset, decoded off the main
/// isolate, and cached for the life of the app.
class ExploreRepository {
  const ExploreRepository();

  static const String asset = 'assets/data/explore_apis.json';

  Future<List<ExploreApi>> load() async {
    final String raw = await rootBundle.loadString(asset);
    // A 40 KB decode is not free on a slow device, and it happens while the
    // Explore tab is animating in, so it goes to a worker isolate.
    return compute(_decode, raw);
  }

  static List<ExploreApi> _decode(String raw) {
    final Object? root = jsonDecode(raw);
    if (root is! Map<String, dynamic>) return const <ExploreApi>[];
    final Object? apis = root['apis'];
    if (apis is! List<Object?>) return const <ExploreApi>[];
    final List<ExploreApi> out = <ExploreApi>[];
    for (final Object? entry in apis) {
      if (entry is! Map<String, dynamic>) continue;
      try {
        out.add(ExploreApi.fromJson(entry));
      } catch (error) {
        // A bad row in a shipped asset is a build problem, not a crash.
        debugPrint('Skipped an Explore entry: $error');
      }
    }
    out.sort((ExploreApi a, ExploreApi b) => a.name.compareTo(b.name));
    return out;
  }
}

final Provider<ExploreRepository> exploreRepositoryProvider =
    Provider<ExploreRepository>((Ref ref) => const ExploreRepository());

final FutureProvider<List<ExploreApi>> exploreApisProvider =
    FutureProvider<List<ExploreApi>>(
      (Ref ref) => ref.watch(exploreRepositoryProvider).load(),
    );

/// The categories with their live counts, which is what the browse list draws.
final Provider<List<ExploreCategory>> exploreCategoriesProvider =
    Provider<List<ExploreCategory>>((Ref ref) {
      final List<ExploreApi> apis = ref.watch(exploreApisProvider).value ??
          const <ExploreApi>[];
      final Map<String, List<ExploreApi>> grouped = <String, List<ExploreApi>>{};
      for (final ExploreApi api in apis) {
        grouped.putIfAbsent(api.category, () => <ExploreApi>[]).add(api);
      }
      final List<ExploreCategory> out = <ExploreCategory>[
        for (final MapEntry<String, List<ExploreApi>> e in grouped.entries)
          ExploreCategory(
            name: e.key,
            total: e.value.length,
            noAuth: e.value.where((ExploreApi a) => a.readyToCall).length,
          ),
      ]..sort((ExploreCategory a, ExploreCategory b) => a.name.compareTo(b.name));
      return out;
    });

/// The filters on the Explore tab, shared by browse, a category and search, so
/// the counts on all three agree.
@immutable
class ExploreFilters {
  const ExploreFilters({
    this.httpsOnly = false,
    this.auths = const <ApiAuth>{},
    this.query = '',
  });

  final bool httpsOnly;

  /// Empty means every kind of auth.
  final Set<ApiAuth> auths;
  final String query;

  bool get any => httpsOnly || auths.isNotEmpty || query.isNotEmpty;

  ExploreFilters copyWith({
    bool? httpsOnly,
    Set<ApiAuth>? auths,
    String? query,
  }) => ExploreFilters(
    httpsOnly: httpsOnly ?? this.httpsOnly,
    auths: auths ?? this.auths,
    query: query ?? this.query,
  );

  bool accepts(ExploreApi api) {
    if (httpsOnly && !api.https) return false;
    if (auths.isNotEmpty && !auths.contains(api.auth)) return false;
    return api.matches(query);
  }

  /// The same test with one filter dropped, so "3 APIs match without that
  /// filter" can be true rather than a guess.
  ExploreFilters without({bool? https, ApiAuth? auth, bool query = false}) =>
      ExploreFilters(
        httpsOnly: https == true ? false : httpsOnly,
        auths: auth == null
            ? auths
            : <ApiAuth>{...auths}..remove(auth),
        query: query ? '' : this.query,
      );
}

class ExploreFiltersController extends Notifier<ExploreFilters> {
  @override
  ExploreFilters build() => const ExploreFilters();

  void toggleHttps() => state = state.copyWith(httpsOnly: !state.httpsOnly);

  void toggleAuth(ApiAuth auth) {
    final Set<ApiAuth> next = <ApiAuth>{...state.auths};
    next.contains(auth) ? next.remove(auth) : next.add(auth);
    state = state.copyWith(auths: next);
  }

  void setQuery(String query) => state = state.copyWith(query: query);

  void clear() => state = const ExploreFilters();

  /// Replaces the whole set, which is how "show these without that filter"
  /// drops one without the caller reaching into `state`.
  void replace(ExploreFilters filters) => state = filters;
}

final NotifierProvider<ExploreFiltersController, ExploreFilters>
    exploreFiltersProvider =
        NotifierProvider<ExploreFiltersController, ExploreFilters>(
          ExploreFiltersController.new,
        );

/// Turns a catalogue entry into an unsaved request, ready for the workspace.
///
/// The sample path is joined to the base URL rather than concatenated, so a
/// base that already ends in a slash and a path that starts with one do not
/// produce a double.
ApiRequest requestFrom(ExploreApi api, {ApiSample? sample}) {
  final ApiSample chosen = sample ??
      (api.samples.isEmpty ? const ApiSample() : api.samples.first);
  final String base = api.baseUrl.startsWith('http')
      ? api.baseUrl
      : 'https://${api.baseUrl}';
  final String path = chosen.path;
  final String url = path.isEmpty
      ? base
      : '${base.endsWith('/') ? base.substring(0, base.length - 1) : base}'
          '${path.startsWith('/') ? '' : '/'}$path';
  final DateTime now = DateTime.now();
  return ApiRequest(
    id: newId(),
    name: chosen.description.isEmpty ? api.name : chosen.description,
    description: api.description,
    method: chosen.method,
    url: url,
    // A sample endpoint usually carries a query, and the Params tab claims to
    // show what the URL holds, so it has to start out agreeing with it.
    params: _paramsOf(url),
    bodyType: chosen.method.sendsBody ? BodyType.json : BodyType.none,
    createdAt: now,
    updatedAt: now,
  );
}

List<KeyValueRow> _paramsOf(String url) {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null || uri.queryParameters.isEmpty) return const <KeyValueRow>[];
  return <KeyValueRow>[
    for (final MapEntry<String, String> e in uri.queryParameters.entries)
      KeyValueRow(id: newId(), key: e.key, value: e.value),
  ];
}
