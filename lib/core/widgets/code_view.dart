import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    bool raw = false,
  }) {
    // Raw means the bytes as they came back, so it is never re-indented.
    final Object? root = raw ? null : _tryDecode(source);
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

  /// Whether [source] parses, without building a single span for it.
  ///
  /// The body editor asks this on every keystroke. Building the outline to
  /// find out meant colouring the whole document twice per character.
  static bool isValid(String source) => _tryDecode(source) != null;

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
    Object? value, {
    required String path,
    required int indent,
    required String suffix,
    String? key,
  }) {
    final String pad = _indentUnit * indent;
    final List<InlineSpan> head = <InlineSpan>[
      TextSpan(text: pad, style: _punc),
      if (key != null) ...<InlineSpan>[
        TextSpan(
          text: '"$key"',
          style: base.copyWith(color: colors.synKey),
        ),
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
        text:
            '$pad${key == null ? '' : '"$key": '}${_scalarText(value)}$suffix',
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
        TextSpan(
          text: '$value',
          style: base.copyWith(color: colors.synNumber),
        ),
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
    this.raw = false,
    this.maxLines,
    super.key,
  });

  final String source;
  final Environment? env;
  final bool wrap;
  final bool foldable;

  /// Show the body as it came back, without parsing or re-indenting it.
  final bool raw;
  final int? maxLines;

  @override
  State<SliverCodeView> createState() => _SliverCodeViewState();
}

class _SliverCodeViewState extends State<SliverCodeView> {
  final Set<String> _folded = <String>{};

  /// How far the block is scrolled sideways, shared by every line.
  ///
  /// Not a Scrollable per line: separate Scrollables sharing a controller do
  /// not follow one another, so only the line under the finger moved. One
  /// offset applied through a Transform moves the whole block as one sheet of
  /// text, and the list stays virtualised.
  double _offsetX = 0;
  double _overflowX = 0;

  /// The height of one line, measured from the shared style.
  ///
  /// A line that scrolls sideways is laid out at its full width through an
  /// [OverflowBox], and an OverflowBox takes the biggest size it is offered:
  /// inside a list that is unbounded vertically, so it has to be told how tall
  /// a line is.
  double _lineHeight = 0;

  /// The parsed document, kept until something it was built from changes.
  ///
  /// Parsing and colouring a response is the most expensive thing this widget
  /// does, and it used to happen on every build: once per fold, and once per
  /// frame of a sideways drag. A 200 KB body made that visible.
  JsonOutline? _outline;
  _OutlineKey? _key;

  /// Bumped on a fold, which is the one input the key cannot see by value.
  int _folds = 0;

  /// The width of the longest line, measured with the outline rather than on
  /// every layout pass.
  double _widest = 0;

  void _drag(DragUpdateDetails details) {
    if (_overflowX <= 0) return;
    setState(
      () => _offsetX = (_offsetX - details.delta.dx).clamp(0.0, _overflowX),
    );
  }

  @override
  void didUpdateWidget(SliverCodeView old) {
    super.didUpdateWidget(old);
    // A new body is a new document; keeping the old fold state would collapse
    // nodes that have nothing to do with it.
    if (old.source != widget.source) {
      _folded.clear();
      _offsetX = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final TextStyle base = AppType.monoCode;
    final _OutlineKey key = _OutlineKey(
      source: widget.source,
      raw: widget.raw,
      folds: widget.foldable ? _folds : 0,
      colors: c,
      env: widget.env,
    );
    if (_outline == null || key != _key) {
      _outline = JsonOutline.of(
        widget.source,
        colors: c,
        base: base,
        folded: widget.foldable ? _folded : const <String>{},
        env: widget.env,
        raw: widget.raw,
      );
      _key = key;
      final (double widest, double height) = _measure(_outline!.lines, base);
      _widest = widest;
      _lineHeight = height;
    }
    final JsonOutline outline = _outline!;
    final List<CodeLine> lines = widget.maxLines == null
        ? outline.lines
        : outline.lines.take(widget.maxLines!).toList(growable: false);

    if (widget.wrap) {
      return SliverList.builder(
        itemCount: lines.length,
        itemBuilder: (BuildContext context, int i) =>
            _Line(line: lines[i], wrap: true, onToggleFold: _toggle),
      );
    }

    // How far the widest line runs past the viewport, measured once per build
    // from the longest string rather than by laying every line out.
    return SliverLayoutBuilder(
      builder: (BuildContext context, SliverConstraints constraints) {
        final double available = constraints.crossAxisExtent - _gutter;
        _overflowX = math.max(0, _widest - available);
        if (_offsetX > _overflowX) _offsetX = _overflowX;
        return SliverList.builder(
          itemCount: lines.length,
          itemBuilder: (BuildContext context, int i) => _Line(
            line: lines[i],
            wrap: false,
            offsetX: _offsetX,
            height: _lineHeight,
            onHorizontalDrag: _overflowX > 0 ? _drag : null,
            onToggleFold: _toggle,
          ),
        );
      },
    );
  }

  void Function(String)? get _toggle => widget.foldable ? _toggleFold : null;

  void _toggleFold(String path) => setState(() {
    if (!_folded.remove(path)) _folded.add(path);
    // The key cannot see inside the set, so the version stands in for it.
    _folds++;
  });

  /// The number column plus the fold caret.
  static const double _gutter = 52;

  /// The width of the longest line and the height of any line.
  ///
  /// Measuring the longest string is enough: every line shares one monospaced
  /// style, so the longest string is the widest line and one layout answers
  /// for the whole document.
  (double, double) _measure(List<CodeLine> lines, TextStyle base) {
    String longest = '';
    for (final CodeLine line in lines) {
      if (line.text.length > longest.length) longest = line.text;
    }
    final TextPainter painter = TextPainter(
      text: TextSpan(text: longest.isEmpty ? ' ' : longest, style: base),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final (double, double) out = (painter.width, painter.height);
    painter.dispose();
    return out;
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.line,
    required this.wrap,
    this.offsetX = 0,
    this.height,
    this.onHorizontalDrag,
    this.onToggleFold,
  });

  final CodeLine line;
  final bool wrap;

  /// Shared with every other line, so the block moves as one.
  final double offsetX;

  /// The measured height of one line, which a sideways line needs because it
  /// sizes itself to what it is given rather than to its text.
  final double? height;
  final ValueChanged<DragUpdateDetails>? onHorizontalDrag;
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

    Widget row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        gutter,
        Expanded(
          child: wrap
              ? text
              : ClipRect(
                  child: Transform.translate(
                    offset: Offset(-offsetX, 0),
                    child: OverflowBox(
                      alignment: Alignment.centerLeft,
                      maxWidth: double.infinity,
                      child: text,
                    ),
                  ),
                ),
        ),
      ],
    );
    if (!wrap && height != null) {
      row = SizedBox(height: height, child: row);
    }

    final Widget body = canFold
        ? InkWell(
            enableFeedback: false,
            onTap: () => onToggleFold!(line.foldPath!),
            child: row,
          )
        : row;
    if (onHorizontalDrag == null) return body;
    // The drag is on every line, so wherever the finger lands the whole block
    // moves; the vertical gesture still belongs to the list above.
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: onHorizontalDrag,
      child: body,
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
    this.maxHeight,
    super.key,
  });

  final String source;
  final Environment? env;

  /// True inside a sheet, where the sheet already owns `surfaceContainer`.
  final bool onSurface;
  final bool showLineNumbers;

  /// Caps the block and lets the code scroll inside it, both ways.
  ///
  /// The block owns the scrolling so that its outline stays where it is.
  /// Scrolling the whole block instead took the outline with it, and a
  /// snippet wider than the sheet then looked like it had no boundary at all.
  final double? maxHeight;

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
    final bool scrolls = maxHeight != null;
    final Widget lines = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final CodeLine line in outline.lines)
          Row(
            mainAxisSize: scrolls ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (showLineNumbers) ...<Widget>[
                SizedBox(
                  width: 28,
                  child: Text(
                    '${line.number}',
                    textAlign: TextAlign.right,
                    style: base.copyWith(color: c.onSurfaceMuted),
                  ),
                ),
                const SizedBox(width: Space.md),
              ],
              // Unbounded inside the horizontal scroll, so the line takes the
              // width it needs rather than the width it is given.
              if (scrolls)
                Text.rich(TextSpan(children: line.spans), softWrap: false)
              else
                Expanded(child: Text.rich(TextSpan(children: line.spans))),
            ],
          ),
      ],
    );

    return Container(
      width: scrolls ? null : double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
      decoration: BoxDecoration(
        color: onSurface ? c.surface : c.surfaceContainer,
        borderRadius: Radii.cardR,
        border: Border.all(color: c.outline),
      ),
      child: scrolls
          ? ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight!),
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: lines,
                ),
              ),
            )
          : lines,
    );
  }
}

/// Copies [text] and says so.
Future<void> copyToClipboard(String text) =>
    Clipboard.setData(ClipboardData(text: text));

/// What an outline was built from. Rebuilding it when none of this changed is
/// the difference between a smooth drag and a parse every frame.
class _OutlineKey {
  const _OutlineKey({
    required this.source,
    required this.raw,
    required this.folds,
    required this.colors,
    required this.env,
  });

  final String source;
  final bool raw;
  final int folds;
  final AppColors colors;
  final Environment? env;

  @override
  bool operator ==(Object other) =>
      other is _OutlineKey &&
      other.raw == raw &&
      other.folds == folds &&
      identical(other.colors, colors) &&
      identical(other.env, env) &&
      other.source == source;

  @override
  int get hashCode => Object.hash(source, raw, folds, colors, env);
}
