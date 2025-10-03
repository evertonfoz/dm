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
}
