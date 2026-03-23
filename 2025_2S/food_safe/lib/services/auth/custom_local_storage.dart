import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Custom LocalStorage implementation that avoids Hive migration issues
/// and prevents TimeoutException that causes IDE pauses.
///
/// See: https://github.com/supabase/supabase-flutter/issues/794
class CustomLocalStorage extends LocalStorage {
  final String persistSessionKey;

  CustomLocalStorage({this.persistSessionKey = 'supabase-auth-token'});

  @override
  Future<void> initialize() async {
    // SharedPreferences is ready to use immediately
  }

  @override
  Future<String?> accessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(persistSessionKey);
  }

  @override
  Future<bool> hasAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(persistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(persistSessionKey, persistSessionString);
  }

  @override
  Future<void> removePersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(persistSessionKey);
  }
}
