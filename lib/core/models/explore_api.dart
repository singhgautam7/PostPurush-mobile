import 'package:freezed_annotation/freezed_annotation.dart';

import 'http_method.dart';

part 'explore_api.freezed.dart';
part 'explore_api.g.dart';

/// What an API asks of you before it answers. The board prints these as plain
/// text next to HTTPS, never as a coloured badge alone.
enum ApiAuth {
  none('No auth', 'no auth'),
  apiKey('API key', 'api key'),
  oauth('OAuth', 'oauth'),
  other('Other', 'other');

  const ApiAuth(this.filterLabel, this.rowLabel);

  /// On the filter chip.
  final String filterLabel;

  /// In a row's metadata line.
  final String rowLabel;

  static ApiAuth parse(String? value) {
    final String v = (value ?? '').trim().toLowerCase();
    if (v.isEmpty || v == 'no' || v == 'none') return ApiAuth.none;
    if (v.contains('oauth')) return ApiAuth.oauth;
    if (v.contains('key')) return ApiAuth.apiKey;
    return ApiAuth.other;
  }
}

/// One sample endpoint, so "Open as request" has something to open.
@freezed
abstract class ApiSample with _$ApiSample {
  const factory ApiSample({
    @Default(HttpMethod.get) HttpMethod method,
    @Default('') String path,
    @Default('') String description,
  }) = _ApiSample;

  factory ApiSample.fromJson(Map<String, dynamic> json) =>
      _$ApiSampleFromJson(json);
}

/// A row of the bundled public-APIs catalogue. Read-only: the asset is built
/// by hand as `assets/data/explore_apis.json` and shipped, so Explore works
/// offline and costs nothing at runtime beyond one decode.
@freezed
abstract class ExploreApi with _$ExploreApi {
  const factory ExploreApi({
    required String name,
    @Default('') String description,
    @Default('') String category,
    @Default(ApiAuth.none) ApiAuth auth,
    @Default(true) bool https,
    @Default('') String baseUrl,
    @Default('') String docsUrl,
    @Default(<ApiSample>[]) List<ApiSample> samples,
  }) = _ExploreApi;

  factory ExploreApi.fromJson(Map<String, dynamic> json) =>
      _$ExploreApiFromJson(json);
}

extension ExploreApiX on ExploreApi {
  /// "Ready to call" on the board: nothing stands between opening it and
  /// getting an answer.
  bool get readyToCall => auth == ApiAuth.none;

  /// "no auth · https · api.open-meteo.com", as a row prints it.
  String get metaLine => <String>[
    auth.rowLabel,
    if (https) 'https',
    if (host.isNotEmpty) host,
  ].join(' · ');

  String get host => Uri.tryParse(
    baseUrl.startsWith('http') ? baseUrl : 'https://$baseUrl',
  )?.host ??
      baseUrl;

  /// What a search types against.
  bool matches(String query) {
    if (query.isEmpty) return true;
    final String q = query.toLowerCase();
    return name.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q) ||
        host.toLowerCase().contains(q);
  }
}

/// One category in the browse list, with the counts the board shows live.
class ExploreCategory {
  const ExploreCategory({
    required this.name,
    required this.total,
    required this.noAuth,
  });

  final String name;
  final int total;
  final int noAuth;

  /// "28 · 19 no auth".
  String get summary => '$total · $noAuth no auth';
}
