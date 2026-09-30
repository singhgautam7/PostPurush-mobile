import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/models/http_method.dart';
import '../../core/models/key_value.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/util/ids.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/states.dart';

/// Board 4.6. The type decides how the value is inserted into a body, and the
/// value field validates against it. Marking it secret masks the value and
/// keeps it out of exports.
///
/// The board draws this in place on the variables page. It is a sheet here
/// because the workspace's "Add it" needs the same form, and one
/// implementation used in both places beats two that drift apart.
Future<KeyValueRow?> showVariableSheet(
  BuildContext context, {
  required String environmentName,
  KeyValueRow? initial,
}) => showAppSheet<KeyValueRow>(
  context: context,
  title: initial == null || initial.key.isEmpty
      ? 'New variable'
      : 'Edit ${initial.key}',
  subtitle: 'in $environmentName · use as {{name}}',
  builder: (BuildContext context) => _VariableForm(initial: initial),
);

class _VariableForm extends StatefulWidget {
  const _VariableForm({required this.initial});

  final KeyValueRow? initial;

  @override
  State<_VariableForm> createState() => _VariableFormState();
}

class _VariableFormState extends State<_VariableForm> {
  late final TextEditingController _key = TextEditingController(
    text: widget.initial?.key ?? '',
  );
  late final TextEditingController _value = TextEditingController(
    text: widget.initial?.value ?? '',
  );
  late VarType _type = widget.initial?.type ?? VarType.string;
  late bool _secret = widget.initial?.secret ?? false;

  @override
  void initState() {
    super.initState();
    _value.addListener(_revalidate);
  }

  @override
  void dispose() {
    _key.dispose();
    _value
      ..removeListener(_revalidate)
      ..dispose();
    super.dispose();
  }

  void _revalidate() => setState(() {});

  /// The value field validates against the type, because a number variable
  /// that holds `forty two` will fail at the server, not here.
  String? get _error {
    final String text = _value.text.trim();
    if (text.isEmpty) return null;
    switch (_type) {
      case VarType.string:
        return null;
      case VarType.number:
        return double.tryParse(text) == null ? 'Not a number' : null;
      case VarType.boolean:
        return text == 'true' || text == 'false'
            ? null
            : 'Use true or false';
      case VarType.json:
        try {
          jsonDecode(text);
          return null;
        } on FormatException {
          return 'Not valid JSON';
        }
    }
  }

  void _submit() {
    final String key = _key.text.trim();
    if (key.isEmpty || _error != null) return;
    Navigator.of(context).pop(
      (widget.initial ?? KeyValueRow(id: newId())).copyWith(
        key: key,
        value: _value.text,
        type: _type,
        secret: _secret,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final String? error = _error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: <Widget>[
        LabelledField(
          label: 'Name',
          controller: _key,
          hint: 'apiKey',
          mono: true,
          autofocus: true,
          onSurface: true,
          onChanged: (_) => setState(() {}),
        ),
        Row(
          spacing: Space.sm,
          children: <Widget>[
            for (final VarType type in VarType.values)
              PillChip(
                label: type.label,
                selected: _type == type,
                showCheck: true,
                onTap: () => setState(() => _type = type),
              ),
          ],
        ),
        LabelledField(
          label: 'Value',
          controller: _value,
          mono: true,
          onSurface: true,
          onSubmitted: (_) => _submit(),
        ),
        if (error != null)
          InlineError(icon: Icons.data_object_rounded, message: error),
        SwitchRow(
          label: 'Secret',
          note: 'masked, left out of exports',
          icon: Icons.lock_outline_rounded,
          value: _secret,
          onChanged: (bool value) => setState(() => _secret = value),
        ),
        Text(
          'To add several at once, use Paste lines from the page menu.',
          style: AppType.bodySmall.copyWith(color: c.onSurfaceVariant),
        ),
        Row(
          spacing: Space.row,
          children: <Widget>[
            Expanded(
              child: AppButton(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
                type: AppButtonType.outlined,
                fullWidth: true,
              ),
            ),
            Expanded(
              flex: 2,
              child: AppButton(
                label: widget.initial?.key.isNotEmpty ?? false ? 'Save' : 'Add',
                icon: Icons.check_rounded,
                fullWidth: true,
                onPressed: _key.text.trim().isEmpty || error != null
                    ? null
                    : _submit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Board 4.6's bulk paste, as its own action on the variables page.
List<KeyValueRow> parseVariableLines(String text) {
  final List<KeyValueRow> rows = <KeyValueRow>[];
  for (final String line in text.split('\n')) {
    final String trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final int split = trimmed.contains('=')
        ? trimmed.indexOf('=')
        : trimmed.indexOf(':');
    if (split <= 0) continue;
    final String value = trimmed.substring(split + 1).trim();
    rows.add(
      KeyValueRow(
        id: newId(),
        key: trimmed.substring(0, split).trim(),
        // A quoted .env value is quoted for the shell, not for the server.
        value: _unquote(value),
      ),
    );
  }
  return rows;
}

String _unquote(String value) =>
    value.length >= 2 &&
            ((value.startsWith('"') && value.endsWith('"')) ||
                (value.startsWith("'") && value.endsWith("'")))
        ? value.substring(1, value.length - 1)
        : value;
