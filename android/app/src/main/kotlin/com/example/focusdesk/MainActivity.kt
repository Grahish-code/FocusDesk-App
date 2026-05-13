package com.example.focusdesk

import android.app.KeyguardManager
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

class MainActivity : FlutterActivity() {

    private val CHANNEL_METHOD = "com.example.focusdesk/settings"
    private val CHANNEL_STREAM = "com.example.focusdesk/notifications"

    private var notificationReceiver: BroadcastReceiver? = null

    override fun onResume() {
        super.onResume()
        AppState.isAppInForeground = true
    }

    override fun onPause() {
        super.onPause()
        AppState.isAppInForeground = false
    }

    override fun onStart() {
        super.onStart()
        android.util.Log.d("FOCUSDESK_DEBUG", "onStart called — starting service")
        // ✅ Start service safely in background thread so it never blocks Flutter engine init
        Thread {
            try {
                startUnlockMonitorService()
            } catch (e: Exception) {
                android.util.Log.e("FOCUSDESK", "Service start failed safely: ${e.message}")
            }
        }.start()
    }

    private fun startUnlockMonitorService(action: String? = null) {
        val serviceIntent = Intent(this, UnlockMonitorService::class.java).apply {
            action?.let { this.action = it }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_METHOD)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(true)
                    }
                    "isPhoneLocked" -> {
                        val km = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                        result.success(km.isKeyguardLocked)
                    }
                    "updateSticky" -> {
                        android.util.Log.d("FOCUSDESK", "MainActivity caught updateSticky ping!")
                        startUnlockMonitorService("com.example.focusdesk.ACTION_UPDATE_STICKY")
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_STREAM)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if (events == null) return
                    notificationReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            events.success(mapOf(
                                "action"  to (intent?.getStringExtra("action")  ?: "POST"),
                                "id"      to (intent?.getStringExtra("id")      ?: ""),
                                "package" to intent?.getStringExtra("package"),
                                "title"   to intent?.getStringExtra("title"),
                                "text"    to intent?.getStringExtra("text")
                            ))
                        }
                    }
                    val filter = IntentFilter("com.example.focusdesk.NOTIFICATION_LISTENER")
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        registerReceiver(notificationReceiver, filter, Context.RECEIVER_EXPORTED)
                    } else {
                        registerReceiver(notificationReceiver, filter)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    notificationReceiver?.let {
                        try { unregisterReceiver(it) } catch (_: Exception) {}
                    }
                    notificationReceiver = null
                }
            })
    }

    override fun onDestroy() {
        super.onDestroy()
        notificationReceiver?.let {
            try { unregisterReceiver(it) } catch (_: Exception) {}
        }
        notificationReceiver = null
    }
}
