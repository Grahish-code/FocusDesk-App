import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

enum AppState { loading, nameInput, goalSetting, nightRest, dashboard, failureReason }

class AppProvider extends ChangeNotifier {
  AppState _currentState = AppState.loading;
  String _userName = "";
  bool _goalsCompleted = false;

  // 1. DATA STORAGE
  List<String> _savedGoals = [];
  Map<String, bool> _goalStates = {};

  List<String> _wallpaperPaths = [];
  bool _isWallpaperSetupDone = false;

  // 2. GETTERS (UI Reads these)
  AppState get currentState => _currentState;
  String get userName => _userName;
  bool get goalsCompleted => _goalsCompleted;
  List<String> get savedGoals => _savedGoals;
  Map<String, bool> get goalStates => _goalStates;
  List<String> get wallpaperPaths => _wallpaperPaths;
  bool get isWallpaperSetupDone => _isWallpaperSetupDone;

  AppProvider() {
    _initApp();
  }
  
 // --- INITIALIZATION ---
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

    // B. Check Wallpaper Memory
    _isWallpaperSetupDone = prefs.getBool('wallpaper_setup_done') ?? false;
    _wallpaperPaths = prefs.getStringList('saved_wallpapers') ?? [];

    // C. Check Time & Goals
    await _checkTimeAndGoals(prefs);
  }


  // TO save the user historical record in json later this will be user to make a dashboard page for user
  Future<void> _addToHistory({
    required String date,
    required bool isSuccess,
    required List<String> allGoals,
    required Map<String, bool> goalStatus,
    String? reason,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Get existing history or create empty list
    String? existingJson = prefs.getString('user_history_db');
    List<dynamic> historyList = existingJson != null ? jsonDecode(existingJson) : [];

    // 2. Check if this date already exists (Prevent Duplicates)
    // We don't want to save Jan 4th twice if the user opens the app 5 times.
    bool alreadyExists = historyList.any((record) => record['date'] == date);
    if (alreadyExists) return;

    // 3. Categorize Goals
    List<String> completedList = [];
    List<String> incompleteList = [];

    for (var goal in allGoals) {
      if (goalStatus[goal] == true) {
        completedList.add(goal);
      } else {
        incompleteList.add(goal);
      }
    }

    // 4. Create the Record Object
    Map<String, dynamic> newRecord = {
      "date": date,
      "status": isSuccess ? "Completed" : "Incomplete",
      "total_goals": allGoals,
      "completed_goals": completedList,
      "incomplete_goals": incompleteList,
      "reason": reason ?? "N/A" // Save "N/A" if success
    };

    // 5. Add to list and Save
    historyList.add(newRecord);
    await prefs.setString('user_history_db', jsonEncode(historyList));

    debugPrint(" HISTORY SAVED: $newRecord");
  }

  Future<void> _checkTimeAndGoals(SharedPreferences prefs) async {
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);

    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayKey = DateFormat('yyyy-MM-dd').format(yesterday);

    // =========================================================
    // PHASE 1: NIGHT REST (00:00 - 06:00)
    // Always show Night Rest, but load Yesterday's data
    // so the UI can decide whether to say "Sleep Well, Champion" or "Rest up for tomorrow".
    // =========================================================
    if (now.hour >= 0 && now.hour < 6) {
      // Load YESTERDAY'S data for the UI to display
      await _loadDataForDate(prefs, yesterdayKey);

      _currentState = AppState.nightRest;
      notifyListeners();
      return; // STOP HERE. Do not check anything else.
    }

    // =========================================================
    // PHASE 2: MORNING ACCOUNTABILITY (06:00 Onwards)
    // Check if yesterday was a failure that needs explaining.
    // =========================================================

    // Did we even have goals yesterday? (Skip this if it's a fresh install)
    bool yesterdayHadGoals = prefs.containsKey('goals_$yesterdayKey');

    if (yesterdayHadGoals) {
      bool yesterdayCompleted = prefs.getBool('completed_$yesterdayKey') ?? false;
      bool reasonGiven = prefs.containsKey('reason_$yesterdayKey');

      if (yesterdayCompleted) {
        // We load the data just to save it properly
        await _loadDataForDate(prefs, yesterdayKey);
        await _addToHistory(
            date: yesterdayKey,
            isSuccess: true,
            allGoals: _savedGoals,
            goalStatus: _goalStates
        );
      }

      // CONDITION: Failed + No Reason Given Yet
      if (!yesterdayCompleted && !reasonGiven) {
        // Load YESTERDAY'S data so the Failure Page can show the unchecked boxes
        await _loadDataForDate(prefs, yesterdayKey);

        _currentState = AppState.failureReason;
        notifyListeners();
        return; // STOP HERE. User is trapped until they give a reason.
      }
    }

    // =========================================================
    // PHASE 3: TODAY'S FLOW
    // If we reached here, either yesterday was a success,
    // or the user has already admitted their failure.
    // =========================================================

    // Now load TODAY'S data
    await _loadDataForDate(prefs, todayKey);

    if (_savedGoals.isNotEmpty) {
      _currentState = AppState.dashboard;
    } else {
      _currentState = AppState.goalSetting;
    }

    notifyListeners();
  }

  // --- HELPER FUNCTION (To switch between loading Yesterday vs Today) ---
  Future<void> _loadDataForDate(SharedPreferences prefs, String dateKey) async {
    _savedGoals = prefs.getStringList('goals_$dateKey') ?? [];
    _goalsCompleted = prefs.getBool('completed_$dateKey') ?? false;

    _goalStates.clear();
    for (var goal in _savedGoals) {
      _goalStates[goal] = prefs.getBool('status_${dateKey}_$goal') ?? false;
    }
  }

  // --- ACTION: Submit Reason ---
  Future<void> submitFailureReason(String reason) async {
    final prefs = await SharedPreferences.getInstance();

    // We are saving this reason for YESTERDAY
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

    // Re-run the main check.
    // Since 'reasonGiven' will now be true, it will skip Phase 2 and go to Phase 3.
    await _checkTimeAndGoals(prefs);
  }

  // --- ACTIONS ---

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

  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String? existingJson = prefs.getString('user_history_db');
    if (existingJson == null) return [];

    // Convert the dynamic list to a strong Map type
    List<dynamic> rawList = jsonDecode(existingJson);
    return rawList.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}