import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _userNameKey = 'userName';
  static const String _userEmailKey = 'userEmail';
  static const String _userPhotoPathKey = 'userPhotoPath';
  static const String _userPhotoUpdatedAtKey = 'userPhotoUpdatedAt';
  
  // Existing mood journal keys
  static const String _moodEntriesKey = 'mood_entries';
  static const String _dailyGoalKey = 'daily_goal';
  static const String _firstTimeKey = 'first_time';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // User Profile Methods
  static Future<String?> getUserName() async {
    final prefs = await _instance;
    return prefs.getString(_userNameKey);
  }

  static Future<void> setUserName(String name) async {
    final prefs = await _instance;
    await prefs.setString(_userNameKey, name);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await _instance;
    return prefs.getString(_userEmailKey);
  }

  static Future<void> setUserEmail(String email) async {
    final prefs = await _instance;
    await prefs.setString(_userEmailKey, email);
  }

  static Future<String?> getUserPhotoPath() async {
    final prefs = await _instance;
    return prefs.getString(_userPhotoPathKey);
  }

  static Future<void> setUserPhotoPath(String? path) async {
    final prefs = await _instance;
    if (path == null) {
      await prefs.remove(_userPhotoPathKey);
    } else {
      await prefs.setString(_userPhotoPathKey, path);
    }
  }

  static Future<int?> getUserPhotoUpdatedAt() async {
    final prefs = await _instance;
    return prefs.getInt(_userPhotoUpdatedAtKey);
  }

  static Future<void> setUserPhotoUpdatedAt(int? timestamp) async {
    final prefs = await _instance;
    if (timestamp == null) {
      await prefs.remove(_userPhotoUpdatedAtKey);
    } else {
      await prefs.setInt(_userPhotoUpdatedAtKey, timestamp);
    }
  }

  static Future<void> clearUserProfile() async {
    final prefs = await _instance;
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPhotoPathKey);
    await prefs.remove(_userPhotoUpdatedAtKey);
  }

  // Existing Mood Journal Methods (migrated from MoodStorage)
  static Future<List<String>> getMoodEntries() async {
    final prefs = await _instance;
    return prefs.getStringList(_moodEntriesKey) ?? [];
  }

  static Future<void> setMoodEntries(List<String> entries) async {
    final prefs = await _instance;
    await prefs.setStringList(_moodEntriesKey, entries);
  }

  static Future<bool> getDailyGoal() async {
    final prefs = await _instance;
    return prefs.getBool(_dailyGoalKey) ?? false;
  }

  static Future<void> setDailyGoal(bool enabled) async {
    final prefs = await _instance;
    await prefs.setBool(_dailyGoalKey, enabled);
  }

  static Future<bool> isFirstTime() async {
    final prefs = await _instance;
    return prefs.getBool(_firstTimeKey) ?? true;
  }

  static Future<void> setFirstTimeCompleted() async {
    final prefs = await _instance;
    await prefs.setBool(_firstTimeKey, false);
  }
}

