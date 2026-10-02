import 'package:flutter/material.dart';

import '../models/environment.dart';
import '../models/http_method.dart';
import '../theme/app_theme.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'chips.dart';
import 'variable_text.dart';

/// The method chip in the URL bar: 36dp, its own hue, with the caret that
/// opens the method sheet.
class MethodPicker extends StatelessWidget {
  const MethodPicker({required this.method, required this.onTap, super.key});

  final HttpMethod method;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Semantics(
      button: true,
      label: 'Method, ${method.label}',
      child: Material(
        color: c.methodBg(method),
        borderRadius: Radii.chipR,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // The Android click sound belongs to the system, not to a tool.
          enableFeedback: false,
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.only(left: Space.md, right: Space.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  method.label,
                  style: AppType.monoTabular.copyWith(
                    color: c.methodFg(method),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: IconSpec.small,
                  color: c.methodFg(method),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The URL bar: a method chip and a wrapping mono field whose variables are
/// checked against the active environment as you type.
class UrlBar extends StatefulWidget {
  const UrlBar({
    required this.controller,
    required this.method,
    required this.onMethodTap,
    required this.env,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    super.key,
  });

  final VariableEditingController controller;
  final HttpMethod method;
  final VoidCallback onMethodTap;
  final Environment? env;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;

  @override
  State<UrlBar> createState() => _UrlBarState();
}

class _UrlBarState extends State<UrlBar> {
  FocusNode? _owned;
  FocusNode get _focus => widget.focusNode ?? (_owned ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _owned?.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final bool focused = _focus.hasFocus;
    // Highlighting depends on the environment and on the palette, so the
    // controller is retold both whenever either can have changed.
    widget.controller.retheme(environment: widget.env, palette: c);

    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: c.surfaceContainer,
        borderRadius: Radii.cardR,
        border: Border.all(
          color: focused ? c.primary : c.outline,
          width: focused ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Space.md,
        children: <Widget>[
          MethodPicker(method: widget.method, onTap: widget.onMethodTap),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: _WelledField(
                controller: widget.controller,
                focusNode: _focus,
                env: widget.env,
                colors: c,
                readOnly: widget.readOnly,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The field itself, with the variable wells painted behind the glyphs. The
/// field is multi-line and never scrolls, so the painter's own layout matches
/// the field's exactly.
class _WelledField extends StatelessWidget {
  const _WelledField({
    required this.controller,
    required this.focusNode,
    required this.env,
    required this.colors,
    required this.readOnly,
    this.onChanged,
    this.onSubmitted,
  });

  final VariableEditingController controller;
  final FocusNode focusNode;
  final Environment? env;
  final AppColors colors;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppType.monoBody.copyWith(color: colors.onSurface);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (BuildContext context, TextEditingValue value, Widget? _) {
        final List<VariableWell> wells = VariableText.wells(
          text: value.text,
          env: env,
          colors: colors,
        );
        final Widget field = TextField(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly,
          maxLines: null,
          minLines: 1,
          style: style,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          cursorColor: colors.primary,
          cursorWidth: 2,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            hintText: 'Enter a URL or paste cURL',
            hintStyle: style.copyWith(color: colors.onSurfaceMuted),
          ),
        );
        if (wells.isEmpty) return field;
        return CustomPaint(
          painter: VariableWellPainter(
            spans: VariableText.spans(
              text: value.text,
              env: env,
              colors: colors,
              base: style,
            ),
            wells: wells,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          ),
          child: field,
        );
      },
    );
  }
}
