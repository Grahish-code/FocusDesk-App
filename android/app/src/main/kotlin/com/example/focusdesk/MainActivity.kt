package com.example.focusdesk

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    // 1. DEFINE TWO DIFFERENT CHANNEL NAMES
    private val CHANNEL_METHOD = "com.example.focusdesk/settings"       // For Buttons
    private val CHANNEL_STREAM = "com.example.focusdesk/notifications"  // For Data

    // --- NEW: TRACK APP VISIBILITY ---
    override fun onResume() {
        super.onResume()
        // App is Open: Turn the listener ON
        AppState.isAppInForeground = true
    }

    override fun onPause() {
        super.onPause()
        // App is Minimized/Closed: Turn the listener OFF
        AppState.isAppInForeground = false
    }
    // ---------------------------------

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 2. SETUP THE METHOD CHANNEL (For opening settings)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_METHOD).setMethodCallHandler { call, result ->
            if (call.method == "openSettings") {
                startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                result.success(true)
            } else {
                result.notImplemented()
            }
        }

// 3. SETUP THE EVENT CHANNEL (For listening to notifications)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_STREAM).setStreamHandler(
            object : EventChannel.StreamHandler {
                private var receiver: BroadcastReceiver? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if (events == null) return

                    receiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            // --- CHANGED SECTION START ---
                            // 1. Capture Action and ID (Crucial for fixing spam/ghosts)
                            val action = intent?.getStringExtra("action") ?: "POST"
                            val id = intent?.getStringExtra("id") ?: ""

                            // 2. Capture Data (Allow nulls so we don't crash on REMOVE)
                            val packageName = intent?.getStringExtra("package")
                            val title = intent?.getStringExtra("title")
                            val text = intent?.getStringExtra("text")

                            // 3. Send EVERYTHING to Flutter
                            events.success(mapOf(
                                "action" to action,
                                "id" to id,
                                "package" to packageName,
                                "title" to title,
                                "text" to text
                            ))
                            // --- CHANGED SECTION END ---
                        }
                    }

                    val filter = IntentFilter("com.example.focusdesk.NOTIFICATION_LISTENER")
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
                    } else {
                        registerReceiver(receiver, filter)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    if (receiver != null) {
                        unregisterReceiver(receiver)
                        receiver = null
                    }
                }
            }
        )
    }
}