import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureLocalStorage extends LocalStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async {
    return await _storage.read(key: supabasePersistSessionKey);
  }

  @override
  Future<bool> hasAccessToken() async {
    final value = await _storage.containsKey(key: supabasePersistSessionKey);
    return value;
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _storage.write(
      key: supabasePersistSessionKey,
      value: persistSessionString,
    );
  }

  @override
  Future<void> removePersistedSession() async {
    await _storage.delete(key: supabasePersistSessionKey);
  }
}
