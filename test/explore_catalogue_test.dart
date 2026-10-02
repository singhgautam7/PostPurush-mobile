import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:postpurush/core/models/explore_api.dart';

/// The catalogue is a shipped asset that the repository decodes leniently: a
/// malformed row is skipped at runtime rather than crashing Explore. That is
/// the right behaviour on a device and the wrong one for catching a typo, so
/// the strict read lives here.
void main() {
  final List<dynamic> rows =
      (jsonDecode(File('assets/data/explore_apis.json').readAsStringSync())
              as Map<String, dynamic>)['apis']
          as List<dynamic>;
  final List<ExploreApi> apis = rows
      .map((dynamic e) => ExploreApi.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);

  test('every row decodes', () => expect(apis, hasLength(rows.length)));

  test('names are unique, so a folder per API cannot collide', () {
    expect(apis.map((ExploreApi a) => a.name).toSet(), hasLength(apis.length));
  });

  test('every row is filled in', () {
    for (final ExploreApi api in apis) {
      expect(api.name, isNotEmpty, reason: api.baseUrl);
      expect(api.description, isNotEmpty, reason: api.name);
      expect(api.category, isNotEmpty, reason: api.name);
      expect(api.docsUrl, startsWith('http'), reason: api.name);
      // Add to Folders saves one request per sample, so an empty list would
      // make a folder with nothing in it.
      expect(api.samples, isNotEmpty, reason: api.name);
    }
  });

  test('the https flag agrees with the base URL', () {
    for (final ExploreApi api in apis) {
      expect(
        api.baseUrl.startsWith('https://'),
        api.https,
        reason: api.name,
      );
    }
  });

  test('the catalogue covers more than reads', () {
    final Set<String> methods = <String>{
      for (final ExploreApi api in apis)
        for (final ApiSample sample in api.samples) sample.method.label,
    };
    expect(methods, containsAll(<String>['GET', 'POST', 'PUT', 'PATCH', 'DELETE']));
  });
}
