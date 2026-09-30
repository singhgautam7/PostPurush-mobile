import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/http/api_client.dart';
import '../../core/http/code_export.dart';
import '../../core/theme/palette.dart';

/// Whether a time is shown as `2 min ago` or as `14:07` (board 7).
enum TimeStyle {
  relative('Relative'),
  absolute('Absolute');

  const TimeStyle(this.label);

  final String label;
}

/// Device-level settings, which must be known before the first frame, kept in
/// SharedPreferences and read synchronously.
///
/// User data (requests, folders, environments, history) lives in the database,
/// not here. The split is what lets the theme be resolved without an await,
/// which is what stops the default theme flashing on launch.
@immutable
class AppSettings {
  const AppSettings({
    this.familyId = 'postpurush',
    this.themeMode = ThemeMode.system,
    this.trueBlack = false,
    this.dynamicColor = false,
    this.timeoutSeconds = 30,
    this.followRedirects = true,
    this.verifySsl = true,
    this.defaultHeaders = const <String, String>{},
    this.timeStyle = TimeStyle.relative,
    this.historyDays = 30,
    this.lastExportLanguage = CodeLanguage.curl,
    this.onboarded = false,
  });

  final String familyId;
  final ThemeMode themeMode;

  /// True black. Only takes effect while dark is in effect, and only for a
  /// family that ships it.
  final bool trueBlack;
  final bool dynamicColor;

  final int timeoutSeconds;
  final bool followRedirects;

  /// Off for a self-signed local server, and that is the only reason to.
  final bool verifySsl;

  /// Added to every request unless the request sets the same name itself.
  final Map<String, String> defaultHeaders;

  final TimeStyle timeStyle;

  /// How long history is kept on the device. Pruned once per launch.
  final int historyDays;

  final CodeLanguage lastExportLanguage;

  /// False until the welcome flow has been seen, which routes the first launch.
  final bool onboarded;

  ThemeFamily get family => ThemeFamily.byId(familyId);

  SendOptions get sendOptions => SendOptions(
    timeout: Duration(seconds: timeoutSeconds),
    followRedirects: followRedirects,
    verifySsl: verifySsl,
    defaultHeaders: defaultHeaders,
  );

  /// The tone to render for a given platform brightness.
  Tone toneFor(Brightness platform) {
    final bool dark = switch (themeMode) {
      ThemeMode.light => false,
      ThemeMode.dark => true,
      ThemeMode.system => platform == Brightness.dark,
    };
    if (!dark) return Tone.light;
    return trueBlack && family.hasAmoled ? Tone.amoled : Tone.dark;
  }

  AppSettings copyWith({
    String? familyId,
    ThemeMode? themeMode,
    bool? trueBlack,
    bool? dynamicColor,
    int? timeoutSeconds,
    bool? followRedirects,
    bool? verifySsl,
    Map<String, String>? defaultHeaders,
    TimeStyle? timeStyle,
    int? historyDays,
    CodeLanguage? lastExportLanguage,
    bool? onboarded,
  }) => AppSettings(
    familyId: familyId ?? this.familyId,
    themeMode: themeMode ?? this.themeMode,
    trueBlack: trueBlack ?? this.trueBlack,
    dynamicColor: dynamicColor ?? this.dynamicColor,
    timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    followRedirects: followRedirects ?? this.followRedirects,
    verifySsl: verifySsl ?? this.verifySsl,
    defaultHeaders: defaultHeaders ?? this.defaultHeaders,
    timeStyle: timeStyle ?? this.timeStyle,
    historyDays: historyDays ?? this.historyDays,
    lastExportLanguage: lastExportLanguage ?? this.lastExportLanguage,
    onboarded: onboarded ?? this.onboarded,
  );

  static const String kFamily = 'theme.family';
  static const String kMode = 'theme.mode';
  static const String kTrueBlack = 'theme.trueBlack';
  static const String kDynamic = 'theme.dynamic';
  static const String kTimeout = 'send.timeout';
  static const String kRedirects = 'send.redirects';
  static const String kSsl = 'send.ssl';
  static const String kHeaders = 'send.headers';
  static const String kTimeStyle = 'time.style';
  static const String kHistoryDays = 'history.days';
  static const String kExportLanguage = 'export.language';
  static const String kOnboarded = 'app.onboarded';

  /// Timeout choices, in seconds. A stepper would be fiddly for something
  /// chosen once, so it is a short list.
  static const List<int> timeoutChoices = <int>[5, 10, 30, 60, 120];

  static const List<int> historyChoices = <int>[7, 30, 90, 365];

  static AppSettings read(SharedPreferences prefs) => AppSettings(
    familyId: prefs.getString(kFamily) ?? 'postpurush',
    themeMode: ThemeMode.values.firstWhere(
      (ThemeMode m) => m.name == prefs.getString(kMode),
      orElse: () => ThemeMode.system,
    ),
    trueBlack: prefs.getBool(kTrueBlack) ?? false,
    dynamicColor: prefs.getBool(kDynamic) ?? false,
    timeoutSeconds: prefs.getInt(kTimeout) ?? 30,
    followRedirects: prefs.getBool(kRedirects) ?? true,
    verifySsl: prefs.getBool(kSsl) ?? true,
    defaultHeaders: _readHeaders(prefs.getString(kHeaders)),
    timeStyle: prefs.getString(kTimeStyle) == TimeStyle.absolute.name
        ? TimeStyle.absolute
        : TimeStyle.relative,
    historyDays: prefs.getInt(kHistoryDays) ?? 30,
    lastExportLanguage: CodeLanguage.parse(prefs.getString(kExportLanguage)),
    onboarded: prefs.getBool(kOnboarded) ?? false,
  );

  /// A malformed blob means no default headers, not a crash on launch.
  static Map<String, String> _readHeaders(String? raw) {
    if (raw == null || raw.isEmpty) return const <String, String>{};
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const <String, String>{};
      return <String, String>{
        for (final MapEntry<String, dynamic> e in decoded.entries)
          e.key: '${e.value}',
      };
    } catch (_) {
      return const <String, String>{};
    }
  }
}

/// Overridden in `main` with the instance opened during bootstrap.
final Provider<SharedPreferences> prefsProvider = Provider<SharedPreferences>(
  (Ref ref) => throw UnimplementedError('prefsProvider must be overridden'),
);

/// Settings are held in memory and written through, so reading the theme is
/// synchronous and a change repaints exactly the widgets that selected on it.
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => AppSettings.read(ref.watch(prefsProvider));

  SharedPreferences get _prefs => ref.read(prefsProvider);

  Future<void> setFamily(String id) async {
    state = state.copyWith(familyId: id);
    await _prefs.setString(AppSettings.kFamily, id);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(AppSettings.kMode, mode.name);
  }

  Future<void> setTrueBlack({required bool value}) async {
    state = state.copyWith(trueBlack: value);
    await _prefs.setBool(AppSettings.kTrueBlack, value);
  }

  Future<void> setDynamicColor({required bool value}) async {
    state = state.copyWith(dynamicColor: value);
    await _prefs.setBool(AppSettings.kDynamic, value);
  }

  Future<void> setTimeout(int seconds) async {
    state = state.copyWith(timeoutSeconds: seconds);
    await _prefs.setInt(AppSettings.kTimeout, seconds);
  }

  Future<void> setFollowRedirects({required bool value}) async {
    state = state.copyWith(followRedirects: value);
    await _prefs.setBool(AppSettings.kRedirects, value);
  }

  Future<void> setVerifySsl({required bool value}) async {
    state = state.copyWith(verifySsl: value);
    await _prefs.setBool(AppSettings.kSsl, value);
  }

  Future<void> setDefaultHeaders(Map<String, String> headers) async {
    state = state.copyWith(defaultHeaders: headers);
    await _prefs.setString(AppSettings.kHeaders, jsonEncode(headers));
  }

  Future<void> setTimeStyle(TimeStyle style) async {
    state = state.copyWith(timeStyle: style);
    await _prefs.setString(AppSettings.kTimeStyle, style.name);
  }

  Future<void> setHistoryDays(int days) async {
    state = state.copyWith(historyDays: days);
    await _prefs.setInt(AppSettings.kHistoryDays, days);
  }

  Future<void> setExportLanguage(CodeLanguage language) async {
    state = state.copyWith(lastExportLanguage: language);
    await _prefs.setString(AppSettings.kExportLanguage, language.name);
  }

  Future<void> setOnboarded({required bool value}) async {
    state = state.copyWith(onboarded: value);
    await _prefs.setBool(AppSettings.kOnboarded, value);
  }
}

final NotifierProvider<SettingsController, AppSettings> settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
