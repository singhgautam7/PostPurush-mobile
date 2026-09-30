/// Every route in one place, so a push is never a typed string literal.
abstract final class Routes {
  /// The first launch's three-step flow, shown once.
  static const String welcome = '/welcome';

  // The four destinations.
  static const String collections = '/collections';
  static const String explore = '/explore';
  static const String search = '/search';
  static const String more = '/more';

  /// Inside the Collections branch, so opening a request keeps Collections
  /// active and the nav pill stays (board 00).
  static const String workspace = '/collections/workspace';

  /// Inside the Explore branch, which keeps its nav too.
  static String exploreCategory(String name) =>
      '/explore/category/${Uri.encodeComponent(name)}';

  /// A pushed page: the nav leaves and the primary action floats where it was.
  static String exploreApi(String name) =>
      '/explore/api/${Uri.encodeComponent(name)}';

  // Pushed pages, all outside the shell, so none of them keeps the nav.
  static const String environments = '/environments';
  static const String newEnvironment = '/environments/new';
  static String environment(String id) => '/environments/$id';
  static String editEnvironment(String id) => '/environments/$id/edit';

  static const String history = '/history';
  static const String analytics = '/analytics';
  static const String testing = '/testing';
  static const String apiDocs = '/docs';
  static String apiDoc(String folderId) => '/docs/$folderId';

  static const String settings = '/settings';
  static const String theme = '/settings/theme';
  static const String defaultHeaders = '/settings/headers';
  static const String about = '/about';
  static const String privacy = '/privacy';
}
