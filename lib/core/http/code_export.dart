import 'dart:convert';

import 'request_builder.dart';

/// The six languages on the export sheet (board 9), in its order.
enum CodeLanguage {
  curl('cURL', 'bash'),
  javascript('JavaScript', 'js'),
  python('Python', 'py'),
  go('Go', 'go'),
  java('Java', 'java'),
  php('PHP', 'php');

  const CodeLanguage(this.label, this.extension);

  final String label;
  final String extension;

  static CodeLanguage parse(String? value) => CodeLanguage.values.firstWhere(
    (CodeLanguage l) => l.name == value,
    orElse: () => CodeLanguage.curl,
  );
}

/// Renders a resolved request as a snippet someone can paste and run.
///
/// The input is a [WireRequest], so the variables are already filled in and
/// secrets are already masked if the sheet asked for that. This file makes no
/// decision about what a secret is.
abstract final class CodeExport {
  static String render(WireRequest wire, CodeLanguage language) =>
      switch (language) {
        CodeLanguage.curl => _curl(wire),
        CodeLanguage.javascript => _javascript(wire),
        CodeLanguage.python => _python(wire),
        CodeLanguage.go => _go(wire),
        CodeLanguage.java => _java(wire),
        CodeLanguage.php => _php(wire),
      };

  static Map<String, String> _headers(WireRequest wire) => <String, String>{
    ...wire.headers,
    if (wire.contentType != null &&
        !wire.headers.keys.any((String k) => k.toLowerCase() == 'content-type'))
      'Content-Type': wire.contentType!,
  };

  // A single-quoted shell word: close, insert an escaped quote, reopen.
  static String _sh(String value) => "'${value.replaceAll("'", r"'\''")}'";

  static String _curl(WireRequest wire) {
    final List<String> parts = <String>[
      'curl -X ${wire.method.label}',
      '  ${_sh(wire.url)}',
      for (final MapEntry<String, String> h in _headers(wire).entries)
        '  -H ${_sh('${h.key}: ${h.value}')}',
      if (wire.body != null) '  -d ${_sh(wire.body!)}',
    ];
    return parts.join(' \\\n');
  }

  static String _javascript(WireRequest wire) {
    final Map<String, String> headers = _headers(wire);
    final StringBuffer out = StringBuffer()
      ..writeln("const response = await fetch(${jsonEncode(wire.url)}, {")
      ..writeln("  method: ${jsonEncode(wire.method.label)},");
    if (headers.isNotEmpty) {
      out.writeln('  headers: {');
      for (final MapEntry<String, String> h in headers.entries) {
        out.writeln('    ${jsonEncode(h.key)}: ${jsonEncode(h.value)},');
      }
      out.writeln('  },');
    }
    if (wire.body != null) {
      out.writeln('  body: ${jsonEncode(wire.body)},');
    }
    out
      ..writeln('});')
      ..writeln()
      ..write('console.log(response.status, await response.text());');
    return out.toString();
  }

  static String _python(WireRequest wire) {
    final Map<String, String> headers = _headers(wire);
    final List<String> lines = <String>['import requests', ''];
    if (headers.isNotEmpty) {
      lines.add('headers = {');
      for (final MapEntry<String, String> h in headers.entries) {
        lines.add('    ${_py(h.key)}: ${_py(h.value)},');
      }
      lines
        ..add('}')
        ..add('');
    }
    if (wire.body != null) {
      lines
        ..add('data = ${_py(wire.body!)}')
        ..add('');
    }
    lines
      ..add('response = requests.request(')
      ..add('    ${_py(wire.method.label)},')
      ..add('    ${_py(wire.url)},');
    if (headers.isNotEmpty) lines.add('    headers=headers,');
    if (wire.body != null) lines.add('    data=data,');
    lines
      ..add(')')
      ..add('')
      ..add('print(response.status_code, response.text)');
    return lines.join('\n');
  }

  /// Python's own string literal rules: triple quotes for anything with a
  /// newline, so a JSON body stays readable.
  static String _py(String value) {
    if (!value.contains('\n')) {
      return "'${value.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}'";
    }
    return '"""${value.replaceAll(r'\', r'\\').replaceAll('"""', r'\"\"\"')}"""';
  }

  static String _go(WireRequest wire) {
    final Map<String, String> headers = _headers(wire);
    final StringBuffer out = StringBuffer()
      ..writeln('package main')
      ..writeln()
      ..writeln('import (')
      ..writeln('\t"fmt"')
      ..writeln('\t"io"')
      ..writeln('\t"net/http"');
    if (wire.body != null) out.writeln('\t"strings"');
    out
      ..writeln(')')
      ..writeln()
      ..writeln('func main() {');
    if (wire.body != null) {
      out.writeln('\tbody := strings.NewReader(${_goString(wire.body!)})');
    }
    out
      ..writeln(
        '\treq, err := http.NewRequest(${_goString(wire.method.label)}, '
        '${_goString(wire.url)}, ${wire.body == null ? 'nil' : 'body'})',
      )
      ..writeln('\tif err != nil {')
      ..writeln('\t\tpanic(err)')
      ..writeln('\t}');
    for (final MapEntry<String, String> h in headers.entries) {
      out.writeln(
        '\treq.Header.Set(${_goString(h.key)}, ${_goString(h.value)})',
      );
    }
    out
      ..writeln('\tres, err := http.DefaultClient.Do(req)')
      ..writeln('\tif err != nil {')
      ..writeln('\t\tpanic(err)')
      ..writeln('\t}')
      ..writeln('\tdefer res.Body.Close()')
      ..writeln()
      ..writeln('\tout, _ := io.ReadAll(res.Body)')
      ..writeln('\tfmt.Println(res.StatusCode, string(out))')
      ..write('}');
    return out.toString();
  }

  /// Go has no raw-string escape for a backtick, so an interpreted string with
  /// JSON encoding is the honest choice.
  static String _goString(String value) => jsonEncode(value);

  static String _java(WireRequest wire) {
    final Map<String, String> headers = _headers(wire);
    final StringBuffer out = StringBuffer()
      ..writeln('import java.net.URI;')
      ..writeln('import java.net.http.*;')
      ..writeln()
      ..writeln('HttpClient client = HttpClient.newHttpClient();')
      ..writeln('HttpRequest request = HttpRequest.newBuilder()')
      ..writeln('    .uri(URI.create(${jsonEncode(wire.url)}))');
    for (final MapEntry<String, String> h in headers.entries) {
      out.writeln(
        '    .header(${jsonEncode(h.key)}, ${jsonEncode(h.value)})',
      );
    }
    out
      ..writeln(
        '    .method(${jsonEncode(wire.method.label)}, '
        '${wire.body == null ? 'HttpRequest.BodyPublishers.noBody()' : 'HttpRequest.BodyPublishers.ofString(${jsonEncode(wire.body)})'})',
      )
      ..writeln('    .build();')
      ..writeln()
      ..writeln(
        'HttpResponse<String> response = '
        'client.send(request, HttpResponse.BodyHandlers.ofString());',
      )
      ..write('System.out.println(response.statusCode() + " " + response.body());');
    return out.toString();
  }

  static String _php(WireRequest wire) {
    final Map<String, String> headers = _headers(wire);
    final StringBuffer out = StringBuffer()
      ..writeln('<?php')
      ..writeln(r'$ch = curl_init();')
      ..writeln('curl_setopt(\$ch, CURLOPT_URL, ${_phpString(wire.url)});')
      ..writeln(r'curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);')
      ..writeln(
        'curl_setopt(\$ch, CURLOPT_CUSTOMREQUEST, '
        '${_phpString(wire.method.label)});',
      );
    if (headers.isNotEmpty) {
      out.writeln(r'curl_setopt($ch, CURLOPT_HTTPHEADER, [');
      for (final MapEntry<String, String> h in headers.entries) {
        out.writeln('    ${_phpString('${h.key}: ${h.value}')},');
      }
      out.writeln(']);');
    }
    if (wire.body != null) {
      out.writeln(
        'curl_setopt(\$ch, CURLOPT_POSTFIELDS, ${_phpString(wire.body!)});',
      );
    }
    out
      ..writeln()
      ..writeln(r'$response = curl_exec($ch);')
      ..writeln(r'$status = curl_getinfo($ch, CURLINFO_HTTP_CODE);')
      ..writeln(r'curl_close($ch);')
      ..write('echo \$status, " ", \$response;');
    return out.toString();
  }

  /// Single quotes: PHP only honours `\\` and `\'` inside them, so nothing
  /// else needs escaping and a JSON body survives verbatim.
  static String _phpString(String value) =>
      "'${value.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}'";
}
