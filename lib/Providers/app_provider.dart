import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

enum AppState { loading, nameInput, goalSetting, nightRest, dashboard }

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

  Future<void> _checkTimeAndGoals(SharedPreferences prefs) async {
    final now = DateTime.now();
    String dateKey = DateFormat('yyyy-MM-dd').format(now);

    // Check if goals exist for TODAY
    bool goalsSetToday = prefs.containsKey('goals_$dateKey');
    _goalsCompleted = prefs.getBool('completed_$dateKey') ?? false;

    if (goalsSetToday) {
      // 1. Load the list of goals
      _savedGoals = prefs.getStringList('goals_$dateKey') ?? [];

      // 2. Load the CHECKBOX status for each goal
      _goalStates.clear();
      for (var goal in _savedGoals) {
        bool isDone = prefs.getBool('status_${dateKey}_$goal') ?? false;
        _goalStates[goal] = isDone;
      }
    } else {
      _savedGoals = [];
      _goalStates.clear();
    }

    // LOGIC TREE
    if (now.hour >= 0 && now.hour < 6) {
      _currentState = AppState.nightRest;
    } else {
      if (goalsSetToday) {
        _currentState = AppState.dashboard;
      } else {
        _currentState = AppState.goalSetting;
      }
    }
    notifyListeners();
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
}