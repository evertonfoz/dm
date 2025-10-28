import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_keys.dart';

class SharedPreferencesService {
  final SharedPreferences _prefs;

  SharedPreferencesService._(this._prefs);

  static SharedPreferencesService? _instance;

  static Future<SharedPreferencesService> getInstance() async {
    if (_instance != null) return _instance!;

    final prefs = await SharedPreferences.getInstance();
    _instance = SharedPreferencesService._(prefs);
    return _instance!;
  }

  // Test helper: reset the singleton instance. Use only in tests.
  static void resetForTests() {
    _instance = null;
  }

  static Future<void> setMarketingConsent(bool consent) async {
    if (_instance == null) {
      await getInstance();
    }
    await _instance!._prefs.setBool(PreferencesKeys.marketingConsent, consent);
  }

  static Future<bool> getMarketingConsent() async {
    if (_instance == null) {
      await getInstance();
    }
    return _instance!._prefs.getBool(PreferencesKeys.marketingConsent) ?? false;
  }

  static Future<void> setPrivacyPolicyAllRead(bool read) async {
    if (_instance == null) {
      await getInstance();
    }
    await _instance!._prefs.setBool(PreferencesKeys.privacyPolicyAllRead, read);
  }

  static Future<bool> getPrivacyPolicyAllRead() async {
    if (_instance == null) {
      await getInstance();
    }
    return _instance!._prefs.getBool(PreferencesKeys.privacyPolicyAllRead) ??
        false;
  }

  // User data helpers (name and email) - keep separate from consent keys
  static Future<void> setUserName(String name) async {
    if (_instance == null) {
      await getInstance();
    }
    await _instance!._prefs.setString(PreferencesKeys.userName, name);
  }

  static Future<String?> getUserName() async {
    if (_instance == null) {
      await getInstance();
    }
    return _instance!._prefs.getString(PreferencesKeys.userName);
  }

  static Future<void> removeUserName() async {
    if (_instance == null) {
      await getInstance();
    }
    await _instance!._prefs.remove(PreferencesKeys.userName);
  }

  static Future<void> setUserEmail(String email) async {
    if (_instance == null) {
      await getInstance();
    }
    await _instance!._prefs.setString(PreferencesKeys.userEmail, email);
  }

  static Future<String?> getUserEmail() async {
    if (_instance == null) {
      await getInstance();
    }
    return _instance!._prefs.getString(PreferencesKeys.userEmail);
  }

  static Future<void> removeUserEmail() async {
    if (_instance == null) {
      await getInstance();
    }
    await _instance!._prefs.remove(PreferencesKeys.userEmail);
  }

  static Future<void> revokeMarketingConsent() async {
    if (_instance == null) {
      await getInstance();
    }
    await _instance!._prefs.remove(PreferencesKeys.marketingConsent);
  }

  static Future<void> setTermsOfUseReadStatus(bool read) async {
    if (_instance == null) {
      await getInstance();
    }
    await _instance!._prefs.setBool(PreferencesKeys.termsOfUseAllRead, read);
  }

  static Future<bool> getTermsOfUseReadStatus() async {
    if (_instance == null) {
      await getInstance();
    }
    return _instance!._prefs.getBool(PreferencesKeys.termsOfUseAllRead) ??
        false;
  }

  static Future<void> removeAll() async {
    if (_instance == null) {
      await getInstance();
    }
    await _instance!._prefs.clear();
  }

  static Future<void> setProvidersTutorialShown(bool shown) async {
    if (_instance == null) {
      await getInstance();
    }
    await _instance!._prefs.setBool('providers_tutorial_shown', shown);
  }

  static Future<bool> getProvidersTutorialShown() async {
    if (_instance == null) {
      await getInstance();
    }
    return _instance!._prefs.getBool('providers_tutorial_shown') ?? false;
  }
}
