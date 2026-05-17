package com.example.control

import android.content.Context
import org.json.JSONObject

object InterceptionConfigStore {
    private const val PREFS = "control_interception"
    private const val KEY_CONFIG = "protected_config"
    private const val KEY_ALLOWED_PACKAGE = "last_allowed_package"
    private const val KEY_ALLOWED_AT_MS = "last_allowed_at_ms"

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
