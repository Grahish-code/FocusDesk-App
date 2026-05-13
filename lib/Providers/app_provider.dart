import 'package:focusdesk/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:focusdesk/models/app_state.dart';
import '../services/storage_service.dart';

class AppProvider extends ChangeNotifier with WidgetsBindingObserver {
  final StorageService _storage = StorageService();

  // --- CORE STATE ---
  AppState _currentState = AppState.loading;
  String _userName = "";
  Timer? _timeCheckTimer;

  String _goal30 = '';
  String _goal60 = '';
  String _goalLongTerm = '';

  // --- DAILY GOALS STATE ---
  List<String> _savedGoals = [];
  Map<String, bool> _goalStates = {};
  bool _goalsCompleted = false;

  // --- STRATEGY & COSMETICS STATE ---
  String _avatarUrl = "https://api.dicebear.com/9.x/lorelei/png?seed=Sasha";
  List<String> _wallpaperPaths = [];
  bool _isWallpaperSetupDone = false;
  int _currentStreak = 0;

  // --- MULTI-DAY GAP STATE ---
  List<String> _missedDays = [];

  // =========================================================
  // GETTERS
  // =========================================================
  AppState get currentState => _currentState;
  String get userName => _userName;
  List<String> get savedGoals => _savedGoals;
  Map<String, bool> get goalStates => _goalStates;
  bool get goalsCompleted => _goalsCompleted;
  String get goal30 => _goal30;
  String get goal60 => _goal60;
  String get goalLongTerm => _goalLongTerm;
  String get avatarUrl => _avatarUrl;
  int get currentStreak => _currentStreak;
  List<String> get wallpaperPaths => _wallpaperPaths;
  bool get isWallpaperSetupDone => _isWallpaperSetupDone;
  List<String> get missedDays => List.unmodifiable(_missedDays);

  AppProvider() {
    WidgetsBinding.instance.addObserver(this);
    _initApp().then((_) {
      _timeCheckTimer = Timer.periodic(
        const Duration(minutes: 1),
            (_) => _refreshTimeCheck(),
      );
    });
  }

  // =========================================================
  // INIT
  // =========================================================

  Future<void> _initApp() async {
    log("[AppProvider] Initializing...");

    try {
      await _storage.init().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          log("[AppProvider] WARNING: storage.init() timed out!");
        },
      );
    } catch (e) {
      log("[AppProvider] ERROR: storage.init() failed: $e");
    }

    try {
      await _storage.warmCache().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          log("[AppProvider] WARNING: warmCache() timed out!");
        },
      );
    } catch (e) {
      log("[AppProvider] ERROR: warmCache() failed: $e");
    }

    try {
      _avatarUrl =
      await _storage.getAvatarUrl().timeout(const Duration(seconds: 3));
    } catch (_) {}

    try {
      _isWallpaperSetupDone = await _storage
          .isWallpaperSetupDone()
          .timeout(const Duration(seconds: 3));
    } catch (_) {}

    try {
      _wallpaperPaths =
      await _storage.getWallpapers().timeout(const Duration(seconds: 3));
    } catch (_) {}

    try {
      _currentStreak = await _storage
          .getCurrentStreak()
          .timeout(const Duration(seconds: 3));
    } catch (_) {}

    try {
      _userName =
      await _storage.getUserName().timeout(const Duration(seconds: 5));
    } catch (_) {}

    try {
      _goal30 = await _storage.getGoal30().timeout(const Duration(seconds: 5));
    } catch (_) {}

    try {
      _goal60 = await _storage.getGoal60().timeout(const Duration(seconds: 5));
    } catch (_) {}

    try {
      _goalLongTerm =
      await _storage.getGoalLongTerm().timeout(const Duration(seconds: 5));
    } catch (_) {}

    if (_userName.trim().isEmpty) {
      _changeState(AppState.nameInput);
      return;
    }
    if (_goalLongTerm.trim().isEmpty) {
      _changeState(AppState.longTermGoalSetting);
      return;
    }

    await _checkTimeAndGoals();
  }

  // =========================================================
  // LIFECYCLE
  // =========================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _timeCheckTimer?.cancel();
      _timeCheckTimer = Timer.periodic(
        const Duration(minutes: 1),
            (_) => _refreshTimeCheck(),
      );

      Future.microtask(() async {
        await _refreshTimeCheck();
      });
    }
  }

  Future<void> _refreshTimeCheck() async {
    if (_userName.trim().isEmpty || _goalLongTerm.trim().isEmpty) return;
    await _checkTimeAndGoals();
  }

  Future<void> retryInit() async {
    _changeState(AppState.loading);
    await _initApp();
  }

  // =========================================================
  // CORE ROUTING LOGIC
  // =========================================================

  Future<void> _checkTimeAndGoals() async {
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final todayDate = DateTime(now.year, now.month, now.day);

    // ── Multi-day gap detection via last date user saved goals ──
    // Using getLastDateWithGoals() instead of last_opened so that
    // simply opening the app (night rest etc.) never poisons the anchor date.
    String? lastGoalDateStr;
    try {
      lastGoalDateStr = await _storage
          .getLastDateWithGoals()
          .timeout(const Duration(seconds: 3));
    } catch (_) {}

    _missedDays = [];
    if (lastGoalDateStr != null) {
      // getLastDateWithGoals() returns a plain yyyy-MM-dd string — no timezone conversion needed.
      final lastDateOnly = DateTime.parse(lastGoalDateStr);
      final daysSinceRecord = todayDate.difference(lastDateOnly).inDays;

      if (daysSinceRecord > 1) {
        for (int i = 1; i < daysSinceRecord; i++) {
          final candidate = lastDateOnly.add(Duration(days: i));
          final candidateKey = DateFormat('yyyy-MM-dd').format(candidate);

          if (candidateKey != todayKey) {
            _missedDays.add(candidateKey);
          }
        }
        log("[AppProvider] Unaccounted days found: $_missedDays");

        try {
          await _storage.resetStreak();
          _currentStreak = 0;
          notifyListeners();
        } catch (e) {
          log("[AppProvider] Failed to reset streak: $e");
        }
      }
    }
    // ────────────────────────────────────────────────────────

    // Load today's goals and statuses.
    try {
      _savedGoals = await _storage
          .getTodayGoals(todayKey)
          .timeout(const Duration(seconds: 3));
      _goalStates = await _storage
          .getGoalStatuses(todayKey)
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      log("[AppProvider] Goal load failed: $e");
    }

    _goalsCompleted = _savedGoals.isNotEmpty &&
        _savedGoals.every((g) => _goalStates[g] == true);

    try {
      _currentStreak = await _storage
          .getCurrentStreak()
          .timeout(const Duration(seconds: 3));
    } catch (_) {}

    final String yesterdayKey =
    DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));
    final String primaryMissedKey =
    _missedDays.isNotEmpty ? _missedDays.last : yesterdayKey;

    bool reasonGiven = false;
    try {
      reasonGiven = await _storage
          .hasFailureReason(primaryMissedKey)
          .timeout(const Duration(seconds: 3));
    } catch (_) {}

    _safePushBridgeState(todayKey, reasonGiven);

    // ROUTING RULE 1: Night Rest
    if (now.hour < 6) {
      _changeState(AppState.nightRest);
      return;
    }

    // ROUTING RULE 2: Multi-day gap
    if (_missedDays.isNotEmpty && !reasonGiven) {
      List<String> missedGoals = [];
      Map<String, bool> missedStates = {};
      try {
        missedGoals = await _storage
            .getTodayGoals(primaryMissedKey)
            .timeout(const Duration(seconds: 3));
        missedStates = await _storage
            .getGoalStatuses(primaryMissedKey)
            .timeout(const Duration(seconds: 3));
      } catch (_) {}

      if (missedGoals.isNotEmpty) {
        _savedGoals = missedGoals;
        _goalStates = missedStates;
      } else {
        _savedGoals = ["No goals were set during the missed days"];
        _goalStates = {"No goals were set during the missed days": false};
      }

      _changeState(AppState.failureReason);
      return;
    }

    // ROUTING RULE 3: Standard goal setting / yesterday accountability
    if (_savedGoals.isEmpty) {
      List<String> yesterdayGoals = [];
      Map<String, bool> yesterdayStates = {};

      try {
        yesterdayGoals = await _storage
            .getTodayGoals(yesterdayKey)
            .timeout(const Duration(seconds: 3));
      } catch (_) {}

      final hadGoalsYesterday = yesterdayGoals.isNotEmpty;
      bool failedYesterday = false;

      // isFirstDay = user has never saved goals ever
      final isFirstDay = lastGoalDateStr == null;

      if (hadGoalsYesterday) {
        try {
          yesterdayStates = await _storage
              .getGoalStatuses(yesterdayKey)
              .timeout(const Duration(seconds: 3));
        } catch (_) {}

        final yesterdayCompleted =
        yesterdayGoals.every((g) => yesterdayStates[g] == true);
        failedYesterday = !yesterdayCompleted;

        if (yesterdayCompleted) {
          try {
            await _storage.logDayToHistory(
              date: yesterdayKey,
              isSuccess: true,
              allGoals: yesterdayGoals,
              goalStatus: yesterdayStates,
              reason: "Mission Accomplished",
            );
            _currentStreak = await _storage
                .getCurrentStreak()
                .timeout(const Duration(seconds: 3));
          } catch (e) {
            log("[AppProvider] logDayToHistory failed: $e");
          }
        }
      } else if (!isFirstDay) {
        failedYesterday = true;
      }

      if (failedYesterday && !reasonGiven) {
        if (hadGoalsYesterday) {
          _savedGoals = yesterdayGoals;
          _goalStates = yesterdayStates;
        } else {
          _savedGoals = ["No goals were set yesterday"];
          _goalStates = {"No goals were set yesterday": false};
        }
        _changeState(AppState.failureReason);
      } else {
        _savedGoals = [];
        _goalStates = {};
        _changeState(AppState.goalSetting);
      }
    } else {
      _changeState(AppState.dashboard);
    }
  }

  // =========================================================
  // USER ACTIONS
  // =========================================================

  Future<void> saveName(String name) async {
    await _storage.saveUserName(name);
    _userName = name;
    _changeState(AppState.longTermGoalSetting);
  }

  Future<void> saveLongTermStrategy({
    required String goal30,
    required String goal60,
    required String longTerm,
  }) async {
    await _storage.saveLongTermStrategy(
      goal30: goal30,
      goal60: goal60,
      goalLong: longTerm,
    );
    _goal30 = goal30;
    _goal60 = goal60;
    _goalLongTerm = longTerm;
    notifyListeners();

    await _checkTimeAndGoals();
  }

  Future<void> saveGoals(List<String> goals) async {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _storage.saveTodayGoals(todayKey, goals);


    // Record the last date user actually saved goals — used for gap detection.
    await _storage.setLastOpened(DateTime.now().toUtc().toIso8601String());

    _savedGoals = goals;
    _goalStates = {for (var g in goals) g: false};
    _goalsCompleted = false;

    _safePushBridgeState(todayKey, false);
    _changeState(AppState.dashboard);
  }

  Future<void> toggleGoalStatus(String goal, bool isDone) async {
    _goalStates[goal] = isDone;
    _goalsCompleted = _savedGoals.isNotEmpty &&
        _savedGoals.every((g) => _goalStates[g] == true);

    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayKey =
    DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    await _storage.toggleGoalStatus(todayKey, goal, isDone, _goalsCompleted);

    bool reasonGiven = false;
    try {
      reasonGiven = await _storage
          .hasFailureReason(yesterdayKey)
          .timeout(const Duration(seconds: 3));
    } catch (_) {}

    _safePushBridgeState(todayKey, reasonGiven);
    notifyListeners();
  }

  Future<void> submitFailureReason(String reason) async {
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayKey =
    DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    final List<String> daysToLog =
    _missedDays.isNotEmpty ? List.from(_missedDays) : [yesterdayKey];

    log("[AppProvider] submitFailureReason: logging reason for days: $daysToLog");

    for (final dayKey in daysToLog) {
      List<String> goalsForDay = [];
      Map<String, bool> statusesForDay = {};
      try {
        goalsForDay = await _storage
            .getTodayGoals(dayKey)
            .timeout(const Duration(seconds: 3));
        statusesForDay = await _storage
            .getGoalStatuses(dayKey)
            .timeout(const Duration(seconds: 3));
      } catch (_) {}

      final allGoals = goalsForDay.isEmpty ? ["No goals set"] : goalsForDay;
      final goalStatus = goalsForDay.isEmpty
          ? {"No goals set": false}
          : statusesForDay;

      await _storage.saveFailureReason(dayKey, reason);
      await _storage.logDayToHistory(
        date: dayKey,
        isSuccess: false,
        allGoals: allGoals,
        goalStatus: goalStatus,
        reason: reason,
      );
    }

    _missedDays = [];
    _savedGoals = [];
    _goalStates = {};

    _safePushBridgeState(todayKey, true);
    await _checkTimeAndGoals();
  }

  // ─── VISUALS ──────────────────────────────────────────────

  Future<void> updateAvatar(String url) async {
    await _storage.saveAvatarUrl(url);
    _avatarUrl = url;
    notifyListeners();
  }

  Future<void> saveWallpapers(List<String> paths) async {
    await _storage.saveWallpapers(paths);
    _wallpaperPaths = paths;
    _isWallpaperSetupDone = true;
    notifyListeners();
  }

  // ─── HISTORY ──────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getHistory() => _storage.getHistory();

  Future<Map<String, dynamic>> getFullContext() async {
    final storageData = await _storage.getFullContext();

    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final List<Map<String, dynamic>> todayTasks =
    _savedGoals.map((goal) => {
      "title": goal,
      "is_completed": _goalStates[goal] ?? false,
    }).toList();

    return {
      "user_profile": {
        "name": storageData['user']['name'] ?? '',
        "current_streak": storageData['user']['current_streak'] ?? 0,
        "longest_streak": storageData['user']['longest_streak'] ?? 0,
      },
      "strategy": {
        "30_day": storageData['user']['goal_30'] ?? '',
        "60_day": storageData['user']['goal_60'] ?? '',
        "long_term": storageData['user']['goal_long'] ?? '',
      },
      "today_plan": {
        "date": todayKey,
        "tasks": todayTasks,
      },
      "history": storageData['history'] ?? [],
    };
  }

  // =========================================================
  // PRIVATE HELPERS
  // =========================================================

  void _safePushBridgeState(String todayKey, bool reasonGiven) {
    Future.microtask(() async {
      try {
        await NotificationBridge.push(
          dateKey: todayKey,
          goals: _savedGoals,
          goalStates: _goalStates,
          currentStreak: _currentStreak,
          reasonGivenForYesterday: reasonGiven,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            log("[AppProvider] Bridge push timed out — skipping.");
          },
        );
      } catch (e) {
        log("[AppProvider] Bridge push failed (safe to ignore): $e");
      }
    });
  }

  void _changeState(AppState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timeCheckTimer?.cancel();
    super.dispose();
  }
}