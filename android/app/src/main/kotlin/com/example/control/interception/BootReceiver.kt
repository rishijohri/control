package com.example.control.interception

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Boot receiver placeholder.
 *
 * On real devices we use this to reschedule background monitoring jobs,
 * restore focus mode schedules, and re-initialize reliability safeguards after reboot.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // Reserved for future start-up work. Keeping receiver explicit prevents OEM drops.
        }
    }
}
