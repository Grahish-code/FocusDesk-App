package com.example.focusdesk

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

// =============================================================
// OverlayService — The 9AM Floating Popup
// =============================================================

class OverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var overlayView: View?            = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        android.util.Log.d("FOCUSDESK", "OverlayService started — drawing popup")

        if (!Settings.canDrawOverlays(this)) {
            android.util.Log.w("FOCUSDESK", "Overlay permission not granted — stopping")
            stopSelf()
            return START_NOT_STICKY
        }

        drawOverlay()
        return START_NOT_STICKY
    }

    private fun drawOverlay() {
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(64, 64, 64, 56)
            background = buildCardBackground()
        }

        val emoji = TextView(this).apply {
            text     = "🎯"
            setTextSize(36f)
            gravity  = Gravity.CENTER
        }

        val headline = TextView(this).apply {
            text      = "Hey, time to set your goals!"
            setTextSize(18f)
            setTextColor(Color.parseColor("#1A1A2E"))
            gravity   = Gravity.CENTER
            typeface  = android.graphics.Typeface.DEFAULT_BOLD
            setPadding(0, 24, 0, 0)
        }

        val body = TextView(this).apply {
            text      = "Setting your goals is the first thing.\n\nThis helps you stay focused toward what actually matters."
            setTextSize(14f)
            setTextColor(Color.parseColor("#4A4A6A"))
            gravity   = Gravity.CENTER
            setLineSpacing(0f, 1.4f)
            setPadding(0, 20, 0, 0)
        }

        val divider = View(this).apply {
            setBackgroundColor(Color.parseColor("#E8E8F0"))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 1
            ).apply { setMargins(0, 40, 0, 32) }
        }

        val openBtn = Button(this).apply {
            text            = "Open FocusDesk"
            setTextSize(15f)
            setTextColor(Color.WHITE)
            background      = buildButtonBackground("#4361EE")
            setPadding(0, 28, 0, 28)
            layoutParams    = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            setOnClickListener { onOpenFocusDesk() }
        }

        val laterBtn = Button(this).apply {
            text            = "I'll do it later"
            setTextSize(14f)
            setTextColor(Color.parseColor("#9090B0"))
            setBackgroundColor(Color.TRANSPARENT)
            layoutParams    = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(0, 12, 0, 0) }
            setOnClickListener { onDismiss() }
        }

        card.addView(emoji)
        card.addView(headline)
        card.addView(body)
        card.addView(divider)
        card.addView(openBtn)
        card.addView(laterBtn)

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            android.graphics.PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.BOTTOM
            x       = 0
            y       = 120
        }

        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity     = Gravity.BOTTOM
            setBackgroundColor(Color.parseColor("#99000000"))
            setPadding(32, 0, 32, 48)
            addView(card)
        }

        val fullScreenParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            android.graphics.PixelFormat.TRANSLUCENT
        )

        overlayView = container
        try {
            windowManager?.addView(container, fullScreenParams)
            android.util.Log.d("FOCUSDESK", "Overlay drawn successfully")
        } catch (e: Exception) {
            android.util.Log.e("FOCUSDESK", "Failed to draw overlay: ${e.message}")
            stopSelf()
        }
    }

    private fun onOpenFocusDesk() {
        android.util.Log.d("FOCUSDESK", "User tapped Open FocusDesk")
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        if (launchIntent != null) startActivity(launchIntent)
        dismissAndStop()
    }

    private fun onDismiss() {
        android.util.Log.d("FOCUSDESK", "User tapped I'll do it later")
        dismissAndStop()
    }

    private fun dismissAndStop() {
        removeOverlayView()
        stopSelf()
    }

    private fun removeOverlayView() {
        try {
            overlayView?.let { windowManager?.removeView(it) }
            overlayView = null
        } catch (e: Exception) {
            android.util.Log.e("FOCUSDESK", "Error removing overlay: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        removeOverlayView()
        android.util.Log.d("FOCUSDESK", "OverlayService destroyed — popup dismissed")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildCardBackground(): GradientDrawable {
        return GradientDrawable().apply {
            shape       = GradientDrawable.RECTANGLE
            setColor(Color.WHITE)
            cornerRadius = 48f
        }
    }

    private fun buildButtonBackground(hexColor: String): GradientDrawable {
        return GradientDrawable().apply {
            shape        = GradientDrawable.RECTANGLE
            setColor(Color.parseColor(hexColor))
            cornerRadius = 32f
        }
    }
}