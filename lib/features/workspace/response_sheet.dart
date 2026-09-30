import 'package:flutter/material.dart';

import '../../core/models/api_response.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/util/format.dart';
import '../../core/widgets/app_icon_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/code_view.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/states.dart';
import 'workspace_controller.dart';

enum _Tab { body, headers, cookies }

enum _BodyView { pretty, raw, preview }

/// Board 2.4 and 2.5. The dock grows into this: a bottom sheet with a status
/// header that keeps Send within reach, three tabs, and a body that folds node
/// by node.
///
/// It is one scroll view, driven by the controller a `DraggableScrollableSheet`
/// hands down. That is what makes the drag and the body scroll a single
/// gesture: pulling up when the body is at its top raises the sheet, and once
/// it is full the same drag scrolls the body.
class ResponseSheet extends StatefulWidget {
  const ResponseSheet({
    required this.response,
    required this.scrollController,
    required this.stop,
    required this.onStopChanged,
    required this.onResend,
    super.key,
  });

  final ApiResponse response;

  /// From the enclosing `DraggableScrollableSheet`.
  final ScrollController scrollController;

  final DockStop stop;
  final ValueChanged<DockStop> onStopChanged;
  final VoidCallback onResend;

  @override
  State<ResponseSheet> createState() => _ResponseSheetState();
}

class _ResponseSheetState extends State<ResponseSheet> {
  _Tab _tab = _Tab.body;
  _BodyView _view = _BodyView.pretty;
  bool _wrap = false;
  final TextEditingController _find = TextEditingController();
  bool _finding = false;

  @override
  void didUpdateWidget(ResponseSheet old) {
    super.didUpdateWidget(old);
    if (old.response != widget.response) {
      _tab = _Tab.body;
      _view = _BodyView.pretty;
      _find.clear();
      _finding = false;
    }
  }

  @override
  void dispose() {
    _find.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final ApiResponse response = widget.response;
    final bool full = widget.stop == DockStop.full;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceContainer,
        borderRadius: full ? null : Radii.sheetR,
        border: Border(top: BorderSide(color: c.outline)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: c.shadow,
            blurRadius: Elevations.navPillBlur,
            offset: const Offset(0, -Elevations.navPill),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: full ? BorderRadius.zero : Radii.sheetR,
        child: CustomScrollView(
          controller: widget.scrollController,
          slivers: <Widget>[
            SliverToBoxAdapter(child: _chrome(response, full: full)),
            ..._content(response),
            const SliverToBoxAdapter(child: SizedBox(height: Space.screen)),
          ],
        ),
      ),
    );
  }

  Widget _chrome(ApiResponse response, {required bool full}) {
    final AppColors c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: Space.row, bottom: Space.sm),
          child: Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: c.onSurfaceVariant,
                borderRadius: Radii.fullR,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: <Widget>[
              _Header(
                response: response,
                full: full,
                onResend: widget.onResend,
                onToggleSize: () => widget.onStopChanged(
                  full ? DockStop.half : DockStop.full,
                ),
              ),
              SegmentedToggle<_Tab>(
                options: const <(_Tab, String)>[
                  (_Tab.body, 'Body'),
                  (_Tab.headers, 'Headers'),
                  (_Tab.cookies, 'Cookies'),
                ],
                badges: <Object?, String>{
                  _Tab.headers: '${response.headers.length}',
                  _Tab.cookies: '${response.cookies.length}',
                },
                selected: _tab,
                onChanged: (_Tab value) => setState(() => _tab = value),
              ),
              if (_tab == _Tab.body) _bodyControls(response),
              if (_finding)
                SearchField(
                  controller: _find,
                  hint: 'Find in body',
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                ),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
      ],
    );
  }

  Widget _bodyControls(ApiResponse response) {
    final AppColors c = context.colors;
    final bool json = response.isJson;
    return Row(
      spacing: Space.sm,
      children: <Widget>[
        if (json)
          PillChip(
            label: 'Pretty',
            selected: _view == _BodyView.pretty,
            onTap: () => setState(() => _view = _BodyView.pretty),
          ),
        PillChip(
          label: 'Raw',
          selected: _view == _BodyView.raw || !json,
          onTap: () => setState(() => _view = _BodyView.raw),
        ),
        if (!json && response.body.isNotEmpty)
          PillChip(
            label: 'Preview',
            selected: _view == _BodyView.preview,
            onTap: () => setState(() => _view = _BodyView.preview),
          ),
        const Spacer(),
        if (!json || _view == _BodyView.raw)
          AppIconButton(
            icon: _wrap ? Icons.wrap_text_rounded : Icons.short_text_rounded,
            onPressed: () => setState(() => _wrap = !_wrap),
            semanticLabel: _wrap ? 'Stop wrapping lines' : 'Wrap long lines',
            filled: false,
            size: IconSpec.navTarget,
            tint: c.icon,
          ),
        AppIconButton(
          icon: Icons.search_rounded,
          onPressed: () => setState(() {
            _finding = !_finding;
            if (!_finding) _find.clear();
          }),
          semanticLabel: 'Find in body',
          filled: false,
          size: IconSpec.navTarget,
          tint: _finding ? c.accent : c.icon,
        ),
        AppIconButton(
          icon: Icons.content_copy_rounded,
          onPressed: () async {
            await copyToClipboard(response.body);
            if (mounted) AppSnackbar.info(context, 'Response copied');
          },
          semanticLabel: 'Copy the response body',
          filled: false,
          size: IconSpec.navTarget,
          tint: c.icon,
        ),
      ],
    );
  }

  List<Widget> _content(ApiResponse response) {
    final AppColors c = context.colors;
    const EdgeInsets margin = EdgeInsets.symmetric(horizontal: Space.screen);

    switch (_tab) {
      case _Tab.body:
        if (response.body.isEmpty) {
          return <Widget>[
            SliverToBoxAdapter(
              child: _Note(
                text: response.statusCode == 204
                    ? 'No content, which is what a 204 means.'
                    : 'The response had no body.',
              ),
            ),
          ];
        }
        final String source = _view == _BodyView.pretty && response.isJson
            ? response.pretty
            : response.body;
        final String query = _find.text.trim();
        if (query.isNotEmpty) {
          return _matches(source, query);
        }
        return <Widget>[
          SliverPadding(
            padding: margin,
            sliver: DecoratedSliver(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: Radii.cardR,
                border: Border.all(color: c.outline),
              ),
              sliver: SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: Space.md),
                sliver: SliverCodeView(
                  source: source,
                  wrap: _wrap || _view == _BodyView.preview,
                  foldable: _view == _BodyView.pretty && response.isJson,
                ),
              ),
            ),
          ),
        ];

      case _Tab.headers:
        if (response.headers.isEmpty) {
          return const <Widget>[
            SliverToBoxAdapter(child: _Note(text: 'No headers came back.')),
          ];
        }
        final List<String> names = response.headers.keys.toList()..sort();
        return <Widget>[
          SliverPadding(
            padding: margin,
            sliver: SliverToBoxAdapter(
              child: RowGroup(
                onSurface: true,
                children: <Widget>[
                  for (final String name in names)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.lg,
                        vertical: Space.row,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: <Widget>[
                          Text(
                            name,
                            style: AppType.monoTabular.copyWith(
                              color: c.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            response.headers[name]!,
                            style: AppType.monoTabular.copyWith(
                              color: c.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ];

      case _Tab.cookies:
        final List<String> cookies = response.cookies;
        if (cookies.isEmpty) {
          return const <Widget>[
            SliverToBoxAdapter(child: _Note(text: 'No cookies were set.')),
          ];
        }
        return <Widget>[
          SliverPadding(
            padding: margin,
            sliver: SliverToBoxAdapter(
              child: RowGroup(
                onSurface: true,
                children: <Widget>[
                  for (final String cookie in cookies)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.lg,
                        vertical: Space.md,
                      ),
                      child: Text(
                        cookie,
                        style: AppType.monoTabular.copyWith(color: c.onSurface),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ];
    }
  }

  /// Lines of the body that hold the query, with their line numbers, which is
  /// more use on a phone than a highlight you have to scroll to find.
  List<Widget> _matches(String source, String query) {
    final AppColors c = context.colors;
    final List<String> lines = source.split('\n');
    final String needle = query.toLowerCase();
    final List<(int, String)> hits = <(int, String)>[
      for (int i = 0; i < lines.length; i++)
        if (lines[i].toLowerCase().contains(needle)) (i + 1, lines[i]),
    ];
    if (hits.isEmpty) {
      return <Widget>[
        SliverToBoxAdapter(child: _Note(text: 'No line holds "$query".')),
      ];
    }
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: Space.screen),
        sliver: SliverList.builder(
          itemCount: hits.length,
          itemBuilder: (BuildContext context, int i) {
            final (int number, String text) = hits[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Space.md,
                children: <Widget>[
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$number',
                      textAlign: TextAlign.right,
                      style: AppType.monoCode.copyWith(
                        color: c.onSurfaceMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      _highlight(text, needle, c),
                      style: AppType.monoCode.copyWith(color: c.onSurface),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ];
  }

  static TextSpan _highlight(String line, String needle, AppColors c) {
    final List<InlineSpan> spans = <InlineSpan>[];
    final String lower = line.toLowerCase();
    int at = 0;
    while (true) {
      final int found = lower.indexOf(needle, at);
      if (found < 0) {
        spans.add(TextSpan(text: line.substring(at)));
        break;
      }
      if (found > at) spans.add(TextSpan(text: line.substring(at, found)));
      spans.add(
        TextSpan(
          text: line.substring(found, found + needle.length),
          style: TextStyle(
            color: c.onPrimaryContainer,
            backgroundColor: c.primaryContainer,
          ),
        ),
      );
      at = found + needle.length;
    }
    return TextSpan(children: spans);
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.response,
    required this.full,
    required this.onResend,
    required this.onToggleSize,
  });

  final ApiResponse response;
  final bool full;
  final VoidCallback onResend;
  final VoidCallback onToggleSize;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Row(
      spacing: Space.sm,
      children: <Widget>[
        StatusChip.of(response),
        Expanded(
          child: Text(
            '${Fmt.duration(response.durationMs)} · '
            '${Fmt.bytes(response.sizeBytes)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.monoTabular.copyWith(color: c.onSurfaceVariant),
          ),
        ),
        AppIconButton(
          icon: Icons.refresh_rounded,
          onPressed: onResend,
          semanticLabel: 'Send again',
        ),
        AppIconButton(
          icon: full
              ? Icons.close_fullscreen_rounded
              : Icons.open_in_full_rounded,
          onPressed: onToggleSize,
          semanticLabel: full ? 'Shrink the response' : 'Expand the response',
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Space.screen,
      Space.sm,
      Space.screen,
      Space.screen,
    ),
    child: Text(
      text,
      style: AppType.body.copyWith(color: context.colors.onSurfaceVariant),
    ),
  );
}

/// The skeleton the response area shows only if a send runs long enough to
/// warrant one.
class ResponseSkeleton extends StatelessWidget {
  const ResponseSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Delayed(
    child: RowGroup(
      children: <Widget>[
        SkeletonRow(),
        SkeletonRow(titleFactor: 0.45, subtitleFactor: 0.7),
      ],
    ),
  );
}
