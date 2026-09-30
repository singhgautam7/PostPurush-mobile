import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/util/wallpaper_seed.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_icon_button.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/section_header.dart';
import '../about/app_mark.dart';
import '../settings/settings_controller.dart';

/// The welcome board's three-step flow: what it is, what it does, pick a look.
///
/// Shown once. Skip on every step goes straight to Collections, so nobody is
/// held up, and the flag is written on the way out either way.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  int _step = 0;

  static const int _steps = 3;

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).setOnboarded(value: true);
    if (mounted) context.go(Routes.collections);
  }

  void _next() {
    if (_step < _steps - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _TopRow(
                step: _step,
                steps: _steps,
                onBack: _step == 0 ? null : () => setState(() => _step--),
                onSkip: _step == _steps - 1 ? null : _finish,
              ),
              Expanded(
                // Each step replaces the last in place. The key is the step, so
                // the entrance runs again on every change.
                child: _StepBody(
                  key: ValueKey<int>(_step),
                  step: _step,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: Space.lg,
                  bottom: Space.xl,
                ),
                child: AppButton(
                  label: _step == _steps - 1 ? 'Get started' : 'Next',
                  icon: Icons.arrow_forward_rounded,
                  iconTrails: true,
                  fullWidth: true,
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.step,
    required this.steps,
    required this.onBack,
    required this.onSkip,
  });

  final int step;
  final int steps;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return SizedBox(
      height: IconSpec.tapTarget,
      child: Row(
        children: <Widget>[
          if (onBack != null)
            AppIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: onBack,
              semanticLabel: 'Back a step',
              filled: false,
            ),
          Text(
            '${step + 1} of $steps',
            style: AppType.monoLabel.copyWith(color: c.onSurfaceVariant),
          ),
          const Spacer(),
          if (onSkip != null)
            TextButton(
              onPressed: onSkip,
              child: Text(
                'Skip',
                style: AppType.titleMedium.copyWith(color: c.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

/// The entrance the board asks for: the mark scales from 0.88 without
/// overshooting past 1, and everything below it rises 12dp and fades, staggered
/// 40 ms. Under reduced motion it is one 90 ms cross-fade.
class _StepBody extends StatefulWidget {
  const _StepBody({required this.step, super.key});

  final int step;

  @override
  State<_StepBody> createState() => _StepBodyState();
}

class _StepBodyState extends State<_StepBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  static const Duration _stagger = Duration(milliseconds: 40);

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// A child's slice of the entrance: it starts [index] staggers in and runs
  /// for the board's `sheet 260`.
  Animation<double> _slot(int index) {
    const double total = 620;
    final double start = (_stagger.inMilliseconds * index) / total;
    final double end = (start + 260 / total).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(start.clamp(0.0, 1.0), end, curve: Motion.decelerate),
    );
  }

  Widget _rise(int index, Widget child) {
    if (Motion.reduced(context)) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: _entrance,
          curve: const Interval(0, 0.15),
        ),
        child: child,
      );
    }
    final Animation<double> slot = _slot(index);
    return FadeTransition(
      opacity: slot,
      child: AnimatedBuilder(
        animation: slot,
        builder: (BuildContext context, Widget? inner) => Transform.translate(
          offset: Offset(0, 12 * (1 - slot.value)),
          child: inner,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = switch (widget.step) {
      0 => _promise(context),
      1 => _features(context),
      _ => _look(context),
    };
    return ListView(
      padding: const EdgeInsets.only(top: Space.lg, bottom: Space.lg),
      children: <Widget>[
        for (int i = 0; i < children.length; i++) _rise(i, children[i]),
      ],
    );
  }

  /// B1. What it is.
  List<Widget> _promise(BuildContext context) {
    final AppColors c = context.colors;
    return <Widget>[
      // The mark scales from 0.88 and fades, and never overshoots past 1.
      Padding(
        padding: const EdgeInsets.only(bottom: Space.xl),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1).animate(
              CurvedAnimation(
                parent: _entrance,
                curve: Interval(
                  0,
                  240 / 620,
                  curve: Motion.curveOf(context, Motion.decelerate),
                ),
              ),
            ),
            child: const AppMark.tile(),
          ),
        ),
      ),
      Text(
        'A local-first API client',
        style: AppType.display.copyWith(color: c.onSurface),
      ),
      const SizedBox(height: Space.md),
      Text(
        'Build, send, and explore APIs, all on your device.',
        style: AppType.body.copyWith(color: c.onSurfaceVariant),
      ),
      const SizedBox(height: Space.xl),
      const Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: <Widget>[
          _PromiseChip(icon: Icons.person_off_rounded, label: 'No account.'),
          _PromiseChip(icon: Icons.sync_disabled_rounded, label: 'No sync.'),
          _PromiseChip(
            icon: Icons.visibility_off_rounded,
            label: 'No tracking.',
          ),
        ],
      ),
      const SizedBox(height: Space.lg),
      Row(
        spacing: Space.sm,
        children: <Widget>[
          Icon(
            Icons.smartphone_rounded,
            size: IconSpec.small,
            color: c.iconMuted,
          ),
          Expanded(
            child: Text(
              'Everything stays on this device.',
              style: AppType.bodyMedium.copyWith(color: c.onSurfaceVariant),
            ),
          ),
        ],
      ),
    ];
  }

  /// B2. What it does: the six features, each with the icon it carries in the
  /// app, so the flow teaches the navigation as well as the promise.
  List<Widget> _features(BuildContext context) {
    final AppColors c = context.colors;
    const List<(IconData, String, String)> features =
        <(IconData, String, String)>[
      (
        Icons.send_rounded,
        'Compose and send requests',
        'Any method, headers, body and auth',
      ),
      (
        Icons.folder_open_rounded,
        'Collections and environments',
        'Folders, plus variables per environment',
      ),
      (
        Icons.explore_outlined,
        'Explore public APIs',
        'Browse a catalogue and try them right away',
      ),
      (
        Icons.science_outlined,
        'API testing',
        'Assertions and load tests',
      ),
      (
        Icons.bar_chart_rounded,
        'Analytics',
        'Response times and status codes',
      ),
      (
        Icons.description_outlined,
        'API docs',
        'Generated from a collection, export as PDF',
      ),
    ];
    return <Widget>[
      Text(
        'Build, test, and document APIs',
        style: AppType.display.copyWith(fontSize: 32, color: c.onSurface),
      ),
      const SizedBox(height: Space.xl),
      for (final (IconData icon, String title, String note) in features)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.row),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              spacing: 14,
              children: <Widget>[
                Container(
                  width: IconSpec.tapTarget,
                  height: IconSpec.tapTarget,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.primaryContainer,
                    borderRadius: Radii.thumbR,
                  ),
                  child: Icon(
                    icon,
                    size: IconSpec.size,
                    color: c.onPrimaryContainer,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppType.titleMedium.copyWith(
                          color: c.onSurface,
                        ),
                      ),
                      Text(
                        note,
                        style: AppType.bodyMedium.copyWith(
                          color: c.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  /// B3. Pick a look. The five accents the board names, plus wallpaper colour
  /// where the device offers it, and the three modes.
  List<Widget> _look(BuildContext context) {
    final AppColors c = context.colors;
    return <Widget>[
      Text('Pick a look', style: AppType.display.copyWith(color: c.onSurface)),
      const SizedBox(height: Space.md),
      Text(
        'Change it any time in More, then Settings, then Theme.',
        style: AppType.body.copyWith(color: c.onSurfaceVariant),
      ),
      const SizedBox(height: Space.xl),
      const SectionHeader(label: 'Accent'),
      const SizedBox(height: Space.row),
      const _AccentRow(),
      const SizedBox(height: Space.xl),
      const SectionHeader(label: 'Mode'),
      const SizedBox(height: Space.row),
      const _ModeRow(),
    ];
  }
}

class _PromiseChip extends StatelessWidget {
  const _PromiseChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      decoration: BoxDecoration(
        color: c.surfaceContainerHigh,
        borderRadius: Radii.fullR,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: <Widget>[
          Icon(icon, size: 16, color: c.iconMuted),
          Text(label, style: AppType.label.copyWith(color: c.onSurface)),
        ],
      ),
    );
  }
}

/// The board's five named accents. Each swatch is derived live from its family,
/// so what you tap is what you get.
class _AccentRow extends ConsumerWidget {
  const _AccentRow();

  static const List<(String, String)> _choices = <(String, String)>[
    ('postpurush', 'Green'),
    ('indigo', 'Indigo'),
    ('lithub-blue', 'Blue'),
    ('hostman-orange', 'Orange'),
    ('cutube-red', 'Red'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors c = context.colors;
    final AppSettings s = ref.watch(settingsProvider);
    final SettingsController controller = ref.read(settingsProvider.notifier);
    final bool wallpaper = ref.watch(wallpaperSeedProvider).value != null;

    return Wrap(
      spacing: Space.md,
      runSpacing: Space.md,
      children: <Widget>[
        if (wallpaper)
          _Swatch(
            label: 'Wallpaper',
            colour: c.primary,
            icon: Icons.palette_rounded,
            selected: s.dynamicColor,
            onTap: () => controller.setDynamicColor(value: true),
          ),
        for (final (String id, String label) in _choices)
          _Swatch(
            label: label,
            colour: ThemeFamily.byId(id)
                .colors(c.isDark ? Tone.dark : Tone.light)
                .primary,
            selected: !s.dynamicColor && s.familyId == id,
            onTap: () async {
              await controller.setDynamicColor(value: false);
              await controller.setFamily(id);
            },
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.colour,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final Color colour;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.cardR,
        child: SizedBox(
          width: 88,
          child: Column(
            spacing: 6,
            children: <Widget>[
              Container(
                height: IconSpec.tapTarget,
                width: IconSpec.tapTarget,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colour,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? c.onSurface : c.outline,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: IconSpec.small,
                        color: c.onPrimary,
                      )
                    : icon == null
                        ? null
                        : Icon(
                            icon,
                            size: IconSpec.small,
                            color: c.onPrimary,
                          ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.label.copyWith(
                  color: selected ? c.onSurface : c.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeRow extends ConsumerWidget {
  const _ModeRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors c = context.colors;
    final AppSettings s = ref.watch(settingsProvider);
    const List<(ThemeMode, String, IconData)> modes =
        <(ThemeMode, String, IconData)>[
      (ThemeMode.light, 'Light', Icons.light_mode_rounded),
      (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
      (ThemeMode.system, 'System', Icons.contrast_rounded),
    ];
    return Row(
      spacing: Space.row,
      children: <Widget>[
        for (final (ThemeMode mode, String label, IconData icon) in modes)
          Expanded(
            child: Semantics(
              button: true,
              selected: s.themeMode == mode,
              child: InkWell(
                onTap: () =>
                    ref.read(settingsProvider.notifier).setThemeMode(mode),
                borderRadius: Radii.cardR,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: s.themeMode == mode
                        ? c.primaryContainer
                        : c.surfaceContainer,
                    borderRadius: Radii.cardR,
                    border: Border.all(
                      color: s.themeMode == mode ? c.primary : c.outline,
                    ),
                  ),
                  child: Column(
                    spacing: 6,
                    children: <Widget>[
                      Icon(
                        icon,
                        size: IconSpec.size,
                        color: s.themeMode == mode
                            ? c.onPrimaryContainer
                            : c.icon,
                      ),
                      Text(
                        label,
                        style: AppType.label.copyWith(
                          color: s.themeMode == mode
                              ? c.onPrimaryContainer
                              : c.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
