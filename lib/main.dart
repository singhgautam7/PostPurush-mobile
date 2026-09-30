import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/db/app_db.dart';
import 'core/db/history_repository.dart';
import 'core/providers.dart';
import 'features/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Transparent bars, so the app's own surfaces reach the screen edges.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Open what the first frame needs before drawing it: the settings decide the
  // theme, so reading them synchronously is what stops a flash of the default.
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final AppDatabase database = AppDatabase();

  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      prefsProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(database),
    ],
  );

  // History cannot grow without bound. Pruning is off the first frame, because
  // nothing on screen waits for it.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      HistoryRepository(database)
          .prune(keepDays: container.read(settingsProvider).historyDays)
          .catchError((Object error) {
            debugPrint('History prune skipped: $error');
            return 0;
          }),
    );
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PostPurushApp(),
    ),
  );
}
