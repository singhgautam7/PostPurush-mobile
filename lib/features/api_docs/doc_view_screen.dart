import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../app/nav_shell.dart';
import '../../core/http/variable_resolver.dart';
import '../../core/models/api_request.dart';
import '../../core/models/environment.dart';
import '../../core/models/folder.dart';
import '../../core/models/history_entry.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_icon_button.dart';
import '../../core/widgets/app_menu.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/code_view.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/variable_text.dart';
import 'doc_model.dart';
import 'doc_pdf.dart';

/// Board 12.2. A full-screen reading view, so the nav is hidden. Folders become
/// sections and each endpoint gets its method, path, description, parameters,
/// headers and examples.
class DocViewScreen extends ConsumerStatefulWidget {
  const DocViewScreen({required this.folderId, super.key});

  final String folderId;

  @override
  ConsumerState<DocViewScreen> createState() => _DocViewScreenState();
}

class _DocViewScreenState extends ConsumerState<DocViewScreen> {
  final ScrollController _scroll = ScrollController();
  final Map<String, GlobalKey<State<StatefulWidget>>> _anchors =
      <String, GlobalKey<State<StatefulWidget>>>{};
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    // A document is a reading view, so the nav leaves while it is open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(navHiddenProvider.notifier).set(hidden: true);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final List<Folder> folders = ref.watch(foldersProvider).value ??
        const <Folder>[];
    final Folder? root = folders
        .where((Folder f) => f.id == widget.folderId)
        .firstOrNull;

    if (root == null) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppHeader(title: 'API docs', onBack: () => context.pop()),
              const Expanded(
                child: ErrorStateView(
                  message: 'That folder is no longer here.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Environment? env = ref.watch(activeEnvironmentProvider);
    final ApiDoc doc = ApiDoc.of(
      root: root,
      folders: folders,
      requests: ref.watch(requestsProvider).value ?? const <ApiRequest>[],
      history: ref.watch(historyProvider).value ?? const <HistoryEntry>[],
      environment: env,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppHeader(
                  title: 'API docs',
                  onBack: () => context.pop(),
                  actions: <Widget>[
                    Builder(
                      builder: (BuildContext anchor) => AppIconButton(
                        icon: Icons.toc_rounded,
                        onPressed: () => _jumpTo(anchor, doc),
                        semanticLabel: 'Jump to an endpoint',
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: doc.endpointCount == 0
                      ? EmptyState(
                          icon: Icons.description_outlined,
                          title: 'Nothing to document',
                          message:
                              '${root.name} has no saved requests yet.',
                          topPadding: 40,
                        )
                      : ListView(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(
                            Space.screen,
                            Space.sm,
                            Space.screen,
                            120,
                          ),
                          children: <Widget>[
                            Text(
                              doc.title,
                              style: AppType.display.copyWith(
                                fontSize: 30,
                                color: c.onSurface,
                              ),
                            ),
                            if (doc.description.isNotEmpty) ...<Widget>[
                              const SizedBox(height: Space.sm),
                              Text(
                                doc.description,
                                style: AppType.body.copyWith(
                                  color: c.onSurface,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              doc.summary,
                              style: AppType.monoLabel.copyWith(
                                color: c.onSurfaceVariant,
                              ),
                            ),
                            for (final DocSection section in doc.sections) ...<Widget>[
                              const SizedBox(height: Space.xxl),
                              SectionHeader(
                                label:
                                    '${section.title} · ${section.endpoints.length}',
                              ),
                              for (final DocEndpoint endpoint
                                  in section.endpoints) ...<Widget>[
                                const SizedBox(height: Space.lg),
                                _EndpointBlock(
                                  key: _anchorFor(endpoint),
                                  endpoint: endpoint,
                                  env: env,
                                ),
                              ],
                            ],
                          ],
                        ),
                ),
              ],
            ),
            if (doc.endpointCount > 0)
              Positioned(
                left: Space.screen,
                right: Space.screen,
                bottom: Space.xl,
                child: SafeArea(
                  top: false,
                  child: AppButton(
                    label: _exporting ? 'Building…' : 'Export as PDF',
                    icon: Icons.picture_as_pdf_rounded,
                    fullWidth: true,
                    onPressed: _exporting ? null : () => _export(doc, env),
                  ),
                ),
              ),
          ],
        ),
      ),
      backgroundColor: c.surface,
    );
  }

  GlobalKey<State<StatefulWidget>> _anchorFor(DocEndpoint endpoint) =>
      _anchors.putIfAbsent(endpoint.request.id, GlobalKey.new);

  Future<void> _jumpTo(BuildContext anchor, ApiDoc doc) async {
    final Duration duration = Motion.of(context, Motion.containerTransform);
    final Curve curve = Motion.curveOf(context, Motion.decelerate);
    final String? id = await showAppMenu<String>(
      context: anchor,
      header: 'Endpoints',
      width: 300,
      entries: <AppMenuEntry<String>>[
        for (final DocSection section in doc.sections)
          for (final DocEndpoint endpoint in section.endpoints)
            AppMenuEntry<String>(
              value: endpoint.request.id,
              label: endpoint.request.displayName,
              note: '${endpoint.method.label} ${endpoint.path}',
            ),
      ],
    );
    if (id == null || !mounted) return;
    final BuildContext? target = _anchors[id]?.currentContext;
    if (target == null || !target.mounted) return;
    await Scrollable.ensureVisible(target, duration: duration, curve: curve);
  }

  Future<void> _export(ApiDoc doc, Environment? env) async {
    final PdfOptions? options = await showPdfExportSheet(context, doc: doc, env: env);
    if (options == null || !mounted) return;
    setState(() => _exporting = true);
    try {
      final List<int> bytes = await DocPdf.build(
        doc,
        options: options,
        environment: env,
      );
      if (!mounted) return;
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: '${_slug(doc.title)}.pdf',
      );
    } catch (error) {
      if (mounted) AppSnackbar.info(context, 'The PDF could not be built');
      debugPrint('PDF export failed: $error');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  static String _slug(String title) => title
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('^-|-\$'), '');
}

/// Board 12.3. Paper size and what to include. Secrets are masked by default,
/// as in code export.
Future<PdfOptions?> showPdfExportSheet(
  BuildContext context, {
  required ApiDoc doc,
  Environment? env,
}) {
  final List<String> secrets = env == null
      ? const <String>[]
      : <String>{
          for (final DocSection s in doc.sections)
            for (final DocEndpoint e in s.endpoints)
              for (final VariableSpan span
                  in VariableResolver.scan(e.request.url, env))
                if (span.secret) span.name,
        }.toList(growable: false);

  return showAppSheet<PdfOptions>(
    context: context,
    title: 'Export as PDF',
    subtitle: '${doc.title} · ${doc.summary} · about '
        '${doc.estimatedPages} ${doc.estimatedPages == 1 ? 'page' : 'pages'}',
    builder: (BuildContext context) => _PdfForm(secrets: secrets),
  );
}

class _PdfForm extends StatefulWidget {
  const _PdfForm({required this.secrets});

  final List<String> secrets;

  @override
  State<_PdfForm> createState() => _PdfFormState();
}

class _PdfFormState extends State<_PdfForm> {
  PdfOptions _options = const PdfOptions();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 14,
    children: <Widget>[
      const SectionHeader(label: 'Paper'),
      SegmentedToggle<PdfPaper>(
        options: <(PdfPaper, String)>[
          for (final PdfPaper paper in PdfPaper.values) (paper, paper.label),
        ],
        selected: _options.paper,
        onChanged: (PdfPaper paper) => setState(
          () => _options = PdfOptions(
            paper: paper,
            includeExamples: _options.includeExamples,
            maskSecrets: _options.maskSecrets,
            tableOfContents: _options.tableOfContents,
          ),
        ),
      ),
      SwitchRow(
        label: 'Example responses',
        note: 'the last response of each request',
        value: _options.includeExamples,
        onChanged: (bool value) => setState(
          () => _options = PdfOptions(
            paper: _options.paper,
            includeExamples: value,
            maskSecrets: _options.maskSecrets,
            tableOfContents: _options.tableOfContents,
          ),
        ),
      ),
      if (widget.secrets.isNotEmpty)
        SwitchRow(
          label: 'Mask secrets',
          note: '${widget.secrets.length} masked: ${widget.secrets.join(', ')}',
          icon: Icons.lock_outline_rounded,
          value: _options.maskSecrets,
          onChanged: (bool value) => setState(
            () => _options = PdfOptions(
              paper: _options.paper,
              includeExamples: _options.includeExamples,
              maskSecrets: value,
              tableOfContents: _options.tableOfContents,
            ),
          ),
        ),
      SwitchRow(
        label: 'Table of contents',
        value: _options.tableOfContents,
        onChanged: (bool value) => setState(
          () => _options = PdfOptions(
            paper: _options.paper,
            includeExamples: _options.includeExamples,
            maskSecrets: _options.maskSecrets,
            tableOfContents: value,
          ),
        ),
      ),
      AppButton(
        label: 'Save or share PDF',
        icon: Icons.download_rounded,
        fullWidth: true,
        onPressed: () => Navigator.of(context).pop(_options),
      ),
    ],
  );
}

class _EndpointBlock extends StatelessWidget {
  const _EndpointBlock({required this.endpoint, required this.env, super.key});

  final DocEndpoint endpoint;
  final Environment? env;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Container(
      padding: const EdgeInsets.all(Space.screen),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: Radii.cardR,
        border: Border.all(color: c.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Space.row,
        children: <Widget>[
          Row(
            spacing: Space.row,
            children: <Widget>[
              MethodChip(endpoint.method),
              Expanded(
                child: VariableText.display(
                  text: endpoint.path,
                  env: env,
                  colors: c,
                  base: AppType.monoBody.copyWith(color: c.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            endpoint.request.displayName,
            style: AppType.headerTitle.copyWith(color: c.onSurface),
          ),
          if (endpoint.request.description.isNotEmpty)
            Text(
              endpoint.request.description,
              style: AppType.body.copyWith(height: 1.6, color: c.onSurface),
            ),
          if (endpoint.parameters.isNotEmpty)
            _Parameters(title: 'Parameters', rows: endpoint.parameters),
          if (endpoint.headers.isNotEmpty)
            _Parameters(title: 'Headers', rows: endpoint.headers),
          if (endpoint.exampleRequest.isNotEmpty) ...<Widget>[
            Text(
              'Example request',
              style: AppType.titleMedium.copyWith(color: c.onSurface),
            ),
            CodeBlock(source: endpoint.exampleRequest, env: env),
          ],
          if (endpoint.exampleResponse.isNotEmpty) ...<Widget>[
            Row(
              spacing: Space.sm,
              children: <Widget>[
                Text(
                  'Example response',
                  style: AppType.titleMedium.copyWith(color: c.onSurface),
                ),
                Text(
                  '${endpoint.exampleStatus}',
                  style: AppType.monoLabelStrong.copyWith(color: c.success),
                ),
              ],
            ),
            CodeBlock(source: endpoint.exampleResponse),
          ],
        ],
      ),
    );
  }
}

class _Parameters extends StatelessWidget {
  const _Parameters({required this.title, required this.rows});

  final String title;
  final List<DocParameter> rows;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: Space.xs),
          child: Text(
            title,
            style: AppType.titleMedium.copyWith(color: c.onSurface),
          ),
        ),
        for (final DocParameter row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.row),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: <Widget>[
                Wrap(
                  spacing: Space.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      row.name,
                      style: AppType.monoTabular.copyWith(
                        color: c.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      row.meta,
                      style: AppType.monoLabel.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (row.description.isNotEmpty)
                  Text(
                    row.description,
                    style: AppType.bodyMedium.copyWith(
                      fontSize: 14,
                      color: c.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
