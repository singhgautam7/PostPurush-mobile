import 'package:flutter_test/flutter_test.dart';
import 'package:postpurush/core/http/assertion_runner.dart';
import 'package:postpurush/core/http/code_export.dart';
import 'package:postpurush/core/http/curl_parser.dart';
import 'package:postpurush/core/http/json_path.dart';
import 'package:postpurush/core/http/request_builder.dart';
import 'package:postpurush/core/http/variable_resolver.dart';
import 'package:postpurush/core/models/api_request.dart';
import 'package:postpurush/core/models/api_response.dart';
import 'package:postpurush/core/models/environment.dart';
import 'package:postpurush/core/models/http_method.dart';
import 'package:postpurush/core/models/key_value.dart';

Environment _staging() => const Environment(
  id: 'env',
  name: 'Staging',
  variables: <KeyValueRow>[
    KeyValueRow(id: '1', key: 'baseUrl', value: 'https://api.staging.dev'),
    KeyValueRow(id: '2', key: 'userId', value: '42', type: VarType.number),
    KeyValueRow(id: '3', key: 'token', value: 'abc123xyz', secret: true),
    KeyValueRow(id: '4', key: 'off', value: 'nope', enabled: false),
  ],
);

ApiRequest _request({
  String url = '{{baseUrl}}/posts',
  HttpMethod method = HttpMethod.post,
  String body = '',
  BodyType bodyType = BodyType.none,
  List<KeyValueRow> headers = const <KeyValueRow>[],
  List<KeyValueRow> params = const <KeyValueRow>[],
  AuthConfig auth = const AuthConfig(),
}) {
  final DateTime now = DateTime(2026, 9, 30);
  return ApiRequest(
    id: 'r',
    name: 'Create post',
    method: method,
    url: url,
    body: body,
    bodyType: bodyType,
    headers: headers,
    params: params,
    auth: auth,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('VariableResolver', () {
    final Environment env = _staging();

    test('substitutes what the environment carries', () {
      expect(
        VariableResolver.resolve('{{baseUrl}}/users/{{userId}}', env),
        'https://api.staging.dev/users/42',
      );
    });

    test('leaves a missing variable as typed, so the error tells the truth', () {
      expect(
        VariableResolver.resolve('{{baseUrl}}/{{nope}}', env),
        'https://api.staging.dev/{{nope}}',
      );
      expect(VariableResolver.missingIn('{{baseUrl}}/{{nope}}', env), <String>[
        'nope',
      ]);
    });

    test('a disabled variable counts as absent', () {
      expect(VariableResolver.resolve('{{off}}', env), '{{off}}');
      expect(VariableResolver.missingIn('{{off}}', env), <String>['off']);
    });

    test('no environment resolves nothing', () {
      expect(VariableResolver.resolve('{{baseUrl}}', null), '{{baseUrl}}');
      expect(VariableResolver.missingIn('{{baseUrl}}', null), <String>[
        'baseUrl',
      ]);
    });

    test('tolerates spacing inside the braces', () {
      expect(VariableResolver.resolve('{{ userId }}', env), '42');
    });

    test('a literal brace pair is not a variable', () {
      expect(VariableResolver.resolve('{{}}', env), '{{}}');
      expect(VariableResolver.namesIn('a { b } c'), isEmpty);
    });

    test('names are deduplicated in order of first appearance', () {
      expect(
        VariableResolver.namesIn('{{a}}/{{b}}/{{a}}'),
        <String>['a', 'b'],
      );
    });

    test('scan reports which spans resolved and which are secret', () {
      final List<VariableSpan> spans = VariableResolver.scan(
        '{{token}} {{nope}}',
        env,
      );
      expect(spans.length, 2);
      expect(spans.first.resolved, isTrue);
      expect(spans.first.secret, isTrue);
      expect(spans.last.resolved, isFalse);
    });

    test('resolvedCount counts only what the environment fills in', () {
      expect(
        VariableResolver.resolvedCount(<String>['baseUrl', 'nope'], env),
        1,
      );
    });

    test('a string variable is inserted quoted into a JSON body', () {
      const KeyValueRow text = KeyValueRow(id: '1', key: 'name');
      const KeyValueRow number = KeyValueRow(
        id: '2',
        key: 'age',
        type: VarType.number,
      );
      expect(
        VariableResolver.insertion(text, intoJsonBody: true),
        '"{{name}}"',
      );
      expect(
        VariableResolver.insertion(text, intoJsonBody: false),
        '{{name}}',
      );
      expect(
        VariableResolver.insertion(number, intoJsonBody: true),
        '{{age}}',
      );
    });
  });

  group('RequestBuilder', () {
    final Environment env = _staging();

    test('builds a resolved URL, headers and body', () {
      final WireRequest wire = RequestBuilder.build(
        _request(
          body: '{"userId": {{userId}}}',
          bodyType: BodyType.json,
          headers: <KeyValueRow>[
            const KeyValueRow(
              id: 'h',
              key: 'Authorization',
              value: 'Bearer {{token}}',
            ),
          ],
        ),
        env,
      );
      expect(wire.url, 'https://api.staging.dev/posts');
      expect(wire.headers['Authorization'], 'Bearer abc123xyz');
      expect(wire.body, '{"userId": 42}');
      expect(wire.contentType, 'application/json');
      expect(wire.secretHeaderNames, contains('Authorization'));
      expect(wire.missing, isEmpty);
    });

    test('masks only the spans that were secret', () {
      final WireRequest wire = RequestBuilder.build(
        _request(
          headers: <KeyValueRow>[
            const KeyValueRow(id: 'h', key: 'X-Token', value: '{{token}}'),
            const KeyValueRow(id: 'i', key: 'X-User', value: '{{userId}}'),
          ],
        ),
        env,
        maskSecrets: true,
      );
      expect(wire.headers['X-Token'], isNot(contains('abc123xyz')));
      expect(wire.headers['X-Token'], matches(RegExp(r'^•+$')));
      expect(wire.headers['X-User'], '42');
    });

    test('params merge into the query, and the URL wins a duplicate', () {
      final WireRequest wire = RequestBuilder.build(
        _request(
          url: 'https://x.dev/a?page=1',
          params: <KeyValueRow>[
            const KeyValueRow(id: 'p', key: 'page', value: '9'),
            const KeyValueRow(id: 'q', key: 'limit', value: '50'),
            const KeyValueRow(
              id: 'r',
              key: 'off',
              value: 'x',
              enabled: false,
            ),
          ],
        ),
        null,
      );
      final Uri uri = wire.uri;
      expect(uri.queryParameters['page'], '1');
      expect(uri.queryParameters['limit'], '50');
      expect(uri.queryParameters.containsKey('off'), isFalse);
    });

    test('a method with no body sends none', () {
      final WireRequest wire = RequestBuilder.build(
        _request(
          method: HttpMethod.get,
          body: '{"a":1}',
          bodyType: BodyType.json,
        ),
        null,
      );
      expect(wire.body, isNull);
    });

    test('basic auth is base64 encoded and counted as secret', () {
      final WireRequest wire = RequestBuilder.build(
        _request(
          auth: const AuthConfig(
            type: AuthType.basic,
            username: 'ada',
            password: 'lovelace',
          ),
        ),
        null,
      );
      expect(wire.headers['Authorization'], 'Basic YWRhOmxvdmVsYWNl');
      expect(wire.secretHeaderNames, contains('Authorization'));
    });

    test('an API key can ride in the query instead of a header', () {
      final WireRequest wire = RequestBuilder.build(
        _request(
          url: 'https://x.dev/a',
          auth: const AuthConfig(
            type: AuthType.apiKey,
            keyName: 'key',
            keyValue: 'k1',
            keyIn: ApiKeyLocation.query,
          ),
        ),
        null,
      );
      expect(wire.uri.queryParameters['key'], 'k1');
      expect(wire.headers.containsKey('key'), isFalse);
    });

    test('a header the user typed is not overwritten by the auth tab', () {
      final WireRequest wire = RequestBuilder.build(
        _request(
          headers: <KeyValueRow>[
            const KeyValueRow(
              id: 'h',
              key: 'Authorization',
              value: 'Custom mine',
            ),
          ],
          auth: const AuthConfig(type: AuthType.bearer, token: 'theirs'),
        ),
        null,
      );
      expect(wire.headers['Authorization'], 'Custom mine');
    });

    test('form fields go out url-encoded', () {
      final ApiRequest request = _request(bodyType: BodyType.form).copyWith(
        formFields: <KeyValueRow>[
          const KeyValueRow(id: 'a', key: 'name', value: 'a b'),
          const KeyValueRow(id: 'b', key: 'x', value: 'y&z'),
        ],
      );
      final WireRequest wire = RequestBuilder.build(request, null);
      expect(wire.body, 'name=a+b&x=y%26z');
      expect(wire.contentType, 'application/x-www-form-urlencoded');
    });

    group('isSendable', () {
      test('accepts a URL whose host is still a variable', () {
        expect(RequestBuilder.isSendable('{{baseUrl}}/posts'), isFalse);
        expect(
          RequestBuilder.isSendable('https://{{host}}/posts'),
          isTrue,
        );
      });

      test('rejects a URL with no scheme, and says so', () {
        expect(RequestBuilder.isSendable('example.com'), isFalse);
        expect(RequestBuilder.urlError('example.com'), isNotNull);
      });

      test('rejects a scheme that is not http', () {
        expect(RequestBuilder.isSendable('ftp://example.com'), isFalse);
      });

      test('an empty URL is not an error, only not sendable', () {
        expect(RequestBuilder.isSendable(''), isFalse);
        expect(RequestBuilder.urlError(''), isNull);
      });
    });
  });

  group('CurlParser', () {
    test('parses method, headers, body and URL', () {
      final ApiRequest? r = CurlParser.parse(
        "curl -X POST 'https://api.dev/posts' \\\n"
        "  -H 'Content-Type: application/json' \\\n"
        '  -d \'{"title":"hi"}\'',
        id: 'x',
      );
      expect(r, isNotNull);
      expect(r!.method, HttpMethod.post);
      expect(r.url, 'https://api.dev/posts');
      expect(r.bodyType, BodyType.json);
      expect(r.body, '{"title":"hi"}');
      expect(
        r.headers.any((KeyValueRow h) => h.key == 'Content-Type'),
        isTrue,
      );
    });

    test('moves a bearer header onto the auth tab', () {
      final ApiRequest? r = CurlParser.parse(
        "curl https://api.dev -H 'Authorization: Bearer tok'",
        id: 'x',
      );
      expect(r!.auth.type, AuthType.bearer);
      expect(r.auth.token, 'tok');
      expect(r.headers, isEmpty);
    });

    test('infers POST from a body when no method is given', () {
      final ApiRequest? r = CurlParser.parse(
        "curl https://api.dev -d 'a=1'",
        id: 'x',
      );
      expect(r!.method, HttpMethod.post);
    });

    test('pulls query params out of the URL', () {
      final ApiRequest? r = CurlParser.parse(
        'curl "https://api.dev/a?page=2&limit=5"',
        id: 'x',
      );
      expect(r!.params.length, 2);
      expect(
        r.params.firstWhere((KeyValueRow p) => p.key == 'page').value,
        '2',
      );
    });

    test('a paste with no URL is rejected rather than guessed at', () {
      expect(CurlParser.parse('curl -X POST', id: 'x'), isNull);
      expect(CurlParser.parse('not a command', id: 'x'), isNull);
    });

    test('recognises a cURL command', () {
      expect(CurlParser.looksLikeCurl('  curl https://x'), isTrue);
      expect(CurlParser.looksLikeCurl('wget https://x'), isFalse);
    });
  });

  group('CodeExport', () {
    final WireRequest wire = RequestBuilder.build(
      _request(
        url: 'https://api.dev/posts',
        body: '{"a":1}',
        bodyType: BodyType.json,
        headers: <KeyValueRow>[
          const KeyValueRow(id: 'h', key: 'X-Key', value: "it's"),
        ],
      ),
      null,
    );

    test('every language renders something that mentions the URL', () {
      for (final CodeLanguage language in CodeLanguage.values) {
        final String snippet = CodeExport.render(wire, language);
        expect(snippet, contains('api.dev/posts'), reason: language.label);
        expect(snippet.trim(), isNotEmpty, reason: language.label);
      }
    });

    test('cURL escapes a single quote without breaking the word', () {
      final String snippet = CodeExport.render(wire, CodeLanguage.curl);
      expect(snippet, contains(r"'\''"));
      expect(snippet, contains('-X POST'));
      expect(snippet, contains('-d '));
    });

    test('JavaScript emits valid JSON literals', () {
      final String snippet = CodeExport.render(wire, CodeLanguage.javascript);
      expect(snippet, contains('"https://api.dev/posts"'));
      expect(snippet, contains('method: "POST"'));
    });

    test('Python names the method and the data', () {
      final String snippet = CodeExport.render(wire, CodeLanguage.python);
      expect(snippet, contains('import requests'));
      expect(snippet, contains('data=data'));
    });

    test('Go imports strings only when there is a body', () {
      expect(CodeExport.render(wire, CodeLanguage.go), contains('"strings"'));
      final WireRequest noBody = RequestBuilder.build(
        _request(method: HttpMethod.get, url: 'https://api.dev/a'),
        null,
      );
      expect(
        CodeExport.render(noBody, CodeLanguage.go),
        isNot(contains('"strings"')),
      );
    });

    test('PHP escapes a single quote', () {
      final String snippet = CodeExport.render(wire, CodeLanguage.php);
      expect(snippet, contains(r"it\'s"));
    });
  });

  group('JsonPath', () {
    const String doc = '{"a":{"b":[1,{"c":"hi"}]},"n":null}';

    test('reads through objects and arrays', () {
      expect(JsonPath.read(doc, r'$.a.b[0]'), 1);
      expect(JsonPath.read(doc, r'$.a.b[1].c'), 'hi');
    });

    test('a path without the root prefix works too', () {
      expect(JsonPath.read(doc, 'a.b[1].c'), 'hi');
    });

    test('a path that leads nowhere answers null, not an error', () {
      expect(JsonPath.read(doc, r'$.a.z'), isNull);
      expect(JsonPath.read(doc, r'$.a.b[9]'), isNull);
      expect(JsonPath.read('not json', r'$.a'), isNull);
    });

    test('describe prints a value the way a row shows it', () {
      expect(JsonPath.describe(null), 'nothing');
      expect(JsonPath.describe('hi'), 'hi');
      expect(JsonPath.describe(42), '42');
      expect(JsonPath.describe(<int>[1, 2]), '[1,2]');
    });
  });

  group('AssertionRunner', () {
    final ApiResponse response = ApiResponse.arrived(
      statusCode: 201,
      reasonPhrase: 'Created',
      headers: const <String, String>{
        'content-type': 'application/json; charset=utf-8',
      },
      body: '{"id":101,"title":"Test post","userId":42}',
      durationMs: 1391,
      sizeBytes: 79,
    );

    AssertionResult run(
      AssertTarget target,
      AssertComparator comparator,
      String expected, {
      String subject = '',
    }) => AssertionRunner.run(
      Assertion(
        id: 'a',
        target: target,
        comparator: comparator,
        subject: subject,
        expected: expected,
      ),
      response,
    );

    test('status equals', () {
      expect(
        run(AssertTarget.status, AssertComparator.equals, '201').passed,
        isTrue,
      );
      expect(
        run(AssertTarget.status, AssertComparator.equals, '200').passed,
        isFalse,
      );
    });

    test('response time under, and the actual is printed', () {
      final AssertionResult fail = run(
        AssertTarget.responseTime,
        AssertComparator.under,
        '500',
      );
      expect(fail.passed, isFalse);
      expect(fail.actual, '1,391 ms');
      expect(
        run(AssertTarget.responseTime, AssertComparator.under, '2000').passed,
        isTrue,
      );
    });

    test('header contains, case-insensitively', () {
      expect(
        run(
          AssertTarget.header,
          AssertComparator.contains,
          'application/json',
          subject: 'Content-Type',
        ).passed,
        isTrue,
      );
    });

    test('a missing header is reported, not thrown', () {
      final AssertionResult result = run(
        AssertTarget.header,
        AssertComparator.equals,
        'x',
        subject: 'X-Nope',
      );
      expect(result.passed, isFalse);
      expect(result.actual, 'nothing');
    });

    test('body contains, and says where it found it', () {
      final AssertionResult result = run(
        AssertTarget.body,
        AssertComparator.contains,
        'Test post',
      );
      expect(result.passed, isTrue);
      expect(result.note, r'found at $.title');
    });

    test('a JSON path equals, with or without the quoting', () {
      expect(
        run(
          AssertTarget.jsonPath,
          AssertComparator.equals,
          '42',
          subject: r'$.userId',
        ).passed,
        isTrue,
      );
      expect(
        run(
          AssertTarget.jsonPath,
          AssertComparator.equals,
          '"Test post"',
          subject: r'$.title',
        ).passed,
        isTrue,
      );
    });

    test('summary names how many passed', () {
      final List<AssertionResult> results = <AssertionResult>[
        run(AssertTarget.status, AssertComparator.equals, '201'),
        run(AssertTarget.responseTime, AssertComparator.under, '500'),
      ];
      expect(AssertionRunner.summary(results), '1 of 2 passed');
      expect(AssertionRunner.allPassed(results), isFalse);
    });
  });
}
