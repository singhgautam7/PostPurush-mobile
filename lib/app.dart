import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/palette.dart';
import 'core/util/wallpaper_seed.dart';
import 'features/settings/settings_controller.dart';

/// The theme for one brightness, from the settings and, with dynamic colour on,
/// the wallpaper seed.
///
/// Both branches go through the cache in [AppTheme], so a rebuild is a map
/// lookup. Settings were read synchronously before the first frame, which is
/// what stops the default theme flashing on launch.
ThemeData themeFor(AppSettings s, Color? seed, Brightness brightness) {
  final Tone tone = s.toneFor(brightness);
  return seed == null
      ? AppTheme.of(s.family, tone)
      : AppTheme.fromSeed(seed, tone);
}

class PostPurushApp extends ConsumerStatefulWidget {
  const PostPurushApp({super.key});

  @override
  ConsumerState<PostPurushApp> createState() => _PostPurushAppState();
}

class _PostPurushAppState extends ConsumerState<PostPurushApp> {
  // Read once: the flow is shown on the first launch and the flag is written
  // on the way out, so re-reading it would rebuild the router mid-session.
  late final GoRouter _router = buildRouter(
    onboarded: ref.read(settingsProvider).onboarded,
  );

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = ref.watch(settingsProvider);
    // Dynamic colour takes one seed from the OS; every other role is derived
    // exactly as a bundled family's would be, so the two never diverge.
    final Color? seed = settings.dynamicColor
        ? ref.watch(wallpaperSeedProvider).value
        : null;

    return MaterialApp.router(
      title: 'PostPurush',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      themeMode: settings.themeMode,
      theme: themeFor(settings, seed, Brightness.light),
      darkTheme: themeFor(settings, seed, Brightness.dark),
    );
  }
}
