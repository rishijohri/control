package com.example.control

import android.app.AppOpsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ResolveInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity(), MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

	companion object {
		const val ACTION_PROTECTED_APP_LAUNCHED = "com.example.control.PROTECTED_APP_LAUNCHED"
		const val ACTION_SHOW_INTERVENTION = "com.example.control.SHOW_INTERVENTION"
		const val EXTRA_PACKAGE_NAME = "packageName"
		const val EXTRA_TIMESTAMP = "timestamp"
		const val EXTRA_DELAY_SECONDS = "delaySeconds"
	}

	private lateinit var methodChannel: MethodChannel
	private lateinit var eventChannel: EventChannel
	private var eventSink: EventChannel.EventSink? = null
	private var eventReceiver: BroadcastReceiver? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "control/native")
		methodChannel.setMethodCallHandler(this)

		eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, "control/app_detection_events")
		eventChannel.setStreamHandler(this)
	}

	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		if (intent.action == ACTION_SHOW_INTERVENTION) {
			val packageName = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: return
			eventSink?.success(
				mapOf(
					EXTRA_PACKAGE_NAME to packageName,
					EXTRA_TIMESTAMP to System.currentTimeMillis()
				)
			)
		}
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"openAccessibilitySettings" -> {
				startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
				result.success(null)
			}

			"openUsageAccessSettings" -> {
				startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
				result.success(null)
			}

			"openBatteryOptimizationSettings" -> {
				val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
					data = Uri.parse("package:$packageName")
				}
				startActivity(intent)
				result.success(null)
			}

			"isAccessibilityEnabled" -> result.success(isAccessibilityServiceEnabled())
			"isUsageAccessGranted" -> result.success(isUsageAccessGranted())
			"isIgnoringBatteryOptimizations" -> result.success(isIgnoringBatteryOptimizations())
			"getInstalledApps" -> {
				val includeIcons = (call.arguments as? Map<*, *>)
					?.get("includeIcons") as? Boolean ?: false
				result.success(getInstalledApps(includeIcons))
			}
			"getUsageStats" -> result.success(getUsageStats())

			"launchApp" -> {
				val packageName = (call.arguments as? Map<*, *>)?.get("packageName")?.toString() ?: ""
				launchApp(packageName)
				result.success(null)
			}

			"recordBypass" -> {
				val args = call.arguments as? Map<*, *>
				val packageName = args?.get("packageName")?.toString() ?: ""
				val timestampMs = (args?.get("timestampMs") as? Number)?.toLong()
					?: System.currentTimeMillis()

				if (packageName.isNotBlank()) {
					InterceptionConfigStore.recordAllowedOpen(this, packageName, timestampMs)
				}
				result.success(null)
			}

			"syncProtectionConfig" -> {
				val configMap = mutableMapOf<String, Map<String, Any?>>()
				val args = call.arguments as? Map<*, *>
				val config = args?.get("config") as? Map<*, *> ?: emptyMap<String, Any>()

				for ((key, value) in config) {
					val packageName = key?.toString() ?: continue
					val valueMap = value as? Map<*, *> ?: continue
					configMap[packageName] = valueMap.mapKeys { entry -> entry.key.toString() }
				}

				InterceptionConfigStore.saveConfig(this, configMap)
				result.success(null)
			}

			else -> result.notImplemented()
		}
	}

	override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
		eventSink = events
		if (eventReceiver != null) return

		eventReceiver = object : BroadcastReceiver() {
			override fun onReceive(context: Context?, intent: Intent?) {
				if (intent?.action != ACTION_PROTECTED_APP_LAUNCHED) return
				val packageName = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: return
				val timestamp = intent.getLongExtra(EXTRA_TIMESTAMP, System.currentTimeMillis())
				eventSink?.success(
					mapOf(
						EXTRA_PACKAGE_NAME to packageName,
						EXTRA_TIMESTAMP to timestamp
					)
				)
			}
		}

		val filter = IntentFilter(ACTION_PROTECTED_APP_LAUNCHED)
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
			registerReceiver(eventReceiver, filter, RECEIVER_NOT_EXPORTED)
		} else {
			@Suppress("DEPRECATION")
			registerReceiver(eventReceiver, filter)
		}
	}

	override fun onCancel(arguments: Any?) {
		eventSink = null
		eventReceiver?.let {
			unregisterReceiver(it)
		}
		eventReceiver = null
	}

	private fun getInstalledApps(includeIcons: Boolean): List<Map<String, Any?>> {
		val launcherIntent = Intent(Intent.ACTION_MAIN, null).apply {
			addCategory(Intent.CATEGORY_LAUNCHER)
		}

		val launchables: List<ResolveInfo> = packageManager.queryIntentActivities(launcherIntent, 0)
		return launchables
			.sortedBy { it.loadLabel(packageManager).toString().lowercase() }
			.map { info ->
				val packageName = info.activityInfo.packageName
				mapOf(
					"packageName" to packageName,
					"label" to info.loadLabel(packageManager).toString(),
					"iconBase64" to if (includeIcons) drawableToBase64(info.loadIcon(packageManager)) else null
				)
			}
	}

	private fun getUsageStats(): Map<String, Int> {
		val usageManager = getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
		val end = System.currentTimeMillis()
		val start = end - (24L * 60 * 60 * 1000)
		val stats = usageManager.queryUsageStats(
			android.app.usage.UsageStatsManager.INTERVAL_DAILY,
			start,
			end
		)

		return stats.associate { item ->
			item.packageName to (item.totalTimeInForeground / 60000L).toInt()
		}
	}

	private fun launchApp(packageName: String) {
		if (packageName.isBlank()) return
		val intent = packageManager.getLaunchIntentForPackage(packageName) ?: return
		InterceptionConfigStore.recordAllowedOpen(this, packageName, System.currentTimeMillis())
		intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		startActivity(intent)
	}

	private fun isUsageAccessGranted(): Boolean {
		val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
		val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			appOps.unsafeCheckOpNoThrow(
				AppOpsManager.OPSTR_GET_USAGE_STATS,
				android.os.Process.myUid(),
				packageName
			)
		} else {
			@Suppress("DEPRECATION")
			appOps.checkOpNoThrow(
				AppOpsManager.OPSTR_GET_USAGE_STATS,
				android.os.Process.myUid(),
				packageName
			)
		}
		return mode == AppOpsManager.MODE_ALLOWED
	}

	private fun isAccessibilityServiceEnabled(): Boolean {
		val expected = "$packageName/${DistractingAppAccessibilityService::class.java.name}"
		val enabledServices = Settings.Secure.getString(
			contentResolver,
			Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
		) ?: return false
		return enabledServices.contains(expected)
	}

	private fun isIgnoringBatteryOptimizations(): Boolean {
		val manager = getSystemService(Context.POWER_SERVICE) as PowerManager
		return manager.isIgnoringBatteryOptimizations(packageName)
	}

	private fun drawableToBase64(drawable: Drawable): String? {
		val bitmap = if (drawable is BitmapDrawable) {
			drawable.bitmap
		} else {
			val width = drawable.intrinsicWidth.takeIf { it > 0 } ?: 96
			val height = drawable.intrinsicHeight.takeIf { it > 0 } ?: 96
			Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).apply {
				val canvas = Canvas(this)
				drawable.setBounds(0, 0, canvas.width, canvas.height)
				drawable.draw(canvas)
			}
		}

		return try {
			val output = ByteArrayOutputStream()
			bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
			Base64.encodeToString(output.toByteArray(), Base64.NO_WRAP)
		} catch (_: Throwable) {
			null
		}
	}
}
