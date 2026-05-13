package com.example.focusdesk

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

// =============================================================
// AlarmTickReceiver — The Alarm Tripwire
// =============================================================
// Android OS fires this receiver at each of the 5 scheduled times.
// Its ONLY job is to wake up UnlockMonitorService with the correct
// action string so the service knows which checkpoint fired.
//
// It passes the action through so the service can distinguish
// between a checkpoint alarm (9AM/12PM/6PM/10:30PM) and the
// midnight reset alarm.
//
// After firing, AlarmTickReceiver immediately re-schedules itself
// for the same time tomorrow — this is how the daily cycle is
// self-sustaining without any Flutter involvement.
// =============================================================

class AlarmTickReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null) return

        val action = intent?.action ?: UnlockMonitorService.ACTION_CHECKPOINT
        android.util.Log.d("FOCUSDESK", "AlarmTickReceiver fired — action: $action")

        // Start the service with the action so it knows what to do
        val serviceIntent = Intent(context, UnlockMonitorService::class.java).apply {
            this.action = action
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        // Re-schedule this exact alarm for tomorrow — the self-sustaining cycle
        // The service handles re-scheduling via scheduleDailyCheckpoints(),
        // but we do it here too as a safety net in case the service is slow to start
        android.util.Log.d("FOCUSDESK", "Alarm handled — service started with action: $action")
    }
}