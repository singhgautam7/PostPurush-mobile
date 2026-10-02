import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the app can only learn from Android itself.
///
/// One channel, one method. A version written into Dart as a constant drifts
/// from the APK the moment someone bumps `pubspec.yaml` and forgets, so the
/// number on the About screen is the one the package manager reports.
abstract final class PlatformSurfaces {
  static const MethodChannel _channel = MethodChannel(
    'com.grs.postpurush/platform',
  );

  /// The installed version, or null off-device, where there is no package to
  /// ask: a widget test, or any host without the Android side registered.
  static Future<AppVersion?> appVersion() async {
    try {
      final Map<Object?, Object?>? raw = await _channel
          .invokeMapMethod<Object?, Object?>('appVersion');
      if (raw == null) return null;
      final String name = raw['name'] as String? ?? '';
      if (name.isEmpty) return null;
      return AppVersion(name: name, code: (raw['code'] as num?)?.toInt() ?? 0);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}

class AppVersion {
  const AppVersion({required this.name, required this.code});

  /// `versionName`, which is the part of `pubspec.yaml` before the `+`.
  final String name;

  /// `versionCode`, the part after it.
  final int code;

  @override
  String toString() => 'v$name · build $code';
}

/// Read once per launch: the package cannot change while the app is running.
final FutureProvider<AppVersion?> appVersionProvider =
    FutureProvider<AppVersion?>((Ref ref) => PlatformSurfaces.appVersion());
