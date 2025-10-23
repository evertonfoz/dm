import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'secure_local_storage.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  SupabaseClient? _client;

  SupabaseService._internal();

  factory SupabaseService() => _instance;

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize first.');
    }
    return _client!;
  }

  Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: FlutterAuthClientOptions(localStorage: SecureLocalStorage()),
    );

    _client = Supabase.instance.client;
  }
}
