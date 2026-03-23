import 'dart:io';

import 'package:flutter/foundation.dart' show kReleaseMode, debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Simple environment resolution service.
///
/// Resolution priority:
/// 1. Compile-time defines (String.fromEnvironment)
/// 2. dotenv loaded map (if dotenv was initialized)
/// 3. Platform.environment
class EnvService {
  static Map<String, String>? _safeEnv;

  // Known compile-time environment values. Use explicit const fields because
  // String.fromEnvironment requires a constant identifier at compile-time.
  static const _compileSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const _compileSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static const _compileSupabaseKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: '',
  );

  /// Attempts to initialize dotenv from a list of candidate filenames.
  ///
  /// If none are found or loading fails, this method will not throw — it
  /// leaves internal state as null so callers can fall back to other sources.
  static Future<void> ensureInitialized({
    required List<String> candidates,
  }) async {
    // Debug: report cwd and candidates when running in non-release mode so
    // we can diagnose why a .env in the repo root wasn't found at runtime.
    if (!kReleaseMode) {
      try {
        debugPrint('EnvService: Directory.current=${Directory.current.path}');
        debugPrint('EnvService: candidates=${candidates.join(', ')}');
      } catch (_) {}
    }

    for (final name in candidates) {
      try {
        final path = name;
        if (File(path).existsSync()) {
          if (!kReleaseMode) debugPrint('EnvService: loading env file: $path');
          await dotenv.load(fileName: path);
          _safeEnv = Map<String, String>.from(dotenv.env);
          if (!kReleaseMode) {
            // mask a couple of common keys to show presence without leaking
            final url = _safeEnv!['SUPABASE_URL'];
            final anon =
                _safeEnv!['SUPABASE_ANON_KEY'] ?? _safeEnv!['SUPABASE_KEY'];
            debugPrint(
              'EnvService: loaded; SUPABASE_URL=${mask(url)}, SUPABASE_KEY=${mask(anon)}',
            );
          }
          return;
        }
      } catch (e) {
        if (!kReleaseMode) debugPrint('EnvService: failed to load $name: $e');
        // ignore and try next
      }
    }

    // If not loaded, set to null to indicate absence
    _safeEnv = null;
  }

  static String? _fromCompileTime(String key) {
    switch (key) {
      case 'SUPABASE_URL':
        return _compileSupabaseUrl.isNotEmpty ? _compileSupabaseUrl : null;
      case 'SUPABASE_ANON_KEY':
        return _compileSupabaseAnonKey.isNotEmpty
            ? _compileSupabaseAnonKey
            : null;
      case 'SUPABASE_KEY':
        return _compileSupabaseKey.isNotEmpty ? _compileSupabaseKey : null;
      default:
        return null;
    }
  }

  /// Resolve a key following the priority rules.
  static String? get(String key) {
    final fromCompile = _fromCompileTime(key);
    if (fromCompile != null) return fromCompile;

    if (_safeEnv != null) {
      final v = _safeEnv![key];
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }

    final os = Platform.environment[key];
    if (os != null && os.trim().isNotEmpty) return os.trim();

    return null;
  }

  /// Require a key to be present. In release mode this throws if missing.
  static String require(String key, {bool failInRelease = true}) {
    final v = get(key);
    if (v == null) {
      if (kReleaseMode && failInRelease) {
        throw Exception('Missing required environment variable: $key');
      }
      // In debug, return empty string to avoid null checks in call sites
      return '';
    }
    return v;
  }

  /// Mask a secret for logging (does not reveal full value).
  static String mask(String? v) {
    if (v == null || v.isEmpty) return '<missing>';
    if (v.length <= 6) return '******';
    return '${v.substring(0, 3)}***${v.substring(v.length - 3)}';
  }
}
