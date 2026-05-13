import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer';

/// SQLite-backed StorageService.
///
/// Drop-in replacement for the old SharedPreferences version.
/// Public method signatures are identical so AppProvider needs minimal changes.
///
/// pubspec.yaml dependencies to add:
///   sqflite: ^2.3.3
///   path: ^1.9.0
class StorageService {
  // ─── Singleton ────────────────────────────────────────────
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Database? _db;

  // ─── Cache ────────────────────────────────────────────────
  // FIX #4: Moved to top of class where all fields belong.
  Map<String, dynamic> _profileCache = {};

  // ─── Init ─────────────────────────────────────────────────
  Future<void> init() async {
    if (_db != null) {
      log("[StorageService] Already initialized. Skipping.");
      return;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'focusdesk.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );

    // Ensure the single user_profile row always exists
    await _ensureProfileRow();

    log("[StorageService] SQLite initialized at $path");
  }

  Database get _database {
    if (_db == null) {
      throw StateError(
          "Database not initialized. Ensure init() completes before warmCache() or any other call.");
    }
    return _db!;
  }

  Future<void> _createTables(Database db, int version) async {
    // Single-row profile — holds all scalar user settings
    await db.execute('''
      CREATE TABLE user_profile (
        id              INTEGER PRIMARY KEY,
        name            TEXT    NOT NULL DEFAULT '',
        avatar_url      TEXT    NOT NULL DEFAULT 'https://api.dicebear.com/9.x/lorelei/png?seed=Sasha',
        goal_30         TEXT    NOT NULL DEFAULT '',
        goal_60         TEXT    NOT NULL DEFAULT '',
        goal_long       TEXT    NOT NULL DEFAULT '',
        current_streak  INTEGER NOT NULL DEFAULT 0,
        longest_streak  INTEGER NOT NULL DEFAULT 0,
        last_opened     TEXT,
        is_wallpaper_done INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // One row per goal per day
    await db.execute('''
      CREATE TABLE daily_goals (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        date_key    TEXT    NOT NULL,
        goal_text   TEXT    NOT NULL,
        is_done     INTEGER NOT NULL DEFAULT 0,
        sort_order  INTEGER NOT NULL DEFAULT 0,
        UNIQUE(date_key, goal_text)
      )
    ''');

    // One row per day — the end-of-day summary / history record
    await db.execute('''
      CREATE TABLE day_summary (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        date_key  TEXT    NOT NULL UNIQUE,
        status    TEXT    NOT NULL DEFAULT 'Incomplete',
        reason    TEXT    NOT NULL DEFAULT 'N/A',
        logged_at TEXT    NOT NULL
      )
    ''');

    // Wallpaper file paths
    await db.execute('''
      CREATE TABLE wallpapers (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        file_path TEXT    NOT NULL UNIQUE
      )
    ''');

    // Failure reasons — kept separate so we can check
    // "did user already give a reason for yesterday?" cleanly
    await db.execute('''
      CREATE TABLE failure_reasons (
        date_key TEXT PRIMARY KEY,
        reason   TEXT NOT NULL
      )
    ''');
  }

  Future<void> _ensureProfileRow() async {
    final rows = await _database.query('user_profile', limit: 1);
    if (rows.isEmpty) {
      await _database.insert(
        'user_profile',
        {'id': 1},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // ─── USER PROFILE ─────────────────────────────────────────

  Future<Map<String, dynamic>> _getProfile() async {
    final rows = await _database.query('user_profile', where: 'id = 1');
    if (rows.isEmpty) {
      log("[StorageService] WARNING: user_profile table is empty. Returning default map.");
      return {};
    }
    return Map<String, dynamic>.from(rows.first);
  }

  Future<void> _updateProfile(Map<String, dynamic> fields) async {
    await _database.update(
      'user_profile',
      fields,
      where: 'id = 1',
    );
    // Keep cache in sync on every write
    _profileCache.addAll(fields);
  }

  /// FIX #2: warmCache() now guards against being called before init().
  /// Call once after init() to warm the synchronous cache.
  Future<void> warmCache() async {
    if (_db == null) {
      log("[StorageService] warmCache() called before init() — skipping.");
      return;
    }
    _profileCache = await _getProfile();
    log("[StorageService] Cache warmed.");
  }

  // ─── PROFILE GETTERS (all use cache) ──────────────────────

  Future<String> getUserName() async {
    if ((_profileCache['name'] as String? ?? '').isNotEmpty) {
      return _profileCache['name'] as String;
    }
    final p = await _getProfile();
    final name = p['name'] as String? ?? '';
    _profileCache['name'] = name;
    return name;
  }

  Future<String> getGoal30() async {
    if ((_profileCache['goal_30'] as String? ?? '').isNotEmpty) {
      return _profileCache['goal_30'] as String;
    }
    final p = await _getProfile();
    final val = p['goal_30'] as String? ?? '';
    _profileCache['goal_30'] = val;
    return val;
  }

  Future<String> getGoal60() async {
    if ((_profileCache['goal_60'] as String? ?? '').isNotEmpty) {
      return _profileCache['goal_60'] as String;
    }
    final p = await _getProfile();
    final val = p['goal_60'] as String? ?? '';
    _profileCache['goal_60'] = val;
    return val;
  }

  Future<String> getGoalLongTerm() async {
    if ((_profileCache['goal_long'] as String? ?? '').isNotEmpty) {
      return _profileCache['goal_long'] as String;
    }
    final p = await _getProfile();
    final val = p['goal_long'] as String? ?? '';
    _profileCache['goal_long'] = val;
    return val;
  }

  // FIX #1: getAvatarUrl now reads from cache first, just like the other getters.
  Future<String> getAvatarUrl() async {
    if ((_profileCache['avatar_url'] as String? ?? '').isNotEmpty) {
      return _profileCache['avatar_url'] as String;
    }
    final p = await _getProfile();
    final val = p['avatar_url'] as String? ??
        'https://api.dicebear.com/9.x/lorelei/png?seed=Sasha';
    _profileCache['avatar_url'] = val;
    return val;
  }

  Future<void> saveAvatarUrl(String url) async {
    await _updateProfile({'avatar_url': url});
  }

  Future<void> saveUserName(String name) async {
    await _updateProfile({'name': name});
    log("[StorageService] Saved user name: $name");
  }

  Future<void> saveLongTermStrategy({
    required String goal30,
    required String goal60,
    required String goalLong,
  }) async {
    await _updateProfile({
      'goal_30': goal30,
      'goal_60': goal60,
      'goal_long': goalLong,
    });
  }

  Future<Map<String, String>> getLongTermStrategy() async {
    final p = await _getProfile();
    return {
      'goal_30': p['goal_30'] as String? ?? '',
      'goal_60': p['goal_60'] as String? ?? '',
      'goal_long': p['goal_long'] as String? ?? '',
    };
  }

  // ─── LAST OPENED ──────────────────────────────────────────

  // FIX #1 (extended): getLastOpened also reads from cache.
  Future<String?> getLastOpened() async {
    if (_profileCache.containsKey('last_opened')) {
      return _profileCache['last_opened'] as String?;
    }
    final p = await _getProfile();
    _profileCache['last_opened'] = p['last_opened'];
    return p['last_opened'] as String?;
  }

  /// NEW SURE-SHOT RULE: Returns the most recent date_key from 'daily_goals'.
  /// This confirms the last day the user actually set goals.
  Future<String?> getLastDateWithGoals() async {
    final rows = await _database.query(
      'daily_goals',
      columns: ['date_key'],
      orderBy: 'date_key DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['date_key'] as String;
  }


  /// Returns the most recent date_key from day_summary, or null if no history exists.
  Future<String?> getLastRecordedDate() async {
    final rows = await _database.query(
      'day_summary',
      columns: ['date_key'],
      orderBy: 'date_key DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['date_key'] as String;
  }

  Future<void> setLastOpened(String isoUtcString) async {
    await _updateProfile({'last_opened': isoUtcString});
  }

  // ─── STREAKS ──────────────────────────────────────────────

  // FIX #1 (extended): streak reads from cache too.
  Future<int> getCurrentStreak() async {
    if (_profileCache.containsKey('current_streak')) {
      return _profileCache['current_streak'] as int? ?? 0;
    }
    final p = await _getProfile();
    final val = p['current_streak'] as int? ?? 0;
    _profileCache['current_streak'] = val;
    return val;
  }

  Future<int> getLongestStreak() async {
    if (_profileCache.containsKey('longest_streak')) {
      return _profileCache['longest_streak'] as int? ?? 0;
    }
    final p = await _getProfile();
    final val = p['longest_streak'] as int? ?? 0;
    _profileCache['longest_streak'] = val;
    return val;
  }

  Future<void> resetStreak() async {
    await _updateProfile({'current_streak': 0});
    log("[StorageService] Streak reset to 0.");
  }

  Future<void> _updateStreaks(bool isSuccess) async {
    // Read from cache-aware getters so we don't drift from DB
    int current = await getCurrentStreak();
    int longest = await getLongestStreak();

    if (isSuccess) {
      current++;
      if (current > longest) longest = current;
    } else {
      current = 0;
    }

    await _updateProfile({
      'current_streak': current,
      'longest_streak': longest,
    });
    log("[StorageService] Streak → current: $current, longest: $longest");
  }

  // ─── DAILY GOALS ──────────────────────────────────────────

  Future<List<String>> getTodayGoals(String dateKey) async {
    final rows = await _database.query(
      'daily_goals',
      where: 'date_key = ?',
      whereArgs: [dateKey],
      orderBy: 'sort_order ASC',
    );
    return rows.map((r) => r['goal_text'] as String).toList();
  }

  Future<bool> getGoalStatus(String dateKey, String goal) async {
    final rows = await _database.query(
      'daily_goals',
      columns: ['is_done'],
      where: 'date_key = ? AND goal_text = ?',
      whereArgs: [dateKey, goal],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    return (rows.first['is_done'] as int) == 1;
  }

  Future<Map<String, bool>> getGoalStatuses(String dateKey) async {
    final rows = await _database.query(
      'daily_goals',
      where: 'date_key = ?',
      whereArgs: [dateKey],
    );
    return {
      for (final r in rows)
        r['goal_text'] as String: (r['is_done'] as int) == 1
    };
  }

  Future<void> saveTodayGoals(String dateKey, List<String> goals) async {
    final batch = _database.batch();

    batch.delete('daily_goals', where: 'date_key = ?', whereArgs: [dateKey]);

    for (int i = 0; i < goals.length; i++) {
      batch.insert('daily_goals', {
        'date_key': dateKey,
        'goal_text': goals[i],
        'is_done': 0,
        'sort_order': i,
      });
    }

    await batch.commit(noResult: true);
    log("[StorageService] Saved ${goals.length} goals for $dateKey");
  }

  Future<void> toggleGoalStatus(
      String dateKey,
      String goal,
      bool isDone,
      bool allDone, // kept for API compatibility
      ) async {
    await _database.update(
      'daily_goals',
      {'is_done': isDone ? 1 : 0},
      where: 'date_key = ? AND goal_text = ?',
      whereArgs: [dateKey, goal],
    );
    log("[StorageService] Toggled '$goal' → $isDone");
  }

  // ─── FAILURE REASONS ──────────────────────────────────────

  Future<bool> hasFailureReason(String dateKey) async {
    final rows = await _database.query(
      'failure_reasons',
      where: 'date_key = ?',
      whereArgs: [dateKey],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> saveFailureReason(String dateKey, String reason) async {
    await _database.insert(
      'failure_reasons',
      {'date_key': dateKey, 'reason': reason},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── HISTORY ──────────────────────────────────────────────

  Future<void> logDayToHistory({
    required String date,
    required bool isSuccess,
    required List<String> allGoals,
    required Map<String, bool> goalStatus,
    String? reason,
  }) async {
    log("[StorageService] Logging day $date. Success: $isSuccess");

    // Duplicate guard — skip streak math if already logged
    final existing = await _database.query(
      'day_summary',
      where: 'date_key = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      log("[StorageService] $date already in history. Skipping.");
      return;
    }

    await _updateStreaks(isSuccess);

    await _database.insert(
      'day_summary',
      {
        'date_key': date,
        'status': isSuccess ? 'Completed' : 'Incomplete',
        'reason': reason ?? 'N/A',
        'logged_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    log("[StorageService] History log complete for $date.");
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final summaries = await _database.query(
      'day_summary',
      orderBy: 'date_key DESC',
    );

    final List<Map<String, dynamic>> result = [];

    for (final summary in summaries) {
      final dateKey = summary['date_key'] as String;

      final goalRows = await _database.query(
        'daily_goals',
        where: 'date_key = ?',
        whereArgs: [dateKey],
        orderBy: 'sort_order ASC',
      );

      final allGoals = goalRows.map((r) => r['goal_text'] as String).toList();
      final completed = goalRows
          .where((r) => (r['is_done'] as int) == 1)
          .map((r) => r['goal_text'] as String)
          .toList();
      final incomplete = goalRows
          .where((r) => (r['is_done'] as int) == 0)
          .map((r) => r['goal_text'] as String)
          .toList();

      result.add({
        'date': dateKey,
        'status': summary['status'],
        'reason': summary['reason'],
        'total_goals': allGoals,
        'completed_goals': completed,
        'incomplete_goals': incomplete,
      });
    }

    return result;
  }

  Future<Map<String, dynamic>> getFullContext() async {
    final profile = await _getProfile();
    final history = await getHistory();

    return {
      'user': {
        'name': profile['name'],
        'goal_30': profile['goal_30'],
        'goal_60': profile['goal_60'],
        'goal_long': profile['goal_long'],
        'current_streak': profile['current_streak'],
        'longest_streak': profile['longest_streak'],
      },
      'history': history,
    };
  }

  // ─── WALLPAPERS ───────────────────────────────────────────

  Future<List<String>> getWallpapers() async {
    final rows = await _database.query('wallpapers', orderBy: 'id ASC');
    return rows.map((r) => r['file_path'] as String).toList();
  }

  // FIX #3: Each wallpaper insert now has a conflictAlgorithm so duplicates
  // are silently ignored instead of crashing.
  Future<void> saveWallpapers(List<String> paths) async {
    final batch = _database.batch();
    batch.delete('wallpapers');
    for (final p in paths) {
      batch.insert(
        'wallpapers',
        {'file_path': p},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
    await _updateProfile({'is_wallpaper_done': 1});
  }

  Future<bool> isWallpaperSetupDone() async {
    // FIX #1 (extended): read from cache
    if (_profileCache.containsKey('is_wallpaper_done')) {
      return (_profileCache['is_wallpaper_done'] as int? ?? 0) == 1;
    }
    final p = await _getProfile();
    final val = (p['is_wallpaper_done'] as int? ?? 0) == 1;
    _profileCache['is_wallpaper_done'] = val ? 1 : 0;
    return val;
  }

}