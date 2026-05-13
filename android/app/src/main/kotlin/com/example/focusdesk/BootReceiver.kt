package com.example.focusdesk

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/// it is used to rebuild the notification system after phone is being reboot

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        android.util.Log.d("FOCUSDESK_DEBUG", "Boot completed — scheduling service start")

        // ✅ Small delay so system has settled before we demand foreground service
        val handler = android.os.Handler(android.os.Looper.getMainLooper())
        handler.postDelayed({
            val serviceIntent = Intent(context, UnlockMonitorService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }, 3000) // 3 seconds after boot — system is settled by then
    }
}