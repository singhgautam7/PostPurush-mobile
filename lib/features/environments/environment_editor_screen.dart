import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/environment.dart';
import '../../core/providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/ids.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_icon_button.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/states.dart';

/// Board 4.2. Name, icon and colour only. Creating it goes straight to the
/// variables page; editing it keeps Delete at the bottom.
class EnvironmentEditorScreen extends ConsumerStatefulWidget {
  const EnvironmentEditorScreen({this.existing, super.key});

  /// Null for a new environment.
  final Environment? existing;

  @override
  ConsumerState<EnvironmentEditorScreen> createState() =>
      _EnvironmentEditorScreenState();
}

class _EnvironmentEditorScreenState
    extends ConsumerState<EnvironmentEditorScreen> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late EnvIcon _icon = widget.existing?.icon ?? EnvIcon.public;
  late int _colour = widget.existing?.colour ?? 0;

  bool get _isNew => widget.existing == null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String name = _name.text.trim();
    if (name.isEmpty) return;
    final int order = widget.existing?.order ??
        (ref.read(environmentsProvider).value?.length ?? 0);
    final Environment env = (widget.existing ?? Environment(id: newId()))
        .copyWith(name: name, icon: _icon, colour: _colour, order: order);
    await ref.read(environmentsRepositoryProvider).save(env);
    if (!mounted) return;
    if (_isNew) {
      // Creating it opens the variables page straight away, because an
      // environment with no variables does nothing.
      context.pushReplacement(Routes.environment(env.id));
    } else {
      context.pop();
    }
  }

  Future<void> _delete() async {
    final Environment? env = widget.existing;
    if (env == null) return;
    final bool ok = await confirmDialog(
      context,
      title: 'Delete ${env.name}?',
      message:
          'Its ${env.variables.length} '
          '${env.variables.length == 1 ? 'variable goes' : 'variables go'} '
          'with it. Requests that use them keep the braces.',
      confirmLabel: 'Delete',
    );
    if (!ok || !mounted) return;
    await ref.read(environmentsRepositoryProvider).delete(env.id);
    if (mounted) context.go(Routes.environments);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppHeader(
              title: _isNew ? 'New environment' : 'Edit environment',
              leading: AppIconButton(
                icon: Icons.close_rounded,
                onPressed: () => context.pop(),
                semanticLabel: 'Cancel',
                filled: false,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Space.screen,
                  Space.md,
                  Space.screen,
                  Space.bottomSafe,
                ),
                children: <Widget>[
                  Center(
                    child: EnvTile(
                      icon: _icon.glyph,
                      colourIndex: _colour,
                      size: 72,
                      radius: Radii.sheet,
                    ),
                  ),
                  const SizedBox(height: Space.xl),
                  LabelledField(
                    label: 'Name',
                    controller: _name,
                    hint: 'Staging',
                    autofocus: _isNew,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: Space.lg),
                  RowGroup(
                    children: <Widget>[
                      AppRow(
                        title: 'Icon',
                        leading: EnvTile(
                          icon: _icon.glyph,
                          colourIndex: _colour,
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          size: IconSpec.size,
                          color: c.iconMuted,
                        ),
                        onTap: _pickIcon,
                      ),
                      AppRow(
                        title: 'Colour',
                        subtitle: AppColors.catNames[
                            _colour % AppColors.catNames.length],
                        leading: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: c.cat(_colour),
                            shape: BoxShape.circle,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          size: IconSpec.size,
                          color: c.iconMuted,
                        ),
                        onTap: _pickColour,
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.xl),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _name,
                    builder: (BuildContext context, TextEditingValue value, Widget? _) =>
                        AppButton(
                          label: _isNew ? 'Create and add variables' : 'Save',
                          icon: _isNew
                              ? Icons.arrow_forward_rounded
                              : Icons.check_rounded,
                          iconTrails: _isNew,
                          fullWidth: true,
                          onPressed: value.text.trim().isEmpty ? null : _submit,
                        ),
                  ),
                  if (!_isNew) ...<Widget>[
                    const SizedBox(height: Space.xxl),
                    AppButton(
                      label: 'Delete environment',
                      icon: Icons.delete_outline_rounded,
                      type: AppButtonType.danger,
                      fullWidth: true,
                      onPressed: _delete,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickIcon() async {
    final EnvIcon? chosen = await showAppSheet<EnvIcon>(
      context: context,
      title: 'Icon',
      note: '${EnvIcon.values.length} icons',
      builder: (BuildContext context) => _IconGrid(
        current: _icon,
        colour: _colour,
      ),
    );
    if (chosen != null) setState(() => _icon = chosen);
  }

  Future<void> _pickColour() async {
    final int? chosen = await showAppSheet<int>(
      context: context,
      title: 'Colour',
      note: '${AppColors.catHues.length} hues',
      builder: (BuildContext context) => _ColourList(
        current: _colour,
        icon: _icon,
      ),
    );
    if (chosen != null) setState(() => _colour = chosen);
  }
}

/// Board 4.3. A grid of the twelve icons, drawn in the chosen colour.
class _IconGrid extends StatelessWidget {
  const _IconGrid({required this.current, required this.colour});

  final EnvIcon current;
  final int colour;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Wrap(
      spacing: Space.md,
      runSpacing: Space.md,
      children: <Widget>[
        for (final EnvIcon icon in EnvIcon.values)
          Semantics(
            button: true,
            selected: icon == current,
            label: icon.name,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(icon),
              borderRadius: Radii.thumbR,
              child: Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: icon == current ? c.catContainer(colour) : c.surface,
                  borderRadius: Radii.thumbR,
                  border: Border.all(
                    color: icon == current ? c.cat(colour) : c.outline,
                    width: icon == current ? 2 : 1,
                  ),
                ),
                child: Icon(
                  icon.glyph,
                  size: 28,
                  color: icon == current ? c.cat(colour) : c.icon,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Board 4.4. The seven category hues, each previewed on the current icon so
/// you see the real tile.
class _ColourList extends StatelessWidget {
  const _ColourList({required this.current, required this.icon});

  final int current;
  final EnvIcon icon;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Space.md,
      children: <Widget>[
        const SectionHeader(label: 'Fixed hues', note: 're-derived per theme'),
        RowGroup(
          onSurface: true,
          children: <Widget>[
            for (int i = 0; i < AppColors.catHues.length; i++)
              AppRow(
                title: AppColors.catNames[i],
                leading: EnvTile(
                  icon: icon.glyph,
                  colourIndex: i,
                  size: 36,
                  radius: Radii.thumb,
                ),
                trailing: SizedBox(
                  width: IconSpec.tapTarget,
                  height: IconSpec.tapTarget,
                  child: Center(
                    child: Icon(
                      i == current
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: IconSpec.size,
                      color: i == current ? c.primary : c.iconMuted,
                    ),
                  ),
                ),
                onTap: () => Navigator.of(context).pop(i),
              ),
          ],
        ),
      ],
    );
  }
}

/// Resolves an environment id to its record before opening the editor, so the
/// route can be a plain path without the caller carrying the object.
class EditEnvironmentLoader extends ConsumerWidget {
  const EditEnvironmentLoader({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Environment? env = (ref.watch(environmentsProvider).value ??
            const <Environment>[])
        .where((Environment e) => e.id == id)
        .firstOrNull;
    if (env == null) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppHeader(
                title: 'Edit environment',
                onBack: () => context.pop(),
              ),
              const Expanded(
                child: ErrorStateView(
                  message: 'That environment is no longer here.',
                ),
              ),
            ],
          ),
        ),
      );
    }
    return EnvironmentEditorScreen(existing: env);
  }
}
