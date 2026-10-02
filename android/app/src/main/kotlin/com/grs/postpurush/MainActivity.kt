package com.grs.postpurush

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The one channel. It answers what only the platform knows: the version
 * Android actually installed, so the About screen cannot drift from the APK
 * the way a constant in Dart does.
 */
class MainActivity : FlutterActivity() {
    private val channel = "com.grs.postpurush/platform"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "appVersion" -> result.success(appVersion())
                    else -> result.notImplemented()
                }
            }
    }

    private fun appVersion(): Map<String, Any> {
        val info = packageManager.getPackageInfo(packageName, 0)
        val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }
        return mapOf("name" to (info.versionName ?: ""), "code" to code)
    }
}
