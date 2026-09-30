import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/http/variable_resolver.dart';
import '../../core/models/api_request.dart';
import '../../core/models/environment.dart';
import 'doc_model.dart';

/// What the export sheet chose.
class PdfOptions {
  const PdfOptions({
    this.paper = PdfPaper.a4,
    this.includeExamples = true,
    this.maskSecrets = true,
    this.tableOfContents = true,
  });

  final PdfPaper paper;
  final bool includeExamples;
  final bool maskSecrets;
  final bool tableOfContents;
}

enum PdfPaper {
  a4('A4'),
  letter('Letter');

  const PdfPaper(this.label);

  final String label;

  PdfPageFormat get format =>
      this == PdfPaper.a4 ? PdfPageFormat.a4 : PdfPageFormat.letter;
}

/// Renders an [ApiDoc] to a PDF.
///
/// Monochrome and typographic: the document is meant to be read and printed,
/// not to look like a screenshot of the app. Secrets are masked by default,
/// exactly as in code export, so a shared PDF cannot leak a token.
abstract final class DocPdf {
  static Future<List<int>> build(
    ApiDoc doc, {
    required PdfOptions options,
    Environment? environment,
  }) async {
    final pw.Document pdf = pw.Document(
      title: doc.title,
      author: 'PostPurush',
    );

    String fill(String input) {
      if (environment == null) return input;
      String out = input;
      for (final VariableSpan span in VariableResolver.scan(
        input,
        environment,
      )) {
        if (!span.resolved) continue;
        out = out.replaceAll(
          '{{${span.name}}}',
          options.maskSecrets && span.secret
              ? VariableResolver.mask(span.value!)
              : span.value!,
        );
      }
      return out;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: options.paper.format,
        margin: const pw.EdgeInsets.fromLTRB(48, 54, 48, 54),
        footer: (pw.Context context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (pw.Context context) => <pw.Widget>[
          pw.Text(
            doc.title,
            style: const pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            doc.summary,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          if (doc.description.isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 14),
            pw.Text(doc.description, style: const pw.TextStyle(fontSize: 11)),
          ],
          if (options.tableOfContents && doc.sections.length > 1) ...<pw.Widget>[
            pw.SizedBox(height: 22),
            pw.Text(
              'Contents',
              style: const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            for (final DocSection section in doc.sections)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Text(
                  '${section.title} · '
                  '${section.endpoints.length} '
                  '${section.endpoints.length == 1 ? 'endpoint' : 'endpoints'}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
          ],
          for (final DocSection section in doc.sections) ...<pw.Widget>[
            pw.SizedBox(height: 26),
            pw.Text(
              section.title,
              style: const pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(height: 12, color: PdfColors.grey400),
            for (final DocEndpoint endpoint in section.endpoints)
              _endpoint(endpoint, options: options, fill: fill),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _endpoint(
    DocEndpoint endpoint, {
    required PdfOptions options,
    required String Function(String) fill,
  }) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 20),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Text(
                endpoint.method.label,
                style: const pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Text(
                fill(endpoint.path),
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          endpoint.request.displayName,
          style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        if (endpoint.request.description.isNotEmpty) ...<pw.Widget>[
          pw.SizedBox(height: 4),
          pw.Text(
            endpoint.request.description,
            style: const pw.TextStyle(fontSize: 10.5),
          ),
        ],
        if (endpoint.parameters.isNotEmpty)
          _parameters('Parameters', endpoint.parameters),
        if (endpoint.headers.isNotEmpty)
          _parameters('Headers', endpoint.headers),
        if (options.includeExamples && endpoint.exampleRequest.isNotEmpty)
          _code('Example request', fill(endpoint.exampleRequest)),
        if (options.includeExamples && endpoint.exampleResponse.isNotEmpty)
          _code(
            'Example response · ${endpoint.exampleStatus}',
            endpoint.exampleResponse,
          ),
      ],
    ),
  );

  static pw.Widget _parameters(String title, List<DocParameter> rows) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.SizedBox(height: 10),
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
          ),
          for (final DocParameter row in rows)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Row(
                    children: <pw.Widget>[
                      pw.Text(
                        row.name,
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        row.meta,
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  if (row.description.isNotEmpty)
                    pw.Text(
                      row.description,
                      style: const pw.TextStyle(
                        fontSize: 9.5,
                        color: PdfColors.grey800,
                      ),
                    ),
                ],
              ),
            ),
        ],
      );

  static pw.Widget _code(String title, String body) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.SizedBox(height: 10),
      pw.Text(
        title,
        style: const pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        // A long response would take over the document, so it is capped and
        // the cap is stated rather than silently truncating.
        child: pw.Text(
          body.length > 2000
              ? '${body.substring(0, 2000)}\n… truncated'
              : body,
          style: const pw.TextStyle(fontSize: 8.5),
        ),
      ),
    ],
  );
}
