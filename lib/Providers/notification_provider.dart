import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focusdesk/models/notification_event.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationBridge> _notifications = [];
  bool _hasNewNotifications = false;
  StreamSubscription? _subscription;

  static const _methodChannel = MethodChannel('com.example.focusdesk/settings');
  static const _eventChannel = EventChannel('com.example.focusdesk/notifications');

  List<NotificationBridge> get notifications => _notifications;
  bool get hasNewNotifications => _hasNewNotifications;

  // =============================================================
  // KOTLIN BRIDGE LOGIC
  // =============================================================

  /// Starts the Android background service when the app opens.
  /// Call this once during your app initialization (e.g., in main.dart).
  Future<void> startAndroidBackgroundService() async {
    try {
      await _methodChannel.invokeMethod('startUnlockMonitor');
      log("Android UnlockMonitorService started successfully.");
    } catch (e) {
      log("Failed to start Android service: $e");
    }
  }

  /// Syncs the current goal state to Android SharedPreferences.
  /// Call this whenever a goal is added, completed, or updated.
  Future<void> syncGoalStateToAndroid({
    required bool goalsSet,
    required int total,
    required int completed,
    required bool allDone,
    required int streak,
    required bool reasonGiven,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      final Map<String, dynamic> stateMap = {
        "date": now.toIso8601String().split('T').first,
        "goals_set": goalsSet,
        "total": total,
        "completed": completed,
        "all_done": allDone,
        "streak": streak,
        "reason_given": reasonGiven,
        "updated_at": now.toIso8601String(),
      };

      final String stateJson = jsonEncode(stateMap);

      // Saves to 'flutter.focusdesk_notif_state' under the hood
      await prefs.setString('focusdesk_notif_state', stateJson);
      log("Synced bridge state to Android: $stateJson");
    } catch (e) {
      log("Error syncing state to Android: $e");
    }
  }

  // =============================================================
  // ORIGINAL NOTIFICATION LISTENER LOGIC
  // =============================================================

  void startListeningToNotifications() {
    try {
      _subscription = _eventChannel.receiveBroadcastStream().listen((dynamic event) {
        if (event is Map) {
          final String action = event['action'] ?? 'POST';
          final String? id = event['id'];
          if (id == null) return;

          if (action == "REMOVE") {
            _notifications.removeWhere((n) => n.id == id);
            if (_notifications.isEmpty) _hasNewNotifications = false;
          } else {
            final String? title = event['title'], text = event['text'];
            if (title == null || text == null) return;

            final int idx = _notifications.indexWhere((n) => n.id == id);
            if (idx != -1) {
              _notifications[idx] = NotificationBridge(id: id, packageName: event['package'] ?? "", title: title, text: text, createAt: DateTime.now());
            } else {
              _notifications.insert(0, NotificationBridge(id: id, packageName: event['package'] ?? "", title: title, text: text, createAt: DateTime.now()));
              _hasNewNotifications = true;
            }
          }
          notifyListeners();
        }
      });
    } catch (e) { log("Notification Error: $e"); }
  }

  void stopListening() => _subscription?.cancel();

  Future<void> openNotificationSettings() async {
    await _methodChannel.invokeMethod('openSettings');
  }

  Future<void> openAppFromNotification(String? pkg) async {
    if (pkg != null) await LaunchApp.openApp(androidPackageName: pkg);
  }

  void dismissNotification(int i) {
    _notifications.removeAt(i);
    notifyListeners();
  }

  void dismissNotificationById(String id) {
    _notifications.removeWhere((n) => n.id == id);
    if (_notifications.isEmpty) _hasNewNotifications = false;
    notifyListeners();
  }

  void markNotificationsAsRead() {
    _hasNewNotifications = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}