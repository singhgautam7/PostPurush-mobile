import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/environment.dart';
import '../theme/app_theme.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'variable_text.dart';

/// One rendered line of code: its number, its spans, and whether it opens a
/// node that can be folded.
class CodeLine {
  const CodeLine({
    required this.number,
    required this.spans,
    this.foldPath,
    this.folded = false,
    this.text = '',
  });

  final int number;
  final List<InlineSpan> spans;

  /// The path of the node this line opens, or null when it opens nothing.
  /// Tapping the line toggles that path.
  final String? foldPath;
  final bool folded;

  /// The plain text of the line, for copy.
  final String text;
}

/// Turns a JSON document into foldable, coloured lines.
///
/// Built from the decoded value rather than from the raw text, which is what
/// makes "{ 3 keys }" possible: a folded node knows how many children it has
/// and how many line numbers to skip.
class JsonOutline {
  JsonOutline._(this.lines, this.valid, this.raw);

  /// Null [folded] folds nothing.
  factory JsonOutline.of(
    String source, {
    required AppColors colors,
    required TextStyle base,
    Set<String> folded = const <String>{},
    Environment? env,
  }) {
    final Object? root = _tryDecode(source);
    if (root == null) {
      return JsonOutline._(
        _plainLines(source, colors: colors, base: base, env: env),
        false,
        source,
      );
    }
    final _Emitter emitter = _Emitter(
      colors: colors,
      base: base,
      folded: folded,
      env: env,
    );
    emitter.value(root, path: r'$', indent: 0, suffix: '');
    return JsonOutline._(emitter.lines, true, source);
  }

  final List<CodeLine> lines;

  /// False when the body is not JSON, so the viewer offers Raw rather than
  /// Pretty and never claims to have parsed something it did not.
  final bool valid;
  final String raw;

  static Object? _tryDecode(String source) {
    if (source.trim().isEmpty) return null;
    try {
      return jsonDecode(source);
    } on FormatException {
      return null;
    }
  }

  static List<CodeLine> _plainLines(
    String source, {
    required AppColors colors,
    required TextStyle base,
    Environment? env,
  }) {
    final List<String> raw = const LineSplitter().convert(source);
    return <CodeLine>[
      for (int i = 0; i < raw.length; i++)
        CodeLine(
          number: i + 1,
          text: raw[i],
          spans: VariableText.spans(
            text: raw[i],
            env: env,
            colors: colors,
            base: base.copyWith(color: colors.onSurface),
          ),
        ),
    ];
  }
}

class _Emitter {
  _Emitter({
    required this.colors,
    required this.base,
    required this.folded,
    this.env,
  });

  final AppColors colors;
  final TextStyle base;
  final Set<String> folded;
  final Environment? env;

  final List<CodeLine> lines = <CodeLine>[];

  /// Line numbers keep counting through a folded node, so the numbers jump
  /// exactly as the board shows (5 then 9).
  int _number = 1;

  static const String _indentUnit = '  ';

  TextStyle get _punc => base.copyWith(color: colors.synPunctuation);

  /// Emits [value], which may be a scalar, a map or a list.
  void value(
    Object? value,
    {
    required String path,
    required int indent,
    required String suffix,
    String? key,
  }) {
    final String pad = _indentUnit * indent;
    final List<InlineSpan> head = <InlineSpan>[
      TextSpan(text: pad, style: _punc),
      if (key != null) ...<InlineSpan>[
        TextSpan(text: '"$key"', style: base.copyWith(color: colors.synKey)),
        TextSpan(text: ': ', style: _punc),
      ],
    ];

    if (value is Map<String, dynamic>) {
      _container(
        open: '{',
        close: '}',
        summary: _plural(value.length, 'key'),
        head: head,
        path: path,
        indent: indent,
        suffix: suffix,
        children: () {
          final List<String> keys = value.keys.toList();
          for (int i = 0; i < keys.length; i++) {
            this.value(
              value[keys[i]],
              key: keys[i],
              path: '$path.${keys[i]}',
              indent: indent + 1,
              suffix: i == keys.length - 1 ? '' : ',',
            );
          }
        },
      );
      return;
    }
    if (value is List<Object?>) {
      _container(
        open: '[',
        close: ']',
        summary: _plural(value.length, 'item'),
        head: head,
        path: path,
        indent: indent,
        suffix: suffix,
        children: () {
          for (int i = 0; i < value.length; i++) {
            this.value(
              value[i],
              path: '$path[$i]',
              indent: indent + 1,
              suffix: i == value.length - 1 ? '' : ',',
            );
          }
        },
      );
      return;
    }

    lines.add(
      CodeLine(
        number: _number++,
        text: '$pad${key == null ? '' : '"$key": '}${_scalarText(value)}$suffix',
        spans: <InlineSpan>[
          ...head,
          ..._scalarSpans(value),
          if (suffix.isNotEmpty) TextSpan(text: suffix, style: _punc),
        ],
      ),
    );
  }

  void _container({
    required String open,
    required String close,
    required String summary,
    required List<InlineSpan> head,
    required String path,
    required int indent,
    required String suffix,
    required void Function() children,
  }) {
    final bool isFolded = folded.contains(path);
    lines.add(
      CodeLine(
        number: _number++,
        foldPath: path,
        folded: isFolded,
        text: '${_indentUnit * indent}$open',
        spans: <InlineSpan>[
          ...head,
          if (!isFolded) TextSpan(text: open, style: _punc),
          if (isFolded) ...<InlineSpan>[
            // The board draws a folded node's summary as a small tinted chip,
            // so it reads as a placeholder rather than as more code.
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: Radii.chipR,
                ),
                child: Text(
                  '$open $summary $close',
                  style: base.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ),
            if (suffix.isNotEmpty) TextSpan(text: suffix, style: _punc),
          ],
        ],
      ),
    );
    if (isFolded) {
      // Count the lines the fold hides so the next number is still right.
      _number += _countLines(summary);
      return;
    }
    children();
    lines.add(
      CodeLine(
        number: _number++,
        text: '${_indentUnit * indent}$close$suffix',
        spans: <InlineSpan>[
          TextSpan(text: _indentUnit * indent, style: _punc),
          TextSpan(text: close, style: _punc),
          if (suffix.isNotEmpty) TextSpan(text: suffix, style: _punc),
        ],
      ),
    );
  }

  /// A folded node hides its children and its closing brace. The child count
  /// is in the summary, which is where it was already computed.
  int _countLines(String summary) {
    final int? n = int.tryParse(summary.split(' ').first);
    return n == null ? 1 : n + 1;
  }

  static String _plural(int n, String noun) =>
      '$n ${n == 1 ? noun : '${noun}s'}';

  List<InlineSpan> _scalarSpans(Object? value) {
    if (value is String) {
      // A string value can hold a variable, and it should read as one.
      final String quoted = jsonEncode(value);
      return VariableText.spans(
        text: quoted,
        env: env,
        colors: colors,
        base: base.copyWith(color: colors.synString),
      );
    }
    if (value is num) {
      return <InlineSpan>[
        TextSpan(text: '$value', style: base.copyWith(color: colors.synNumber)),
      ];
    }
    return <InlineSpan>[
      TextSpan(
        text: value == null ? 'null' : '$value',
        style: base.copyWith(color: colors.synLiteral),
      ),
    ];
  }

  static String _scalarText(Object? value) =>
      value is String ? jsonEncode(value) : '$value';
}

/// The response body and the request body editor's preview: line numbers in a
/// 40dp gutter, coloured spans, and a tap to fold a node.
///
/// The list is virtualised. A 5 MB response is thousands of lines, and
/// building them all as widgets is the difference between a scroll and a
/// stutter.
class CodeView extends StatefulWidget {
  const CodeView({
    required this.source,
    this.env,
    this.wrap = false,
    this.foldable = true,
    this.padding = const EdgeInsets.symmetric(vertical: Space.md),
    this.maxLines,
    super.key,
  });

  final String source;
  final Environment? env;

  /// Soft-wrap long lines instead of scrolling sideways, which is what the
  /// board's `wrap_text` toggle does on an error body.
  final bool wrap;
  final bool foldable;
  final EdgeInsetsGeometry padding;

  /// Caps the rendered lines, for the docs' example blocks.
  final int? maxLines;

  @override
  State<CodeView> createState() => _CodeViewState();
}

class _CodeViewState extends State<CodeView> {
  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: <Widget>[
      SliverPadding(
        padding: widget.padding,
        sliver: SliverCodeView(
          source: widget.source,
          env: widget.env,
          wrap: widget.wrap,
          foldable: widget.foldable,
          maxLines: widget.maxLines,
        ),
      ),
    ],
  );
}

/// The same lines as a sliver, so a code body can share one scroll view with
/// whatever sits above it. That is what lets the response sheet be a real
/// draggable sheet: the drag and the body scroll have to be one gesture.
class SliverCodeView extends StatefulWidget {
  const SliverCodeView({
    required this.source,
    this.env,
    this.wrap = false,
    this.foldable = true,
    this.maxLines,
    super.key,
  });

  final String source;
  final Environment? env;
  final bool wrap;
  final bool foldable;
  final int? maxLines;

  @override
  State<SliverCodeView> createState() => _SliverCodeViewState();
}

class _SliverCodeViewState extends State<SliverCodeView> {
  final Set<String> _folded = <String>{};

  /// One controller shared by every line, so the whole block scrolls sideways
  /// as one sheet of text. A controller per line made each line scroll on its
  /// own, which is unreadable. Sharing works because nothing here reads a
  /// single-position getter off it.
  final ScrollController _sideways = ScrollController();

  @override
  void dispose() {
    _sideways.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SliverCodeView old) {
    super.didUpdateWidget(old);
    // A new body is a new document; keeping the old fold state would collapse
    // nodes that have nothing to do with it.
    if (old.source != widget.source) _folded.clear();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final TextStyle base = AppType.monoCode;
    final JsonOutline outline = JsonOutline.of(
      widget.source,
      colors: c,
      base: base,
      folded: widget.foldable ? _folded : const <String>{},
      env: widget.env,
    );
    final List<CodeLine> lines = widget.maxLines == null
        ? outline.lines
        : outline.lines.take(widget.maxLines!).toList(growable: false);

    // A builder, because a large response is thousands of lines and only the
    // visible ones should ever become widgets.
    return SliverList.builder(
      itemCount: lines.length,
      itemBuilder: (BuildContext context, int i) => _Line(
        line: lines[i],
        wrap: widget.wrap,
        sideways: _sideways,
        onToggleFold: widget.foldable
            ? (String path) => setState(
                () => _folded.contains(path)
                    ? _folded.remove(path)
                    : _folded.add(path),
              )
            : null,
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.line,
    required this.wrap,
    this.sideways,
    this.onToggleFold,
  });

  final CodeLine line;
  final bool wrap;

  /// Shared with every other line, so they move together.
  final ScrollController? sideways;
  final void Function(String path)? onToggleFold;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final bool canFold = line.foldPath != null && onToggleFold != null;
    // 32dp for the number, 20dp for the fold caret: the board's own gutter.
    final Widget gutter = Row(
      children: <Widget>[
        SizedBox(
          width: 32,
          child: Text(
            '${line.number}',
            textAlign: TextAlign.right,
            style: AppType.monoCode.copyWith(color: c.onSurfaceMuted),
          ),
        ),
        SizedBox(
          width: 20,
          child: canFold
              ? Icon(
                  line.folded
                      ? Icons.chevron_right_rounded
                      : Icons.expand_more_rounded,
                  size: 16,
                  color: c.iconMuted,
                )
              : null,
        ),
      ],
    );

    final Widget text = Text.rich(
      TextSpan(children: line.spans),
      softWrap: wrap,
      overflow: wrap ? TextOverflow.clip : TextOverflow.clip,
    );

    final Widget row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        gutter,
        Expanded(
          child: wrap
              ? text
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: sideways,
                  // Only one line needs to drive the gesture; the rest follow
                  // it through the shared controller.
                  physics: const ClampingScrollPhysics(),
                  child: text,
                ),
        ),
      ],
    );

    if (!canFold) return row;
    return InkWell(
      onTap: () => onToggleFold!(line.foldPath!),
      child: row,
    );
  }
}

/// A short, non-scrolling code block: the export sheet's snippet, a doc's
/// example request or response.
class CodeBlock extends StatelessWidget {
  const CodeBlock({
    required this.source,
    this.env,
    this.onSurface = false,
    this.showLineNumbers = false,
    super.key,
  });

  final String source;
  final Environment? env;

  /// True inside a sheet, where the sheet already owns `surfaceContainer`.
  final bool onSurface;
  final bool showLineNumbers;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final TextStyle base = AppType.monoCode;
    final JsonOutline outline = JsonOutline.of(
      source,
      colors: c,
      base: base,
      env: env,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
      decoration: BoxDecoration(
        color: onSurface ? c.surface : c.surfaceContainer,
        borderRadius: Radii.cardR,
        border: Border.all(color: c.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final CodeLine line in outline.lines)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (showLineNumbers)
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${line.number}',
                      textAlign: TextAlign.right,
                      style: base.copyWith(color: c.onSurfaceMuted),
                    ),
                  ),
                if (showLineNumbers) const SizedBox(width: Space.md),
                Expanded(child: Text.rich(TextSpan(children: line.spans))),
              ],
            ),
        ],
      ),
    );
  }
}

/// Copies [text] and says so.
Future<void> copyToClipboard(String text) =>
    Clipboard.setData(ClipboardData(text: text));
