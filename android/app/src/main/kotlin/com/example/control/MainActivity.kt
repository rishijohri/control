package com.example.control

import android.content.Intent
import android.provider.Settings
import com.example.control.interception.ControlAccessibilityService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "control/app_interception"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openPermissionSettings" -> {
                        openPermissionSettings()
                        result.success(null)
                    }
                    "allowLaunch" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            ControlAccessibilityService.allowNextLaunch(packageName)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun openPermissionSettings() {
        // We intentionally route users directly to Accessibility settings first,
        // then the onboarding UI guides them to Usage Access and battery settings.
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }
}
