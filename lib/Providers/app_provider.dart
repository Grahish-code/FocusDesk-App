import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:developer'; // For logging
import 'package:flutter/services.dart'; // REQUIRED for MethodChannel & EventChannel
import 'package:external_app_launcher/external_app_launcher.dart';

// --- ENUMS ---
enum AppState { loading, nameInput, goalSetting, nightRest, dashboard, failureReason }

class AppProvider extends ChangeNotifier with WidgetsBindingObserver {
  // --- STATE VARIABLES ---
  AppState _currentState = AppState.loading;
  String _userName = "";
  bool _goalsCompleted = false;

  Timer? _timeCheckTimer;

  // 1. DATA STORAGE
  List<String> _savedGoals = [];
  Map<String, bool> _goalStates = {};


  List<String> _wallpaperPaths = [];
  bool _isWallpaperSetupDone = false;

  // 2. GETTERS
  AppState get currentState => _currentState;
  String get userName => _userName;
  bool get goalsCompleted => _goalsCompleted;
  List<String> get savedGoals => _savedGoals;
  Map<String, bool> get goalStates => _goalStates;
  List<String> get wallpaperPaths => _wallpaperPaths;
  bool get isWallpaperSetupDone => _isWallpaperSetupDone;

  // Default value
  String _avatarUrl = "https://api.dicebear.com/9.x/lorelei/png?seed=Sasha";

  // --- NOTIFICATION STATE ---
  List<NotificationEvent> _notifications = [];
  bool _hasNewNotifications = false;

  List<NotificationEvent> get notifications => _notifications;
  bool get hasNewNotifications => _hasNewNotifications;

  // --- NATIVE CHANNELS (Must match MainActivity.kt exactly) ---
  static const _methodChannel = MethodChannel('com.example.focusdesk/settings');      // For Buttons
  static const _eventChannel = EventChannel('com.example.focusdesk/notifications');   // For Data Streams

  String get avatarUrl => _avatarUrl;

  StreamSubscription? _subscription;

  // --- CONSTRUCTOR ---
  AppProvider() {
    // 1. Start listening to App Lifecycle (Background/Foreground changes)
    WidgetsBinding.instance.addObserver(this);
    _initApp();
    // NEW: Check every minute
    _timeCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _refreshTimeCheck();
    });
  }

  // --- DISPOSE (CLEANUP) ---
  @override
  void dispose() {
    // 2. Stop listening to lifecycle changes to prevent memory leaks
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _timeCheckTimer?.cancel(); // <--- Stop the timer
    super.dispose();
  }

  // =========================================================
  // LIFECYCLE LISTENER (THE FIX)
  // =========================================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 3. When the app comes back to the foreground (Resumed)
    if (state == AppLifecycleState.resumed) {
      // Force a re-check of Time and Goals
      _refreshTimeCheck();
    }
  }

  Future<void> _refreshTimeCheck() async {
    // We grab prefs again and run the exact same logic as startup
    final prefs = await SharedPreferences.getInstance();
    await _checkTimeAndGoals(prefs);
    // notifyListeners() is called inside _checkTimeAndGoals, so UI updates automatically
  }

  // =========================================================
  // INITIALIZATION & CORE LOGIC
  // =========================================================
  Future<void> _initApp() async {
    final prefs = await SharedPreferences.getInstance();

    // A. Check Name
    String? name = prefs.getString('playerName');
    if (name == null || name.isEmpty) {
      _currentState = AppState.nameInput;
      notifyListeners();
      return;
    }
    _userName = name;

    String? savedAvatar = prefs.getString('user_avatar_url');
    if (savedAvatar != null && savedAvatar.isNotEmpty) {
      _avatarUrl = savedAvatar;
    }

    // B. Check Wallpaper Memory
    _isWallpaperSetupDone = prefs.getBool('wallpaper_setup_done') ?? false;
    _wallpaperPaths = prefs.getStringList('saved_wallpapers') ?? [];

    // C. Check Time & Goals
    await _checkTimeAndGoals(prefs);
  }

  Future<void> updateAvatar(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Save to phone storage
    await prefs.setString('user_avatar_url', newUrl);

    // 2. Update local state
    _avatarUrl = newUrl;

    // 3. Tell UI to update
    notifyListeners();
  }

  Future<void> _checkTimeAndGoals(SharedPreferences prefs) async {
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayKey = DateFormat('yyyy-MM-dd').format(yesterday);

    // 1. Night Rest (00:00 - 06:00)
    if (now.hour >= 0 && now.hour < 6) {
      await _loadDataForDate(prefs, yesterdayKey);
      _currentState = AppState.nightRest;
      notifyListeners();
      return;
    }

    // 2. Check Yesterday's Accountability
    bool yesterdayHadGoals = prefs.containsKey('goals_$yesterdayKey');

    if (yesterdayHadGoals) {
      bool yesterdayCompleted = prefs.getBool('completed_$yesterdayKey') ?? false;
      bool reasonGiven = prefs.containsKey('reason_$yesterdayKey');

      if (yesterdayCompleted) {
        await _loadDataForDate(prefs, yesterdayKey);
        await _addToHistory(
            date: yesterdayKey,
            isSuccess: true,
            allGoals: _savedGoals,
            goalStatus: _goalStates
        );
      }

      if (!yesterdayCompleted && !reasonGiven) {
        await _loadDataForDate(prefs, yesterdayKey);
        _currentState = AppState.failureReason;
        notifyListeners();
        return;
      }
    }

    // 3. Load Today
    await _loadDataForDate(prefs, todayKey);

    if (_savedGoals.isNotEmpty) {
      _currentState = AppState.dashboard;
    } else {
      _currentState = AppState.goalSetting;
    }
    notifyListeners();
  }

  Future<void> _loadDataForDate(SharedPreferences prefs, String dateKey) async {
    _savedGoals = prefs.getStringList('goals_$dateKey') ?? [];
    _goalsCompleted = prefs.getBool('completed_$dateKey') ?? false;

    _goalStates.clear();
    for (var goal in _savedGoals) {
      _goalStates[goal] = prefs.getBool('status_${dateKey}_$goal') ?? false;
    }
  }

  // =========================================================
  // ACTIONS (Goals, History, Wallpapers)
  // =========================================================

  Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('playerName', name);
    _userName = name;
    await _checkTimeAndGoals(prefs);
  }

  Future<void> saveGoals(List<String> goals) async {
    final prefs = await SharedPreferences.getInstance();
    String dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await prefs.setStringList('goals_$dateKey', goals);
    await prefs.setBool('completed_$dateKey', false);

    for(var goal in goals) {
      await prefs.setBool('status_${dateKey}_$goal', false);
    }

    _savedGoals = goals;
    _goalStates.clear();
    _currentState = AppState.dashboard;
    notifyListeners();
  }

  Future<void> toggleGoalStatus(String goal, bool isDone) async {
    final prefs = await SharedPreferences.getInstance();
    String dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    _goalStates[goal] = isDone;
    await prefs.setBool('status_${dateKey}_$goal', isDone);

    bool allDone = _savedGoals.isNotEmpty && _savedGoals.every((g) => _goalStates[g] == true);
    if (allDone != _goalsCompleted) {
      await prefs.setBool('completed_$dateKey', allDone);
      _goalsCompleted = allDone;
    }
    notifyListeners();
  }

  Future<void> saveWallpapers(List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_wallpapers', paths);
    await prefs.setBool('wallpaper_setup_done', true);

    _wallpaperPaths = paths;
    _isWallpaperSetupDone = true;
    notifyListeners();
  }

  Future<void> submitFailureReason(String reason) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayKey = DateFormat('yyyy-MM-dd').format(yesterday);

    await prefs.setString('reason_$yesterdayKey', reason);

    await _addToHistory(
        date: yesterdayKey,
        isSuccess: false,
        allGoals: _savedGoals,
        goalStatus: _goalStates,
        reason: reason
    );
    await _checkTimeAndGoals(prefs);
  }

  Future<void> _addToHistory({
    required String date,
    required bool isSuccess,
    required List<String> allGoals,
    required Map<String, bool> goalStatus,
    String? reason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? existingJson = prefs.getString('user_history_db');
    List<dynamic> historyList = existingJson != null ? jsonDecode(existingJson) : [];

    bool alreadyExists = historyList.any((record) => record['date'] == date);
    if (alreadyExists) return;

    List<String> completedList = [];
    List<String> incompleteList = [];

    for (var goal in allGoals) {
      if (goalStatus[goal] == true) {
        completedList.add(goal);
      } else {
        incompleteList.add(goal);
      }
    }

    Map<String, dynamic> newRecord = {
      "date": date,
      "status": isSuccess ? "Completed" : "Incomplete",
      "total_goals": allGoals,
      "completed_goals": completedList,
      "incomplete_goals": incompleteList,
      "reason": reason ?? "N/A"
    };

    historyList.add(newRecord);
    await prefs.setString('user_history_db', jsonEncode(historyList));
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String? existingJson = prefs.getString('user_history_db');
    if (existingJson == null) return [];
    List<dynamic> rawList = jsonDecode(existingJson);
    return rawList.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // =========================================================
  // NOTIFICATION LOGIC (NATIVE BRIDGE)
  // =========================================================

  // 1. START LISTENING (Uses EventChannel)
  void startListeningToNotifications() {
    try {
      _subscription = _eventChannel.receiveBroadcastStream().listen((dynamic event) {
        if (event is Map) {
          final String action = event['action'] ?? 'POST';
          final String? id = event['id']; // This is now the "Smart ID" (Package|Title)

          // Safety Check: If we don't have an ID, we can't do anything.
          if (id == null || id.isEmpty) return;

          if (action == "REMOVE") {
            // --- HANDLE REMOVAL ---
            // Synced with Desktop/Phone. If you read it there, it goes away here.
            _notifications.removeWhere((n) => n.id == id);
            if (_notifications.isEmpty) _hasNewNotifications = false;
            notifyListeners();
          }
          else {
            // --- HANDLE POST (Add or Update) ---
            final String? title = event['title'];
            final String? text = event['text'];
            final String pkg = event['package'] ?? "";

            // Ghost Check: If title or text is null, ignore it.
            if (title == null || text == null) return;

            // DEDUPLICATION: Check if we already have a row for this Sender (Smart ID)
            final int existingIndex = _notifications.indexWhere((n) => n.id == id);

            if (existingIndex != -1) {
              // UPDATE: We found the sender. Update the text.
              // This solves the "10 messages" spam. It just updates the same row 10 times.
              _notifications[existingIndex] = NotificationEvent(
                id: id,
                packageName: pkg,
                title: title,
                text: text,
                createAt: DateTime.now(),
              );

              // Optional: Move the updated conversation to the top
              final updatedItem = _notifications.removeAt(existingIndex);
              _notifications.insert(0, updatedItem);
            } else {
              // INSERT: New sender we haven't seen yet.
              _notifications.insert(0, NotificationEvent(
                id: id,
                packageName: pkg,
                title: title,
                text: text,
                createAt: DateTime.now(),
              ));
              _hasNewNotifications = true;
            }
            notifyListeners();
          }
        }
      }, onError: (dynamic error) {
        debugPrint("Native Bridge Error: $error");
      });
    } catch (e) {
      debugPrint("Error connecting to notification stream: $e");
    }
  }

  // 2. STOP LISTENING
  void stopListening() {
    _subscription?.cancel();
  }

  // 3. OPEN SETTINGS (Uses MethodChannel)
  Future<void> openNotificationSettings() async {
    try {
      await _methodChannel.invokeMethod('openSettings');
    } catch (e) {
      debugPrint("Failed to open settings: $e");
    }
  }

  // 4. OPEN APP (Uses external_app_launcher)
  Future<void> openAppFromNotification(String? packageName) async {
    if (packageName != null) {
      try {
        await LaunchApp.openApp(
          androidPackageName: packageName,
          openStore: false,
        );
      } catch (e) {
        log("Error opening app: $e");
      }
    }
  }

  // 5. DISMISS NOTIFICATION
  void dismissNotification(int index) {
    if (index >= 0 && index < _notifications.length) {
      _notifications.removeAt(index);
      if (_notifications.isEmpty) {
        _hasNewNotifications = false;
      }
      notifyListeners();
    }
  }




  // NEW SAFE DISMISSAL METHOD
  void dismissNotificationById(String id) {
    _notifications.removeWhere((n) => n.id == id);
    if (_notifications.isEmpty) {
      _hasNewNotifications = false;
    }
    notifyListeners();
  }

  // 6. MARK AS READ (Turn off glow)
  void markNotificationsAsRead() {
    _hasNewNotifications = false;
    notifyListeners();
  }
}

// --- DATA MODEL ---
class NotificationEvent {
  final String id; // This MUST match the Android 'sbn.key'
  final String packageName;
  final String title;
  final String text;
  final DateTime createAt;

  NotificationEvent({
    required this.id,
    required this.packageName,
    required this.title,
    required this.text,
    required this.createAt,
  });
}