import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'app_icon_button.dart';

/// A labelled text field: a 12dp label, then a 56dp well that takes a 2dp
/// `primary` border while it is focused (board 2.10).
class LabelledField extends StatefulWidget {
  const LabelledField({
    required this.label,
    required this.controller,
    this.hint,
    this.mono = false,
    this.autofocus = false,
    this.onSubmitted,
    this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
    this.onSurface = false,
    this.trailing,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;

  /// True for anything you would type at a terminal: a key, a value, a path.
  final bool mono;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final int? maxLines;

  /// True inside a sheet, where the well sits on `surface`.
  final bool onSurface;
  final Widget? trailing;

  @override
  State<LabelledField> createState() => _LabelledFieldState();
}

class _LabelledFieldState extends State<LabelledField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final bool focused = _focus.hasFocus;
    final TextStyle style = (widget.mono ? AppType.monoTabular : AppType.body)
        .copyWith(color: c.onSurface);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: Space.xs),
          child: Text(
            widget.label,
            style: AppType.label.copyWith(color: c.onSurfaceVariant),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          decoration: BoxDecoration(
            color: widget.onSurface ? c.surface : c.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(Radii.thumb + 2),
            border: Border.all(
              color: focused ? c.primary : c.outline,
              width: focused ? 2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  style: style,
                  maxLines: widget.maxLines,
                  keyboardType: widget.keyboardType,
                  onSubmitted: widget.onSubmitted,
                  onChanged: widget.onChanged,
                  cursorColor: c.primary,
                  cursorWidth: 2,
                  autocorrect: !widget.mono,
                  enableSuggestions: !widget.mono,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: Space.lg,
                    ),
                    hintText: widget.hint,
                    hintStyle: style.copyWith(color: c.onSurfaceMuted),
                  ),
                ),
              ),
              ?widget.trailing,
            ],
          ),
        ),
      ],
    );
  }
}

/// The pill search field: 52dp, `surfaceContainer`, a leading glyph and a
/// clear button once there is something to clear.
class SearchField extends StatelessWidget {
  const SearchField({
    required this.controller,
    required this.hint,
    this.focusNode,
    this.onChanged,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (BuildContext context, TextEditingValue value, Widget? _) =>
          Container(
            height: 52,
            padding: const EdgeInsets.only(left: 18, right: Space.xs),
            decoration: BoxDecoration(
              color: c.surfaceContainer,
              borderRadius: Radii.fullR,
              border: Border.all(
                color: value.text.isEmpty ? c.outline : c.primary,
                width: value.text.isEmpty ? 1 : 2,
              ),
            ),
            child: Row(
              spacing: Space.md,
              children: <Widget>[
                Icon(
                  Icons.search_rounded,
                  size: IconSpec.size,
                  color: c.iconMuted,
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: autofocus,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    style: AppType.body.copyWith(color: c.onSurface),
                    cursorColor: c.primary,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: hint,
                      hintStyle: AppType.body.copyWith(
                        color: c.onSurfaceMuted,
                      ),
                    ),
                  ),
                ),
                if (value.text.isNotEmpty)
                  AppIconButton(
                    icon: Icons.close_rounded,
                    onPressed: () {
                      controller.clear();
                      onChanged?.call('');
                    },
                    semanticLabel: 'Clear search',
                    filled: false,
                    size: IconSpec.navTarget,
                  ),
              ],
            ),
          ),
    );
  }
}

/// A value with minus and plus, which keeps concurrency and iterations in
/// range without a keyboard (board 11.4).
class StepperRow extends StatelessWidget {
  const StepperRow({
    required this.label,
    required this.note,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    this.step = 1,
    this.suffix = '',
    super.key,
  });

  final String label;

  /// The quiet line under the label: `requests in parallel`.
  final String note;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.row,
      ),
      child: Row(
        spacing: Space.md,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: <Widget>[
                Text(
                  label,
                  style: AppType.titleMedium.copyWith(color: c.onSurface),
                ),
                Text(
                  note,
                  style: AppType.monoLabel.copyWith(color: c.onSurfaceVariant),
                ),
              ],
            ),
          ),
          AppIconButton(
            icon: Icons.remove_rounded,
            onPressed: value > min
                ? () => onChanged((value - step).clamp(min, max))
                : null,
            semanticLabel: 'Decrease $label',
            size: 40,
            glyphSize: IconSpec.small,
          ),
          SizedBox(
            width: 52,
            child: Text(
              '$value$suffix',
              textAlign: TextAlign.center,
              style: AppType.monoTabular.copyWith(
                color: c.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          AppIconButton(
            icon: Icons.add_rounded,
            onPressed: value < max
                ? () => onChanged((value + step).clamp(min, max))
                : null,
            semanticLabel: 'Increase $label',
            size: 40,
            glyphSize: IconSpec.small,
          ),
        ],
      ),
    );
  }
}

/// A row that carries a switch: "Follow redirects", "Verify SSL certificates",
/// "Mask secrets".
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.note,
    this.icon,
    super.key,
  });

  final String label;
  final String? note;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return InkWell(
      // The Android click sound belongs to the system, not to a tool.
      enableFeedback: false,
      onTap: () => onChanged(!value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.only(left: Space.lg, right: Space.md),
        child: Row(
          spacing: 13,
          children: <Widget>[
            if (icon != null)
              Icon(icon, size: IconSpec.small, color: c.icon),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: <Widget>[
                  Text(
                    label,
                    style: AppType.titleMedium.copyWith(color: c.onSurface),
                  ),
                  if (note != null)
                    Text(
                      note!,
                      style: AppType.bodySmall.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
