//package com.example.focusdesk
//
//import android.app.Notification
//import android.app.NotificationManager
//import android.content.Intent
//import android.service.notification.NotificationListenerService
//import android.service.notification.StatusBarNotification
//
//class FocusNotificationListener : NotificationListenerService() {
//
//    // ... (Your VIP and BLACKLIST sets remain the same) ...
//    private val VIP_PACKAGES = setOf(
//        "com.whatsapp",
//        "com.google.android.apps.messaging",
//    )
//
//    private val BLACKLIST_PACKAGES = setOf(
//        "com.amazon.mShop.android.shopping",
//        "com.flipkart.android",
//        "in.swiggy.android",
//        "com.application.zomato",
//        "com.facebook.katana"
//    )
//
//    override fun onNotificationPosted(sbn: StatusBarNotification) {
//        if (!AppState.isAppInForeground) return
//
//        val packageName = sbn.packageName
//
//        // --- 1. THE FILTERING LOGIC (Keep your existing logic here) ---
//        // (I am condensing it for brevity, but paste your logic back in here)
//        if (BLACKLIST_PACKAGES.contains(packageName)) return
//        val notification = sbn.notification
//        val extras = notification.extras
//        if (sbn.isOngoing) return
//        if ((notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0) return
//
//        val category = notification.category
//        val isCommunication = (
//                category == Notification.CATEGORY_EMAIL ||
//                        category == Notification.CATEGORY_MESSAGE ||
//                        category == Notification.CATEGORY_CALL ||
//                        category == Notification.CATEGORY_EVENT ||
//                        category == Notification.CATEGORY_ALARM
//                )
//
//        val ranking = Ranking()
//        var isImportant = false
//        try {
//            currentRanking.getRanking(sbn.key, ranking)
//            isImportant = ranking.importance >= NotificationManager.IMPORTANCE_DEFAULT
//        } catch (e: Exception) {
//            isImportant = true
//        }
//
//        var shouldAllow = false
//        if (VIP_PACKAGES.contains(packageName)) {
//            if (isImportant) shouldAllow = true
//        } else if (isCommunication) {
//            if (isImportant) shouldAllow = true
//        } else {
//            if (ranking.importance >= NotificationManager.IMPORTANCE_HIGH) shouldAllow = true
//        }
//
//        if (!shouldAllow) return
//
//        val title = extras.getString("android.title") ?: return
//        val text = extras.getCharSequence("android.text")?.toString() ?: return
//        if (text.trim().isEmpty()) return
//
//        // --- 2. THE CRITICAL FIX: PASS THE ID AND ACTION ---
//        // We use sbn.key as the unique ID for this notification
//        val uniqueKey = sbn.key
//
//        val intent = Intent("com.example.focusdesk.NOTIFICATION_LISTENER")
//        intent.putExtra("action", "POST") // Mark this as an Add/Update
//        intent.putExtra("id", uniqueKey)  // THE UNIQUE ID
//        intent.putExtra("package", packageName)
//        intent.putExtra("title", title)
//        intent.putExtra("text", text)
//        sendBroadcast(intent)
//    }
//
//    override fun onNotificationRemoved(sbn: StatusBarNotification) {
//        // --- 3. THE DESKTOP SYNC FIX ---
//        // When you read on Desktop, Android removes the notification from the phone.
//        // We catch that here and tell Flutter to delete it too.
//
//        val uniqueKey = sbn.key
//
//        val intent = Intent("com.example.focusdesk.NOTIFICATION_LISTENER")
//        intent.putExtra("action", "REMOVE") // Mark this as a Removal
//        intent.putExtra("id", uniqueKey)
//        sendBroadcast(intent)
//    }
//}


package com.example.focusdesk

import android.app.Notification
import android.app.NotificationManager
import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class FocusNotificationListener : NotificationListenerService() {

    // 1. VIP APPS (Always Allow)
    private val VIP_PACKAGES = setOf(
        "com.whatsapp",
        "com.google.android.apps.messaging", // SMS
    )

    // 2. BLOCKED APPS (Always Block)
    private val BLACKLIST_PACKAGES = setOf(
        "com.amazon.mShop.android.shopping",
        "com.flipkart.android",
        "in.swiggy.android",
        "com.application.zomato",
        "com.facebook.katana"
    )

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        if (!AppState.isAppInForeground) return

        val packageName = sbn.packageName

        // --- FILTER 1: BLACKLIST ---
        if (BLACKLIST_PACKAGES.contains(packageName)) return

        // --- FILTER 2: ONGOING & SUMMARIES ---
        if (sbn.isOngoing) return
        val notification = sbn.notification
        if ((notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0) return

        // --- FILTER 3: CATEGORY CHECK ---
        val category = notification.category
        val isCommunication = (
                category == Notification.CATEGORY_EMAIL ||
                        category == Notification.CATEGORY_MESSAGE ||
                        category == Notification.CATEGORY_CALL ||
                        category == Notification.CATEGORY_EVENT ||
                        category == Notification.CATEGORY_ALARM
                )

        // --- FILTER 4: IMPORTANCE CHECK ---
        val ranking = Ranking()
        var isImportant = false
        try {
            currentRanking.getRanking(sbn.key, ranking)
            isImportant = ranking.importance >= NotificationManager.IMPORTANCE_DEFAULT
        } catch (e: Exception) {
            isImportant = true
        }

        // --- FINAL DECISION ---
        var shouldAllow = false
        if (VIP_PACKAGES.contains(packageName)) {
            if (isImportant) shouldAllow = true
        } else if (isCommunication) {
            if (isImportant) shouldAllow = true
        } else {
            if (ranking.importance >= NotificationManager.IMPORTANCE_HIGH) shouldAllow = true
        }

        if (!shouldAllow) return

        // --- EXTRACT DATA ---
        val extras = notification.extras
        val title = extras.getString("android.title") ?: return
        val text = extras.getCharSequence("android.text")?.toString() ?: return

        if (text.trim().isEmpty()) return

        // --- *** THE FIX IS HERE *** ---
        // SPAM FIX: We create a "Smart ID" combining Package + Title (Sender).
        // Messages from "Nirmiti" will now ALWAYS have the ID "com.whatsapp|Nirmiti".
        val smartId = "$packageName|$title"

        val intent = Intent("com.example.focusdesk.NOTIFICATION_LISTENER")
        intent.putExtra("action", "POST")
        intent.putExtra("id", smartId) // Use Smart ID, NOT sbn.key
        intent.putExtra("package", packageName)
        intent.putExtra("title", title)
        intent.putExtra("text", text)
        sendBroadcast(intent)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        // --- DESKTOP SYNC FIX ---
        // When removed from phone, we reconstruct the Smart ID to remove it from Flutter too.
        val extras = sbn.notification.extras
        val title = extras.getString("android.title")
        val packageName = sbn.packageName

        if (title != null) {
            val smartId = "$packageName|$title"

            val intent = Intent("com.example.focusdesk.NOTIFICATION_LISTENER")
            intent.putExtra("action", "REMOVE")
            intent.putExtra("id", smartId)
            sendBroadcast(intent)
        }
    }
}