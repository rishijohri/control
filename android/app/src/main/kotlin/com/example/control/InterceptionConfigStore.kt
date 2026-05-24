package com.example.control

import android.content.Context
import org.json.JSONObject

object InterceptionConfigStore {
    private const val PREFS = "control_interception"
    private const val KEY_CONFIG = "protected_config"
    private const val KEY_ALLOWED_PACKAGE = "last_allowed_package"
    private const val KEY_ALLOWED_AT_MS = "last_allowed_at_ms"
    private const val KEY_SHORT_FORM_DETECTION_ENABLED = "short_form_detection_enabled"
    private const val KEY_SHORT_FORM_INTERRUPTION_AFTER_SECONDS =
        "short_form_interruption_after_seconds"

    private const val DEFAULT_SHORT_FORM_DETECTION_ENABLED = false
    private const val DEFAULT_SHORT_FORM_INTERRUPTION_AFTER_SECONDS = 30

    fun saveConfig(context: Context, config: Map<String, Map<String, Any?>>) {
        val json = JSONObject()
        config.forEach { (packageName, value) ->
            json.put(packageName, JSONObject(value))
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_CONFIG, json.toString())
            .apply()
    }

    fun isProtected(context: Context, packageName: String): Boolean {
        return getConfig(context).has(packageName)
    }

    fun getDelaySeconds(context: Context, packageName: String): Int {
        val appJson = getConfig(context).optJSONObject(packageName) ?: return 8
        return appJson.optInt("delaySeconds", 8)
    }

    fun recordAllowedOpen(context: Context, packageName: String, timestampMs: Long) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_ALLOWED_PACKAGE, packageName)
            .putLong(KEY_ALLOWED_AT_MS, timestampMs)
            .apply()
    }

    fun setShortFormSettings(
        context: Context,
        enabled: Boolean,
        interruptionAfterSeconds: Int
    ) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_SHORT_FORM_DETECTION_ENABLED, enabled)
            .putInt(
                KEY_SHORT_FORM_INTERRUPTION_AFTER_SECONDS,
                interruptionAfterSeconds.coerceIn(10, 120)
            )
            .apply()
    }

    fun isShortFormDetectionEnabled(context: Context): Boolean {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean(
                KEY_SHORT_FORM_DETECTION_ENABLED,
                DEFAULT_SHORT_FORM_DETECTION_ENABLED
            )
    }

    fun getShortFormInterruptionAfterSeconds(context: Context): Int {
        val value = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getInt(
                KEY_SHORT_FORM_INTERRUPTION_AFTER_SECONDS,
                DEFAULT_SHORT_FORM_INTERRUPTION_AFTER_SECONDS
            )
        return value.coerceIn(10, 120)
    }

    fun wasRecentlyAllowedOpen(
        context: Context,
        packageName: String,
        windowMs: Long = 45_000L
    ): Boolean {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val allowedPackage = prefs.getString(KEY_ALLOWED_PACKAGE, "") ?: ""
        if (allowedPackage != packageName) return false

        val allowedAtMs = prefs.getLong(KEY_ALLOWED_AT_MS, 0L)
        if (allowedAtMs <= 0L) return false

        val age = System.currentTimeMillis() - allowedAtMs
        return age in 0..windowMs
    }

    private fun getConfig(context: Context): JSONObject {
        val text = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_CONFIG, "{}") ?: "{}"
        return try {
            JSONObject(text)
        } catch (_: Throwable) {
            JSONObject()
        }
    }
}
