import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart'; // 1. ADD THIS IMPORT
import 'package:shared_preferences/shared_preferences.dart';

class NotificationBridge {
  static const _bridgeKey = 'focusdesk_notif_state';

  // 2. DEFINE THE CHANNEL (Matches the one in MainActivity)
  static const MethodChannel _channel = MethodChannel('com.example.focusdesk/settings');

  static Future<void> push({
    required String dateKey,
    required List<String> goals,
    required Map<String, bool> goalStates,
    required int currentStreak,
    required bool reasonGivenForYesterday,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final total = goals.length;
    final completed = goals.where((g) => goalStates[g] == true).length;
    final allDone = total > 0 && completed == total;

    final payload = {
      'date':         dateKey,
      'goals_set':    total > 0,
      'total':        total,
      'completed':    completed,
      'all_done':     allDone,
      'streak':       currentStreak,
      'reason_given': reasonGivenForYesterday,
      'updated_at':   DateTime.now().toUtc().toIso8601String(),
    };

    await prefs.setString(_bridgeKey, jsonEncode(payload));
    log("[NotificationBridge] Pushed state → $payload");

    // 3. FIRE THE PING TO KOTLIN
    try {
      await _channel.invokeMethod('updateSticky');
      log("[NotificationBridge] Pinged Kotlin to update notification!");
    } catch (e) {
      log("[NotificationBridge] Failed to ping Kotlin: $e");
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bridgeKey);
    log("[NotificationBridge] Cleared.");
  }
}