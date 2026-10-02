import 'package:flutter/material.dart';

import '../../core/models/http_method.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/section_header.dart';

/// Board 2.9. The five everyday methods come first, then the rest. Each keeps
/// its colour, with its one-line explanation next to it.
Future<HttpMethod?> showMethodSheet(
  BuildContext context, {
  required HttpMethod current,
}) => showAppSheet<HttpMethod>(
  context: context,
  title: 'Method',
  note: '${HttpMethod.values.length} methods',
  builder: (BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 14,
    children: <Widget>[
      const SectionHeader(label: 'Common'),
      _MethodGroup(methods: HttpMethod.common, current: current),
      const Padding(
        padding: EdgeInsets.only(top: Space.xs),
        child: SectionHeader(label: 'Less common'),
      ),
      _MethodGroup(methods: HttpMethod.lessCommon, current: current),
    ],
  ),
);

class _MethodGroup extends StatelessWidget {
  const _MethodGroup({required this.methods, required this.current});

  final List<HttpMethod> methods;
  final HttpMethod current;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return RowGroup(
      onSurface: true,
      children: <Widget>[
        for (final HttpMethod m in methods)
          Semantics(
            button: true,
            selected: m == current,
            label: '${m.label}, ${m.blurb}',
            child: InkWell(
              // The Android click sound belongs to the system, not to a tool.
              enableFeedback: false,
              onTap: () => Navigator.of(context).pop(m),
              child: Container(
                color: m == current ? c.primaryContainer : null,
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.only(left: Space.md, right: Space.sm),
                child: Row(
                  spacing: Space.md,
                  children: <Widget>[
                    MethodChip.large(m),
                    Expanded(
                      child: Text(
                        m.blurb,
                        style: AppType.bodyMedium.copyWith(
                          color: m == current
                              ? c.onPrimaryContainer
                              : c.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (m == current)
                      Icon(
                        Icons.check_rounded,
                        size: IconSpec.size,
                        color: c.onPrimaryContainer,
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
