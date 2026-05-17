package com.example.control

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

class DistractingAppAccessibilityService : AccessibilityService() {

    private val ignoredPackages = setOf(
        "com.android.systemui",
        "com.google.android.apps.nexuslauncher",
        "com.android.launcher",
        "com.example.control"
    )

    private var lastPackage = ""
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return
        if (packageName in ignoredPackages) {
            lastPackage = packageName
            return
        }

        if (packageName == lastPackage) {
            // Ignore transitions inside the same app (tabs, activities, dialogs).
            return
        }
        lastPackage = packageName

        if (!InterceptionConfigStore.isProtected(this, packageName)) return
        if (InterceptionConfigStore.wasRecentlyAllowedOpen(this, packageName)) return

        val appIntent = Intent(this, MainActivity::class.java).apply {
            action = MainActivity.ACTION_SHOW_INTERVENTION
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra(MainActivity.EXTRA_PACKAGE_NAME, packageName)
            putExtra(
                MainActivity.EXTRA_DELAY_SECONDS,
                InterceptionConfigStore.getDelaySeconds(this@DistractingAppAccessibilityService, packageName)
            )
        }
        startActivity(appIntent)

        // Broadcast keeps Flutter listeners in sync even when activity is already visible.
        val broadcast = Intent(MainActivity.ACTION_PROTECTED_APP_LAUNCHED).apply {
            putExtra(MainActivity.EXTRA_PACKAGE_NAME, packageName)
            putExtra(MainActivity.EXTRA_TIMESTAMP, System.currentTimeMillis())
        }
        sendBroadcast(broadcast)
    }

    override fun onInterrupt() {
        // No-op. We do not keep long-running gestures or speech in this service.
    }
}
