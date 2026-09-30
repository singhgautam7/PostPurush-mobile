import 'package:flutter/foundation.dart';

import '../../core/models/api_request.dart';
import '../../core/models/environment.dart';
import '../../core/models/folder.dart';
import '../../core/models/history_entry.dart';
import '../../core/models/http_method.dart';
import '../../core/models/key_value.dart';

/// One documented parameter: a name, where it rides, and whether it is needed.
@immutable
class DocParameter {
  const DocParameter({
    required this.name,
    required this.type,
    required this.where,
    required this.required,
    required this.description,
  });

  final String name;

  /// `string`, `number`, `boolean`, `json`.
  final String type;

  /// `query`, `path`, `header`, `body`.
  final String where;
  final bool required;
  final String description;

  /// `number · path · required`, as the board prints it.
  String get meta => <String>[
    type,
    where,
    if (required) 'required',
  ].join(' · ');
}

/// One endpoint in the document.
@immutable
class DocEndpoint {
  const DocEndpoint({
    required this.request,
    required this.parameters,
    required this.headers,
    required this.exampleRequest,
    required this.exampleResponse,
    required this.exampleStatus,
  });

  final ApiRequest request;
  final List<DocParameter> parameters;
  final List<DocParameter> headers;

  /// Empty when the request sends no body.
  final String exampleRequest;

  /// The last response this request produced, or empty if it has none.
  final String exampleResponse;
  final int exampleStatus;

  HttpMethod get method => request.method;

  /// The path with its host dropped, which is what a document shows.
  String get path {
    final Uri? uri = Uri.tryParse(request.url);
    if (uri == null || uri.path.isEmpty) return request.url;
    return uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
  }
}

/// One folder's worth of endpoints.
@immutable
class DocSection {
  const DocSection({required this.title, required this.endpoints});

  final String title;
  final List<DocEndpoint> endpoints;
}

/// A whole document, ready to render on screen or into a PDF.
///
/// Built from what is already stored: each request's description, its
/// parameters and headers, and the last response history holds for it. Nothing
/// is fetched to build it.
@immutable
class ApiDoc {
  const ApiDoc({
    required this.title,
    required this.description,
    required this.sections,
    required this.environmentName,
  });

  factory ApiDoc.of({
    required Folder root,
    required List<Folder> folders,
    required List<ApiRequest> requests,
    required List<HistoryEntry> history,
    Environment? environment,
  }) {
    // The last response per request, so an example is the real one.
    final Map<String, HistoryEntry> lastByName = <String, HistoryEntry>{};
    for (final HistoryEntry e in history) {
      final String key = '${e.method.label} ${e.host}${e.path}';
      final HistoryEntry? existing = lastByName[key];
      if (existing == null || e.sentAt.isAfter(existing.sentAt)) {
        lastByName[key] = e;
      }
    }

    DocEndpoint endpointOf(ApiRequest r) {
      final Uri? uri = Uri.tryParse(r.url);
      final HistoryEntry? last =
          lastByName['${r.method.label} ${uri?.host ?? ''}${uri?.path ?? ''}'];
      return DocEndpoint(
        request: r,
        parameters: <DocParameter>[
          for (final KeyValueRow p in r.params.active)
            DocParameter(
              name: p.key,
              type: _typeOf(p.value),
              where: 'query',
              required: false,
              description: p.description ?? '',
            ),
          if (r.bodyType == BodyType.form)
            for (final KeyValueRow f in r.formFields.active)
              DocParameter(
                name: f.key,
                type: _typeOf(f.value),
                where: 'body',
                required: true,
                description: f.description ?? '',
              ),
        ],
        headers: <DocParameter>[
          for (final KeyValueRow h in r.headers.active)
            DocParameter(
              name: h.key,
              type: 'string',
              where: 'header',
              required: true,
              description: h.description ?? '',
            ),
        ],
        exampleRequest: r.bodyType == BodyType.json ? r.body : '',
        exampleResponse: last?.body ?? '',
        exampleStatus: last?.status ?? 0,
      );
    }

    // Requests sitting directly in the collection come first, then one section
    // per subfolder, which is how the board groups them.
    final List<DocSection> sections = <DocSection>[];
    final List<ApiRequest> direct = <ApiRequest>[
      for (final ApiRequest r in requests) if (r.folderId == root.id) r,
    ];
    if (direct.isNotEmpty) {
      sections.add(
        DocSection(
          title: root.name,
          endpoints: direct.map(endpointOf).toList(growable: false),
        ),
      );
    }
    for (final Folder child in folders) {
      if (child.parentId != root.id) continue;
      final List<ApiRequest> own = <ApiRequest>[
        for (final ApiRequest r in requests) if (r.folderId == child.id) r,
      ];
      if (own.isEmpty) continue;
      sections.add(
        DocSection(
          title: child.name,
          endpoints: own.map(endpointOf).toList(growable: false),
        ),
      );
    }

    return ApiDoc(
      title: root.name,
      description: root.description,
      sections: sections,
      environmentName: environment?.name ?? '',
    );
  }

  final String title;
  final String description;
  final List<DocSection> sections;

  /// Empty when no environment is active.
  final String environmentName;

  int get endpointCount =>
      sections.fold(0, (int sum, DocSection s) => sum + s.endpoints.length);

  /// "5 endpoints · 2 folders · resolved with Staging".
  String get summary => <String>[
    '$endpointCount ${endpointCount == 1 ? 'endpoint' : 'endpoints'}',
    '${sections.length} ${sections.length == 1 ? 'section' : 'sections'}',
    if (environmentName.isNotEmpty) 'resolved with $environmentName',
  ].join(' · ');

  /// Roughly how many A4 pages this will take, for the export sheet. A rough
  /// number the reader can sanity-check beats no number at all.
  int get estimatedPages {
    final int units = sections.length + endpointCount * 3;
    return (units / 6).ceil().clamp(1, 200);
  }

  /// Guessed from the value, because nothing stores a type for a param.
  static String _typeOf(String value) {
    final String v = value.trim();
    if (v.isEmpty) return 'string';
    if (v == 'true' || v == 'false') return 'boolean';
    if (double.tryParse(v) != null) return 'number';
    if (v.startsWith('{') || v.startsWith('[')) return 'json';
    return 'string';
  }
}
