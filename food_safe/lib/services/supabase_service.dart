import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'secure_local_storage.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  SupabaseClient? _client;

  SupabaseService._internal();

  factory SupabaseService() => _instance;

  SupabaseClient get client {
    // If the service hasn't been initialized through this wrapper but the
    // Supabase SDK was initialized elsewhere (for example in `main()`),
    // try to pick up the SDK client instance. This makes the wrapper more
    // tolerant to different initialization flows while preserving the
    // explicit `initialize` helper for cases that need custom localStorage.
    if (_client == null) {
      try {
        // `Supabase.instance.client` is non-nullable once the SDK has been
        // initialized; assign it directly if available.
        _client = Supabase.instance.client;
      } catch (_) {}
    }

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
