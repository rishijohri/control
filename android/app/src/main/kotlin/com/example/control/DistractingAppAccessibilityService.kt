package com.example.control

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.Build
import android.view.accessibility.AccessibilityEvent
import kotlin.math.abs

class DistractingAppAccessibilityService : AccessibilityService() {

    private companion object {
        const val REOPEN_RETRIGGER_WINDOW_MS = 15L * 60L * 1000L
        const val MIN_SCROLL_DELTA_FOR_GESTURE = 24
        const val MIN_GESTURES_FOR_SHORT_FORM_TRIGGER = 8
    }

    private val ignoredPackages = setOf(
        "com.android.systemui",
        "com.google.android.apps.nexuslauncher",
        "com.android.launcher",
        "com.example.control"
    )

    private var lastPackage = ""
    private var lastPackageSeenAtMs = 0L
    private val shortFormGestureTimesMsByPackage = mutableMapOf<String, ArrayDeque<Long>>()

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        val eventType = event.eventType
        val packageName = event.packageName?.toString() ?: return
        val nowMs = System.currentTimeMillis()

        if (
            eventType == AccessibilityEvent.TYPE_VIEW_SCROLLED &&
            InterceptionConfigStore.isShortFormDetectionEnabled(this)
        ) {
            maybeTriggerShortFormIntervention(event, packageName, nowMs)
        }

        if (
            eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            eventType != AccessibilityEvent.TYPE_WINDOWS_CHANGED
        ) {
            return
        }

        if (packageName in ignoredPackages) {
            lastPackage = packageName
            lastPackageSeenAtMs = nowMs
            return
        }

        val sameAsLastPackage = packageName == lastPackage
        val shouldRetriggerAfterLongBackground =
            sameAsLastPackage && (nowMs - lastPackageSeenAtMs) >= REOPEN_RETRIGGER_WINDOW_MS

        if (sameAsLastPackage && !shouldRetriggerAfterLongBackground) {
            // Ignore transitions inside the same app (tabs, activities, dialogs).
            lastPackageSeenAtMs = nowMs
            return
        }

        lastPackage = packageName
        lastPackageSeenAtMs = nowMs

        if (!InterceptionConfigStore.isProtected(this, packageName)) return
        if (InterceptionConfigStore.wasRecentlyAllowedOpen(this, packageName)) return

        launchIntervention(packageName)
    }

    private fun maybeTriggerShortFormIntervention(
        event: AccessibilityEvent,
        packageName: String,
        nowMs: Long
    ) {
        if (packageName in ignoredPackages) return
        if (!InterceptionConfigStore.isProtected(this, packageName)) return
        if (InterceptionConfigStore.wasRecentlyAllowedOpen(this, packageName)) return

        val deltaY = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            event.scrollDeltaY
        } else {
            val indexDelta = event.toIndex - event.fromIndex
            if (indexDelta == 0) 0 else MIN_SCROLL_DELTA_FOR_GESTURE
        }
        if (abs(deltaY) < MIN_SCROLL_DELTA_FOR_GESTURE) {
            return
        }

        val triggerAfterSeconds =
            InterceptionConfigStore.getShortFormInterruptionAfterSeconds(this)
        val windowMs = triggerAfterSeconds * 1000L
        val queue = shortFormGestureTimesMsByPackage.getOrPut(packageName) { ArrayDeque() }

        queue.addLast(nowMs)
        while (queue.isNotEmpty() && nowMs - queue.first() > windowMs) {
            queue.removeFirst()
        }

        if (queue.size < MIN_GESTURES_FOR_SHORT_FORM_TRIGGER) {
            return
        }

        queue.clear()
        launchIntervention(packageName)
    }

    private fun launchIntervention(packageName: String) {
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
