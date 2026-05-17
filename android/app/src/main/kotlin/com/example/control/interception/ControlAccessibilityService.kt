package com.example.control.interception

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import java.util.concurrent.ConcurrentHashMap

/**
 * Accessibility service that observes foreground app changes.
 *
 * Design notes:
 * - We only subscribe to window-state events for lower battery impact.
 * - A short in-memory cooldown avoids infinite loops when our own app opens.
 * - allowNextLaunch() creates a one-shot bypass for deliberate user continuation.
 */
class ControlAccessibilityService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val packageName = event?.packageName?.toString() ?: return
        if (packageName == this.packageName) return
        if (!ProtectedAppStore.isProtected(packageName)) return
        if (AllowedLaunchStore.consume(packageName)) return

        val now = System.currentTimeMillis()
        val last = debounce[packageName] ?: 0L
        if (now - last < 1000L) return
        debounce[packageName] = now

        val intent = packageManager.getLaunchIntentForPackage(this.packageName) ?: return
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        intent.putExtra("intervention_target_package", packageName)
        startActivity(intent)
    }

    override fun onInterrupt() = Unit

    companion object {
        private val debounce = ConcurrentHashMap<String, Long>()

        fun allowNextLaunch(packageName: String) {
            AllowedLaunchStore.allow(packageName)
        }
    }
}

private object AllowedLaunchStore {
    private val grants = ConcurrentHashMap<String, Long>()

    fun allow(packageName: String) {
        grants[packageName] = System.currentTimeMillis() + 15_000L
    }

    fun consume(packageName: String): Boolean {
        val expiresAt = grants.remove(packageName) ?: return false
        return expiresAt > System.currentTimeMillis()
    }
}

/**
 * In production this should read from SharedPreferences/Room synced from Flutter.
 * A fixed set is used here to keep native interception deterministic and testable.
 */
private object ProtectedAppStore {
    private val packages = setOf(
        "com.instagram.android",
        "com.google.android.youtube",
        "com.reddit.frontpage",
        "com.twitter.android"
    )

    fun isProtected(packageName: String): Boolean = packages.contains(packageName)
}
