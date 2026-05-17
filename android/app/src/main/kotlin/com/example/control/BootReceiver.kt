package com.example.control

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED || intent?.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            // Touching shared preferences here helps keep interception config warm
            // after reboot/updates without launching UI in the background.
            context.getSharedPreferences("control_interception", Context.MODE_PRIVATE)
        }
    }
}
