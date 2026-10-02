import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/http/variable_resolver.dart';
import '../../core/models/environment.dart';
import '../../core/models/key_value.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';

/// What a partially typed `{{prefix` is asking for.
class VariableQuery {
  const VariableQuery({
    required this.start,
    required this.prefix,
  });

  /// Offset of the opening `{{`.
  final int start;

  /// What has been typed after it.
  final String prefix;

  /// The unclosed `{{…` immediately before the caret, if there is one.
  ///
  /// Only an unclosed one counts: once the braces are closed the variable is
  /// finished and the suggestions have nothing to add.
  static VariableQuery? at(TextEditingValue value) {
    final int caret = value.selection.baseOffset;
    if (caret < 2 || !value.selection.isCollapsed) return null;
    final String head = value.text.substring(0, caret);
    final int open = head.lastIndexOf('{{');
    if (open < 0) return null;
    final String after = head.substring(open + 2);
    // A `}` or a space closes it, and neither belongs in a name.
    if (after.contains('}') || after.contains(' ')) return null;
    return VariableQuery(start: open, prefix: after);
  }
}

/// Board 2.6. The strip above the keyboard: the variables the active
/// environment offers for what is being typed, then the characters that are
/// hard to reach on a phone keyboard.
///
/// It stands in for the dock while the keyboard is up, which is what the board
/// draws and what keeps a small screen readable.
class KeyboardStrip extends StatelessWidget {
  const KeyboardStrip({
    required this.controller,
    required this.env,
    required this.onCreateVariable,
    super.key,
  });

  final TextEditingController controller;
  final Environment? env;

  /// Offered when what is being typed is not a variable the environment holds.
  final ValueChanged<String> onCreateVariable;

  /// The characters the board puts on the strip, in its order.
  static const List<String> keys = <String>['/', '?', '&', '=', ':', '"'];

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (BuildContext context, TextEditingValue value, Widget? _) {
        final VariableQuery? query = VariableQuery.at(value);
        final List<KeyValueRow> matches = query == null
            ? const <KeyValueRow>[]
            : <KeyValueRow>[
                for (final KeyValueRow v in env?.variables ?? const <KeyValueRow>[])
                  if (v.enabled &&
                      v.key.toLowerCase().startsWith(query.prefix.toLowerCase()))
                    v,
              ];

        return Container(
          decoration: BoxDecoration(
            color: c.surfaceContainer,
            border: Border(top: BorderSide(color: c.outline)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (query != null)
                _Suggestions(
                  query: query,
                  matches: matches,
                  env: env,
                  onPick: (KeyValueRow row) => _complete(query, row),
                  onCreate: () => onCreateVariable(query.prefix),
                ),
              _Keys(onInsert: _insert),
            ],
          ),
        );
      },
    );
  }

  /// Replaces the half-typed `{{prefix` with the whole `{{name}}` and puts the
  /// caret after it.
  void _complete(VariableQuery query, KeyValueRow row) {
    final String text = controller.text;
    final int caret = controller.selection.baseOffset;
    final String replacement = '{{${row.key}}}';
    final String next =
        text.substring(0, query.start) + replacement + text.substring(caret);
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(
        offset: query.start + replacement.length,
      ),
    );
  }

  /// Inserts at the caret, replacing any selection, and leaves the caret after
  /// what was inserted. `{{ }}` puts the caret between the braces.
  void _insert(String token) {
    final TextEditingValue value = controller.value;
    final TextSelection selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final bool braces = token == '{{}}';
    final String insert = braces ? '{{}}' : token;
    final String next = value.text.replaceRange(
      selection.start,
      selection.end,
      insert,
    );
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(
        offset: selection.start + (braces ? 2 : insert.length),
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({
    required this.query,
    required this.matches,
    required this.env,
    required this.onPick,
    required this.onCreate,
  });

  final VariableQuery query;
  final List<KeyValueRow> matches;
  final Environment? env;
  final ValueChanged<KeyValueRow> onPick;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.screen, Space.sm, Space.screen, 6),
          child: Text(
            env == null
                ? 'No environment'
                : '${env!.name} · ${matches.length} '
                    '${matches.length == 1 ? 'match' : 'match'}',
            style: AppType.monoLabel.copyWith(color: c.onSurfaceVariant),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 132),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: <Widget>[
              for (final KeyValueRow row in matches)
                _SuggestionRow(
                  row: row,
                  prefix: query.prefix,
                  onTap: () => onPick(row),
                ),
              if (query.prefix.isNotEmpty && env != null)
                InkWell(
                  // The Android click sound belongs to the system, not to a tool.
                  enableFeedback: false,
                  onTap: onCreate,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.screen,
                      vertical: Space.md,
                    ),
                    child: Row(
                      spacing: Space.sm,
                      children: <Widget>[
                        Icon(
                          Icons.add_rounded,
                          size: IconSpec.small,
                          color: c.accent,
                        ),
                        Expanded(
                          child: Text(
                            'Create "${query.prefix}" in ${env!.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.titleMedium.copyWith(
                              color: c.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Divider(color: c.divider, height: 1),
      ],
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.row,
    required this.prefix,
    required this.onTap,
  });

  final KeyValueRow row;
  final String prefix;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    // The typed prefix is shown quiet and the rest in full, so you can see what
    // you are about to accept. A secret's value is never shown here.
    return InkWell(
      // The Android click sound belongs to the system, not to a tool.
      enableFeedback: false,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.screen,
          vertical: Space.row,
        ),
        child: Row(
          spacing: Space.md,
          children: <Widget>[
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: row.key.substring(
                        0,
                        prefix.length.clamp(0, row.key.length),
                      ),
                      style: TextStyle(color: c.onSurfaceMuted),
                    ),
                    TextSpan(
                      text: row.key.substring(
                        prefix.length.clamp(0, row.key.length),
                      ),
                      style: TextStyle(color: c.onSurface),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.monoTabular.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (row.secret)
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: <Widget>[
                  Text(
                    '${VariableResolver.mask(row.value)} secret',
                    style: AppType.monoLabel.copyWith(
                      color: c.onSurfaceVariant,
                    ),
                  ),
                  Icon(
                    Icons.lock_rounded,
                    size: 14,
                    color: c.iconMuted,
                  ),
                ],
              )
            else
              Flexible(
                child: Text(
                  row.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppType.monoLabel.copyWith(
                    color: c.onSurfaceVariant,
                  ),
                ),
              ),
            Icon(
              Icons.keyboard_return_rounded,
              size: 16,
              color: c.iconMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _Keys extends StatelessWidget {
  const _Keys({required this.onInsert});

  final ValueChanged<String> onInsert;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.md),
        children: <Widget>[
          _Key(
            label: '{{ }}',
            wide: true,
            onTap: () => onInsert('{{}}'),
          ),
          for (final String key in KeyboardStrip.keys)
            _Key(label: key, onTap: () => onInsert(key)),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: Space.sm, right: Space.xs),
              child: Semantics(
                button: true,
                label: 'Hide the keyboard',
                child: InkWell(
                  // The Android click sound belongs to the system, not to a tool.
                  enableFeedback: false,
                  onTap: () =>
                      SystemChannels.textInput.invokeMethod<void>('TextInput.hide'),
                  borderRadius: Radii.fullR,
                  child: Padding(
                    padding: const EdgeInsets.all(Space.sm),
                    child: Icon(
                      Icons.keyboard_hide_rounded,
                      size: IconSpec.small,
                      color: c.iconMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap, this.wide = false});

  final String label;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.xs),
        child: Semantics(
          button: true,
          label: 'Insert $label',
          child: Material(
            color: c.surfaceContainerHigh,
            borderRadius: Radii.thumbR,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              // The Android click sound belongs to the system, not to a tool.
              enableFeedback: false,
              onTap: onTap,
              child: SizedBox(
                width: wide ? 64 : 44,
                height: 40,
                child: Center(
                  child: Text(
                    label,
                    style: AppType.monoTabular.copyWith(
                      color: c.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
