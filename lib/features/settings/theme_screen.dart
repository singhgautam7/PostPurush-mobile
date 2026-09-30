import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/util/wallpaper_seed.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/section_header.dart';
import 'settings_controller.dart';

/// Board 7.1. Everything about appearance on one page: mode, true black, then
/// colour. Each swatch is calculated live from its family, so what you see is
/// what the theme will be.
class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors c = context.colors;
    final AppSettings s = ref.watch(settingsProvider);
    final SettingsController controller = ref.read(settingsProvider.notifier);
    final AsyncValue<Color?> seed = ref.watch(wallpaperSeedProvider);
    final bool wallpaperAvailable = seed.value != null;

    return PageScaffold(
      title: 'Theme',
      children: <Widget>[
        const SectionHeader(label: 'Mode'),
        const SizedBox(height: Space.row),
        SegmentedToggle<ThemeMode>(
          options: const <(ThemeMode, String)>[
            (ThemeMode.light, 'Light'),
            (ThemeMode.dark, 'Dark'),
            (ThemeMode.system, 'System'),
          ],
          selected: s.themeMode,
          onChanged: controller.setThemeMode,
        ),
        const SizedBox(height: Space.lg),
        RowGroup(
          children: <Widget>[
            SwitchRow(
              label: 'True black',
              note: s.family.hasAmoled
                  ? 'in dark mode'
                  : 'this family does not ship it',
              icon: Icons.contrast_rounded,
              value: s.trueBlack,
              onChanged: s.family.hasAmoled || s.dynamicColor
                  ? (bool value) => controller.setTrueBlack(value: value)
                  : (bool _) {},
            ),
          ],
        ),
        const SizedBox(height: Space.section),
        SectionHeader(
          label: 'Colour',
          note: s.dynamicColor && wallpaperAvailable
              ? 'fallback, without wallpaper colour'
              : 'calculated live',
        ),
        const SizedBox(height: Space.row),
        RowGroup(
          children: <Widget>[
            for (final ThemeFamily family in ThemeFamily.all)
              _FamilyRow(
                family: family,
                selected: family.id == s.familyId,
                onTap: () => controller.setFamily(family.id),
              ),
          ],
        ),
        const SizedBox(height: Space.lg),
        RowGroup(
          children: <Widget>[
            SwitchRow(
              label: 'From your wallpaper',
              note: wallpaperAvailable
                  ? 'overrides the family above, Android 12 and later'
                  : 'this device does not offer one',
              icon: Icons.wallpaper_rounded,
              value: s.dynamicColor && wallpaperAvailable,
              onChanged: wallpaperAvailable
                  ? (bool value) => controller.setDynamicColor(value: value)
                  : (bool _) {},
            ),
          ],
        ),
        const SizedBox(height: Space.xl),
        Text(
          'Every colour is an OKLCh formula, evaluated for the family and the '
          'mode in effect. Nothing is stored as a hex value, so method chips, '
          'status chips and environment colours stay legible in each one.',
          style: AppType.bodySmall.copyWith(color: c.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// A family row with its own swatches, derived at the moment it is drawn.
class _FamilyRow extends StatelessWidget {
  const _FamilyRow({
    required this.family,
    required this.selected,
    required this.onTap,
  });

  final ThemeFamily family;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final bool dark = c.isDark;
    // The preview is this family in the tone currently in effect, which is what
    // picking it would actually give.
    final AppColors preview = family.colors(
      dark
          ? (family.hasAmoled && c.tone == Tone.amoled
                ? Tone.amoled
                : Tone.dark)
          : Tone.light,
    );
    return AppRow(
      title: family.name,
      subtitle: <String>[
        family.blurb,
        if (family.hasAmoled) 'true black',
      ].join(' · '),
      selected: selected,
      minHeight: 60,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: <Widget>[
          _Swatch(colour: preview.primary, size: 22),
          _Swatch(colour: preview.primaryContainer, size: 16),
          _Swatch(colour: preview.surfaceContainerHigh, size: 12),
        ],
      ),
      trailing: SizedBox(
        width: IconSpec.tapTarget,
        height: IconSpec.tapTarget,
        child: Center(
          child: Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            size: IconSpec.size,
            color: selected ? c.primary : c.iconMuted,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.colour, required this.size});

  final Color colour;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: colour,
      shape: BoxShape.circle,
      border: Border.all(color: context.colors.outline),
    ),
  );
}
