import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/dietary_profile.dart';
import '../domain/repositories/profile_repository.dart';
import 'dietary_profile_json.dart';

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _key = 'dietary_profile';
  static const int _schemaVersion = 1;

  final SharedPreferencesAsync _preferences;

  @override
  Future<DietaryProfile> load() async {
    final stored = await _preferences.getString(_key);
    if (stored == null) {
      return DietaryProfile.empty;
    }

    try {
      if (jsonDecode(stored) case final Map<String, Object?> json) {
        return dietaryProfileFromJson(json);
      }
    } on FormatException {
      // Texto corrompido: segue com o perfil vazio, sem apagar o que há.
    }
    return DietaryProfile.empty;
  }

  @override
  Future<void> save(DietaryProfile profile) async {
    final json = {'schema_version': _schemaVersion, ...profile.toJson()};
    await _preferences.setString(_key, jsonEncode(json));
  }
}
