import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStorage {
  OnboardingStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _completedKey = 'onboarding_completed';

  final SharedPreferencesAsync _preferences;

  Future<bool> isCompleted() async {
    return await _preferences.getBool(_completedKey) ?? false;
  }

  Future<void> markAsCompleted() async {
    await _preferences.setBool(_completedKey, true);
  }
}
