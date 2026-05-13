package com.example.focusdesk

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.util.Calendar

class UnlockMonitorService : Service() {

    private val STICKY_CHANNEL_ID = "focusdesk_sticky_channel"
    private val ALERT_CHANNEL_ID  = "focusdesk_alert_channel"
    private val PREFS_NAME        = "FlutterSharedPreferences"
    private val BRIDGE_KEY        = "flutter.focusdesk_notif_state"
    private val KEY_PENDING_TITLE = "flutter.focusdesk_pending_title"
    private val KEY_PENDING_BODY  = "flutter.focusdesk_pending_body"
    private val KEY_PENDING_ID    = "flutter.focusdesk_pending_id"

    private var isReceiverRegistered = false

    // ─────────────────────────────────────────────────────────────────
    // UNLOCK RECEIVER
    // Fires when user unlocks phone — delivers any parked notification
    // ─────────────────────────────────────────────────────────────────
    private val unlockReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            android.util.Log.d("FOCUSDESK", "Unlock receiver fired: ${intent?.action}")
            val keyguard = getSystemService(Context.KEYGUARD_SERVICE)
                    as android.app.KeyguardManager
            if (!keyguard.isKeyguardLocked) {
                firePendingIfExists()
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // LIFECYCLE — onCreate runs ONCE per service instance
    // All one-time setup goes here, never in onStartCommand
    // ─────────────────────────────────────────────────────────────────
    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()   // must exist before startForeground
        startForegroundWithSticky()    // must call within 5s on Android 8+
        registerUnlockReceiver()       // register once, unregister in onDestroy
        scheduleDailyCheckpoints()     // ✅ FIXED: was in onStartCommand else branch
        // which ACTION_UPDATE_STICKY never reached
        android.util.Log.d("FOCUSDESK", "Service created — alarms scheduled")
    }

    // ─────────────────────────────────────────────────────────────────
    // onStartCommand — action routing ONLY
    // Never registers receivers or schedules alarms here
    // ─────────────────────────────────────────────────────────────────
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        android.util.Log.d("FOCUSDESK", "onStartCommand action: $action")

        when (action) {
            ACTION_CHECKPOINT    -> handleCheckpoint()
            ACTION_MIDNIGHT      -> handleMidnightReset()
            ACTION_UPDATE_STICKY -> updateStickyNotification()
            // null = sticky restart after being killed by OS
            // service just needs to be alive — alarms already set in onCreate
            else -> updateStickyNotification()
        }

        return START_STICKY
    }

    // ─────────────────────────────────────────────────────────────────
    // READ BRIDGE — single source of truth from Flutter
    // ─────────────────────────────────────────────────────────────────
    private fun readBridgeState(): BridgeState? {
        return try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val json  = prefs.getString(BRIDGE_KEY, null) ?: return null
            val obj   = JSONObject(json)
            BridgeState(
                date        = obj.optString("date", ""),
                goalsSet    = obj.optBoolean("goals_set", false),
                total       = obj.optInt("total", 0),
                completed   = obj.optInt("completed", 0),
                allDone     = obj.optBoolean("all_done", false),
                streak      = obj.optInt("streak", 0),
                reasonGiven = obj.optBoolean("reason_given", false)
            )
        } catch (e: Exception) {
            android.util.Log.e("FOCUSDESK", "Failed to read bridge state", e)
            null
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // CHECKPOINT HANDLER
    // Runs at 9AM, 12PM, 6PM, 10:30PM
    // ─────────────────────────────────────────────────────────────────
    private fun handleCheckpoint() {
        // ✅ FIXED: removed stopService(OverlayService) from here
        // It was killing the overlay before it even had a chance to show

        val now         = Calendar.getInstance()
        val currentHour = now.get(Calendar.HOUR_OF_DAY)
        val currentMin  = now.get(Calendar.MINUTE)

        android.util.Log.d("FOCUSDESK", "Checkpoint at $currentHour:$currentMin")

        val state = readBridgeState()

        if (state == null) {
            android.util.Log.w("FOCUSDESK", "Bridge state null — no notification fired")
            updateStickyNotification()
            return
        }

        android.util.Log.d("FOCUSDESK",
            "Bridge: goals_set=${state.goalsSet}, " +
                    "${state.completed}/${state.total}, " +
                    "all_done=${state.allDone}, streak=${state.streak}")

        // Build the notification payload for this time slot
        val payload = buildNotificationPayload(currentHour, currentMin, state)

        if (payload == null) {
            android.util.Log.d("FOCUSDESK", "No notification needed at $currentHour:$currentMin")
            updateStickyNotification()
            return
        }

        // Check if phone is locked
        val keyguard = getSystemService(Context.KEYGUARD_SERVICE)
                as android.app.KeyguardManager

        if (!keyguard.isKeyguardLocked) {
            // Phone is unlocked — fire immediately
            android.util.Log.d("FOCUSDESK", "Phone unlocked — firing immediately")
            fireNotification(payload)
            clearPendingSlot()

            // ✅ FIXED: 9AM overlay — show AFTER firing notification, not before
            // Removed the stopService call that was killing it prematurely
            if (currentHour == 9 && !state.goalsSet) {
                android.util.Log.d("FOCUSDESK", "9AM — showing overlay")
                showNativeOverlay()
            }
        } else {
            // Phone is locked — park it, fire on next unlock
            android.util.Log.d("FOCUSDESK", "Phone locked — parking notification")
            parkInPendingSlot(payload)
        }

        updateStickyNotification()
    }

    // ─────────────────────────────────────────────────────────────────
    // FIRE PARKED NOTIFICATION ON UNLOCK
    // ─────────────────────────────────────────────────────────────────
    private fun firePendingIfExists() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val title = prefs.getString(KEY_PENDING_TITLE, null)
        val body  = prefs.getString(KEY_PENDING_BODY,  null)
        val id    = prefs.getInt(KEY_PENDING_ID, -1)

        if (title == null || body == null || id == -1) {
            android.util.Log.d("FOCUSDESK", "Pending slot empty — nothing to fire")
            return
        }

        android.util.Log.d("FOCUSDESK", "Firing parked notification: $title")
        fireNotification(NotifPayload(id, title, body))
        clearPendingSlot()

        // If it was the 9AM notification and goals still not set, show overlay too
        if (id == 901) {
            val state = readBridgeState()
            if (state != null && !state.goalsSet) {
                android.util.Log.d("FOCUSDESK", "9AM parked — showing overlay on unlock")
                showNativeOverlay()
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MIDNIGHT RESET
    // ─────────────────────────────────────────────────────────────────
    private fun handleMidnightReset() {
        android.util.Log.d("FOCUSDESK", "Midnight reset — clearing pending slot")
        clearPendingSlot()
        updateStickyNotification()
    }

    // ─────────────────────────────────────────────────────────────────
    // NOTIFICATION PAYLOAD BUILDER
    // Returns null = no notification needed at this time
    // ─────────────────────────────────────────────────────────────────
    private fun buildNotificationPayload(
        hour:   Int,
        minute: Int,
        state:  BridgeState
    ): NotifPayload? {

        // Never fire if all goals already completed
        if (state.allDone) {
            android.util.Log.d("FOCUSDESK", "All goals done — skipping notification")
            return null
        }

        val left = state.total - state.completed

        return when {

            // ── 9:00 AM ───────────────────────────────────────────
            hour == 9 && minute < 30 -> when {
                !state.goalsSet ->
                    NotifPayload(901,
                        "Your day is waiting ☀️",
                        "Set today's goals. Even one small win counts.")
                state.completed == 0 ->
                    NotifPayload(902,
                        "Let's get started 💪",
                        "Your goals are set. Tackle the first one now.")
                else -> null
            }

            // ── 12:00 PM ──────────────────────────────────────────
            hour == 12 && minute < 30 -> when {
                !state.goalsSet ->
                    NotifPayload(1201,
                        "Half the day is still yours ⏳",
                        "Set a goal to keep your ${state.streak} day streak alive.")
                state.completed == 0 ->
                    NotifPayload(1202,
                        "It's noon — time to move 🚀",
                        "Not one goal done yet. Start small, start now.")
                else ->
                    NotifPayload(1203,
                        "Keep going 💥",
                        "${state.completed} of ${state.total} done. You're building momentum.")
            }

            // ── 6:00 PM ───────────────────────────────────────────
            // ✅ FIXED: was hour==21 (9:25PM) which had no matching case
            // Changed schedule to 18:00 so this case actually gets hit
            hour == 18 && minute < 30 -> when {
                !state.goalsSet ->
                    NotifPayload(1801,
                        "Last real chance today 🌆",
                        "It's 6pm. Set at least one goal before the day ends.")
                else ->
                    NotifPayload(1802,
                        "Evening check-in 🌅",
                        "${state.completed} of ${state.total} done. " +
                                "$left left — you can finish this.")
            }

            // ── 10:30 PM ──────────────────────────────────────────
            hour == 22 && minute >= 30 -> when {
                !state.goalsSet ->
                    NotifPayload(2201,
                        "No goals for today 😔",
                        "Not even a smaller one? Set one now and complete it tonight.")
                else ->
                    NotifPayload(2202,
                        "Streak at risk 🚨",
                        "$left goal${if (left > 1) "s" else ""} left. " +
                                "Protect your ${state.streak} day streak before midnight!")
            }

            // No matching time slot
            else -> null
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // STICKY NOTIFICATION TEXT
    // ─────────────────────────────────────────────────────────────────
    private fun buildStickyText(): String {
        val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
        if (hour in 0..5) return "Rest well. FocusDesk starts fresh tomorrow."

        val state = readBridgeState() ?: return "FocusDesk is active."

        return when {
            !state.goalsSet -> "Set your goals for today to get started."
            state.allDone   -> "All goals done today! Great work 🎉"
            else            -> "${state.completed} of ${state.total} goals completed today."
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // ALARM SCHEDULING
    // Called once in onCreate — sets all 5 daily alarms
    // ─────────────────────────────────────────────────────────────────
    fun scheduleDailyCheckpoints() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
            && !alarmManager.canScheduleExactAlarms()) {
            android.util.Log.w("FOCUSDESK", "Exact alarm permission missing — alarms not set")
            return
        }

        // ✅ FIXED: 21:25 → 18:00 so 6PM case in buildNotificationPayload is reachable
        scheduleCheckpoint(alarmManager, 9,  0,  100, ACTION_CHECKPOINT)
        scheduleCheckpoint(alarmManager, 12, 0,  101, ACTION_CHECKPOINT)
        scheduleCheckpoint(alarmManager, 18, 0,  102, ACTION_CHECKPOINT)
        scheduleCheckpoint(alarmManager, 22, 30, 103, ACTION_CHECKPOINT)
        scheduleCheckpoint(alarmManager, 0,  0,  104, ACTION_MIDNIGHT)

        android.util.Log.d("FOCUSDESK",
            "Alarms set: 9:00, 12:00, 18:00, 22:30, 00:00")
    }

    private fun scheduleCheckpoint(
        alarmManager: AlarmManager,
        hour: Int,
        minute: Int,
        requestCode: Int,
        action: String
    ) {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            // If this time has already passed today, schedule for tomorrow
            if (before(Calendar.getInstance())) {
                add(Calendar.DAY_OF_YEAR, 1)
            }
        }

        val intent = Intent(this, AlarmTickReceiver::class.java).apply {
            this.action = action
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            calendar.timeInMillis,
            pendingIntent
        )

        android.util.Log.d("FOCUSDESK",
            "Alarm set: $action at $hour:${minute.toString().padStart(2, '0')}")
    }

    // ─────────────────────────────────────────────────────────────────
    // PENDING SLOT HELPERS
    // ─────────────────────────────────────────────────────────────────
    private fun parkInPendingSlot(payload: NotifPayload) {
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
            .putString(KEY_PENDING_TITLE, payload.title)
            .putString(KEY_PENDING_BODY,  payload.body)
            .putInt(KEY_PENDING_ID,       payload.id)
            .apply()
        android.util.Log.d("FOCUSDESK", "Parked: [${payload.id}] ${payload.title}")
    }

    private fun clearPendingSlot() {
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
            .remove(KEY_PENDING_TITLE)
            .remove(KEY_PENDING_BODY)
            .remove(KEY_PENDING_ID)
            .apply()
        android.util.Log.d("FOCUSDESK", "Pending slot cleared")
    }

    private fun fireNotification(payload: NotifPayload) {
        val notification = NotificationCompat.Builder(this, ALERT_CHANNEL_ID)
            .setContentTitle(payload.title)
            .setContentText(payload.body)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setAutoCancel(true)
            .build()
        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .notify(payload.id, notification)
        android.util.Log.d("FOCUSDESK", "Fired [${payload.id}]: ${payload.title}")
    }

    // ─────────────────────────────────────────────────────────────────
    // FOREGROUND STICKY
    // ─────────────────────────────────────────────────────────────────
    private fun startForegroundWithSticky() {
        val notification = NotificationCompat.Builder(this, STICKY_CHANNEL_ID)
            .setContentTitle("FocusDesk")
            .setContentText(buildStickyText())
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(1, notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(1, notification)
        }
    }

    private fun updateStickyNotification() {
        val notification = NotificationCompat.Builder(this, STICKY_CHANNEL_ID)
            .setContentTitle("FocusDesk")
            .setContentText(buildStickyText())
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .build()
        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .notify(1, notification)
    }

    // ─────────────────────────────────────────────────────────────────
    // RECEIVER REGISTRATION — guarded, never double-registers
    // ─────────────────────────────────────────────────────────────────
    private fun registerUnlockReceiver() {
        if (isReceiverRegistered) return
        try {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_USER_PRESENT)
                addAction(Intent.ACTION_SCREEN_ON)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(unlockReceiver, filter, RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(unlockReceiver, filter)
            }
            isReceiverRegistered = true
            android.util.Log.d("FOCUSDESK", "Unlock receiver registered")
        } catch (e: Exception) {
            android.util.Log.e("FOCUSDESK", "Failed to register receiver: ${e.message}")
        }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(
                NotificationChannel(
                    STICKY_CHANNEL_ID,
                    "FocusDesk Background",
                    NotificationManager.IMPORTANCE_LOW
                )
            )
            manager.createNotificationChannel(
                NotificationChannel(
                    ALERT_CHANNEL_ID,
                    "FocusDesk Alerts",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    enableVibration(true)
                }
            )
        }
    }

    private fun showNativeOverlay() {
        try {
            startService(Intent(this, OverlayService::class.java))
            android.util.Log.d("FOCUSDESK", "Overlay service started")
        } catch (e: Exception) {
            android.util.Log.e("FOCUSDESK", "Failed to start overlay: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isReceiverRegistered) {
            try {
                unregisterReceiver(unlockReceiver)
                isReceiverRegistered = false
            } catch (e: Exception) {
                android.util.Log.e("FOCUSDESK", "Unregister failed: ${e.message}")
            }
        }
        android.util.Log.d("FOCUSDESK", "Service destroyed")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // ─────────────────────────────────────────────────────────────────
    // DATA CLASSES
    // ─────────────────────────────────────────────────────────────────
    data class BridgeState(
        val date:        String,
        val goalsSet:    Boolean,
        val total:       Int,
        val completed:   Int,
        val allDone:     Boolean,
        val streak:      Int,
        val reasonGiven: Boolean
    )

    data class NotifPayload(val id: Int, val title: String, val body: String)

    companion object {
        const val ACTION_CHECKPOINT    = "com.example.focusdesk.ACTION_CHECKPOINT"
        const val ACTION_MIDNIGHT      = "com.example.focusdesk.ACTION_MIDNIGHT"
        const val ACTION_BOOT          = "com.example.focusdesk.ACTION_BOOT"
        const val ACTION_UPDATE_STICKY = "com.example.focusdesk.ACTION_UPDATE_STICKY"
    }
}