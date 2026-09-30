/// The ten methods on the board's method sheet (2.9), in its order.
///
/// Each carries its own hue off the category wheel, so a method reads the same
/// colour in a list, in the URL bar, in history and in the docs. TRACE and
/// CONNECT are neutral because they are rarely sent from a client; QUERY takes
/// the one free hue, 110.
enum HttpMethod {
  get('GET', 150, 'Read a resource'),
  post('POST', 265, 'Create, or send data'),
  put('PUT', 55, 'Replace a resource'),
  patch('PATCH', 300, 'Change part of a resource'),
  delete('DELETE', 25, 'Remove a resource'),
  head('HEAD', 200, 'Headers only, no body'),
  options('OPTIONS', 340, 'What the server allows'),
  query('QUERY', 110, 'Safe read with a body'),
  trace('TRACE', null, 'Echo the request back'),
  connect('CONNECT', null, 'Open a tunnel');

  const HttpMethod(this.label, this.hue, this.blurb);

  /// The wire name, which is also what the chip prints.
  final String label;

  /// The category hue, or null for a neutral chip.
  final double? hue;

  /// The one-line explanation on the method sheet.
  final String blurb;

  /// The five everyday methods, which come first on the sheet.
  static const List<HttpMethod> common = <HttpMethod>[
    get,
    post,
    put,
    patch,
    delete,
  ];

  static const List<HttpMethod> lessCommon = <HttpMethod>[
    head,
    options,
    query,
    trace,
    connect,
  ];

  /// Whether a body is normally sent. HEAD and GET have none; QUERY does, by
  /// design, which is the whole point of it.
  bool get sendsBody => this != get && this != head && this != trace;

  static HttpMethod parse(String? value) => HttpMethod.values.firstWhere(
    (HttpMethod m) => m.label == value?.toUpperCase().trim(),
    orElse: () => HttpMethod.get,
  );
}

/// How the body is entered and encoded.
enum BodyType {
  none('None'),
  json('JSON'),
  form('Form'),
  raw('Raw');

  const BodyType(this.label);

  final String label;

  static BodyType parse(String? value) => BodyType.values.firstWhere(
    (BodyType t) => t.name == value,
    orElse: () => BodyType.none,
  );
}

/// The auth tab's four choices.
enum AuthType {
  none('No auth'),
  bearer('Bearer token'),
  basic('Basic auth'),
  apiKey('API key');

  const AuthType(this.label);

  final String label;

  static AuthType parse(String? value) => AuthType.values.firstWhere(
    (AuthType t) => t.name == value,
    orElse: () => AuthType.none,
  );
}

/// Where an API key rides.
enum ApiKeyLocation {
  header('Header'),
  query('Query');

  const ApiKeyLocation(this.label);

  final String label;

  static ApiKeyLocation parse(String? value) =>
      ApiKeyLocation.values.firstWhere(
        (ApiKeyLocation l) => l.name == value,
        orElse: () => ApiKeyLocation.header,
      );
}

/// What a variable's value means, which decides how it is inserted into a
/// body: numbers, booleans and JSON go in unquoted (board 4.6).
enum VarType {
  string('String'),
  number('Number'),
  boolean('Boolean'),
  json('JSON');

  const VarType(this.label);

  final String label;

  static VarType parse(String? value) => VarType.values.firstWhere(
    (VarType t) => t.name == value,
    orElse: () => VarType.string,
  );
}
