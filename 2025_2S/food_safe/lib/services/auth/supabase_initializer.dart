import 'package:flutter/foundation.dart' show debugPrint, kReleaseMode;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'custom_local_storage.dart';

/// Service responsible for initializing Supabase with proper security checks
class SupabaseInitializer {
  /// Initialize Supabase with the given credentials
  ///
  /// Enforces strict security:
  /// - Never initializes with service/admin key on client
  /// - Requires SUPABASE_ANON_KEY for client builds
  /// - Fails fast in production, warns in debug
  static Future<void> initialize({
    required String? supabaseUrl,
    required String? supabaseAnonKey,
    required String? supabaseServiceKey,
  }) async {
    if (supabaseUrl == null) {
      _handleMissingUrl();
      return;
    }

    if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      _handleMissingAnonKey(supabaseServiceKey);
      return;
    }

    // Safe to initialize with anon key
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: CustomLocalStorage(
          persistSessionKey:
              "sb-${Uri.parse(supabaseUrl).host.split(".").first}-auth-token",
        ),
      ),
    );

    debugPrint('Supabase: initialized successfully');
  }

  static void _handleMissingUrl() {
    const message = 'Missing SUPABASE_URL';
    if (kReleaseMode) {
      throw Exception('$message in production environment');
    } else {
      debugPrint('Warning: $message; Supabase will not be initialized.');
    }
  }

  static void _handleMissingAnonKey(String? serviceKey) {
    if (serviceKey != null && serviceKey.isNotEmpty) {
      // Service key present but anon key missing
      const message =
          'Refusing to initialize Supabase client with a service/admin key. '
          'Provide SUPABASE_ANON_KEY for client builds.';

      if (kReleaseMode) {
        throw Exception(message);
      } else {
        debugPrint('WARNING: $message');
        debugPrint(
          'Supabase initialization skipped to avoid using a privileged key in client.',
        );
      }
    } else {
      // No anon key and no service key
      const message = 'Missing SUPABASE_ANON_KEY (and SUPABASE_KEY)';
      if (kReleaseMode) {
        throw Exception('$message in production environment');
      } else {
        debugPrint(
          'Warning: $message found; Supabase will not be initialized.',
        );
      }
    }
  }
}
