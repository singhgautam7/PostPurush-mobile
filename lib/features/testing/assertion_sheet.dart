import 'package:flutter/material.dart';

import '../../core/models/api_request.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/ids.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/section_header.dart';

/// One assertion: what to look at, how to compare, and what to expect.
Future<Assertion?> showAssertionSheet(
  BuildContext context, {
  Assertion? initial,
}) => showAppSheet<Assertion>(
  context: context,
  title: initial == null ? 'New assertion' : 'Edit assertion',
  subtitle: 'saved with the request',
  builder: (BuildContext context) => _AssertionForm(initial: initial),
);

class _AssertionForm extends StatefulWidget {
  const _AssertionForm({required this.initial});

  final Assertion? initial;

  @override
  State<_AssertionForm> createState() => _AssertionFormState();
}

class _AssertionFormState extends State<_AssertionForm> {
  late AssertTarget _target = widget.initial?.target ?? AssertTarget.status;
  late AssertComparator _comparator =
      widget.initial?.comparator ?? AssertComparator.equals;
  late final TextEditingController _subject = TextEditingController(
    text: widget.initial?.subject ?? '',
  );
  late final TextEditingController _expected = TextEditingController(
    text: widget.initial?.expected ?? '',
  );

  @override
  void dispose() {
    _subject.dispose();
    _expected.dispose();
    super.dispose();
  }

  /// Only the comparators that make sense for the target. Offering "under" for
  /// a header name would be a trap.
  List<AssertComparator> get _options => switch (_target) {
    AssertTarget.status => const <AssertComparator>[
      AssertComparator.equals,
      AssertComparator.notEquals,
      AssertComparator.under,
      AssertComparator.over,
    ],
    AssertTarget.responseTime => const <AssertComparator>[
      AssertComparator.under,
      AssertComparator.over,
    ],
    AssertTarget.header => const <AssertComparator>[
      AssertComparator.contains,
      AssertComparator.equals,
      AssertComparator.notContains,
      AssertComparator.exists,
    ],
    AssertTarget.body => const <AssertComparator>[
      AssertComparator.contains,
      AssertComparator.notContains,
      AssertComparator.equals,
    ],
    AssertTarget.jsonPath => const <AssertComparator>[
      AssertComparator.equals,
      AssertComparator.notEquals,
      AssertComparator.contains,
      AssertComparator.exists,
    ],
  };

  void _setTarget(AssertTarget target) => setState(() {
    _target = target;
    if (!_options.contains(_comparator)) _comparator = _options.first;
    if (!target.hasSubject) _subject.clear();
  });

  void _submit() {
    final String expected = _expected.text.trim();
    if (_comparator != AssertComparator.exists && expected.isEmpty) return;
    if (_target.hasSubject && _subject.text.trim().isEmpty) return;
    Navigator.of(context).pop(
      (widget.initial ?? Assertion(id: newId())).copyWith(
        target: _target,
        comparator: _comparator,
        subject: _subject.text.trim(),
        expected: expected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool needsExpected = _comparator != AssertComparator.exists;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: <Widget>[
        const SectionHeader(label: 'Check'),
        RowGroup(
          onSurface: true,
          children: <Widget>[
            for (final AssertTarget target in AssertTarget.values)
              AppRow(
                title: target.label,
                minHeight: 52,
                selected: _target == target,
                trailing: SizedBox(
                  width: IconSpec.tapTarget,
                  height: IconSpec.tapTarget,
                  child: Center(
                    child: Icon(
                      _target == target
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: IconSpec.size,
                    ),
                  ),
                ),
                onTap: () => _setTarget(target),
              ),
          ],
        ),
        if (_target.hasSubject)
          LabelledField(
            label: _target == AssertTarget.header ? 'Header name' : 'JSON path',
            controller: _subject,
            hint: _target == AssertTarget.header
                ? 'Content-Type'
                : r'$.userId',
            mono: true,
            onSurface: true,
            autofocus: true,
          ),
        const SectionHeader(label: 'Compare'),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: <Widget>[
            for (final AssertComparator option in _options)
              PillChip(
                label: option.label,
                selected: _comparator == option,
                onTap: () => setState(() => _comparator = option),
              ),
          ],
        ),
        if (needsExpected)
          LabelledField(
            label: _target == AssertTarget.responseTime
                ? 'Milliseconds'
                : 'Expected',
            controller: _expected,
            hint: switch (_target) {
              AssertTarget.status => '201',
              AssertTarget.responseTime => '500',
              AssertTarget.header => 'application/json',
              AssertTarget.body => '"Test post"',
              AssertTarget.jsonPath => '42',
            },
            mono: true,
            onSurface: true,
            keyboardType: _target == AssertTarget.responseTime ||
                    _target == AssertTarget.status
                ? TextInputType.number
                : null,
            onSubmitted: (_) => _submit(),
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
                label: widget.initial == null ? 'Add' : 'Save',
                icon: Icons.check_rounded,
                fullWidth: true,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
