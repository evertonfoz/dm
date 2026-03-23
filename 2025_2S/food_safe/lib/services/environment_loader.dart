import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:celilac_life/utils/env_utils.dart';
import 'package:celilac_life/utils/platform_environment_stub.dart'
    if (dart.library.io) 'package:celilac_life/utils/platform_environment_io.dart';

/// Service responsible for loading environment variables from multiple sources
class EnvironmentLoader {
  bool _loaded = false;
  Map<String, String> _assetEnv = {};

  // Compile-time environment variables
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

  /// Load environment variables from all available sources
  Future<void> load() async {
    if (_loaded) return;

    await _loadFromDotenv();
    await _loadFromAssets();

    _loaded = true;
    _logLoadedVariables();
  }

  /// Load environment from .env files using flutter_dotenv
  Future<void> _loadFromDotenv() async {
    try {
      await dotenv.load(fileName: '.env');
      debugPrint('Environment: loaded .env');
      return;
    } catch (_) {
      // Try alternative path
    }

    try {
      await dotenv.load(fileName: 'assets/.env');
      debugPrint('Environment: loaded assets/.env');
    } catch (_) {
      // Will try asset fallback next
    }
  }

  /// Load environment from bundled assets as fallback
  Future<void> _loadFromAssets() async {
    for (final candidate in ['.env', 'assets/.env']) {
      try {
        final content = await rootBundle.loadString(candidate);
        _assetEnv = parseEnvContent(content);
        debugPrint(
          'Environment: parsed asset $candidate; SUPABASE_URL=${maskSecret(_assetEnv['SUPABASE_URL'])}',
        );
        break;
      } catch (_) {
        // Try next candidate
      }
    }
  }

  /// Get environment variable with resolution order:
  /// 1. Compile-time variables
  /// 2. dotenv
  /// 3. Asset-parsed environment
  /// 4. Platform environment
  String? getVariable(String key) {
    // Check compile-time constants
    if (key == 'SUPABASE_URL' && _compileSupabaseUrl.isNotEmpty) {
      return _compileSupabaseUrl;
    }
    if (key == 'SUPABASE_ANON_KEY' && _compileSupabaseAnonKey.isNotEmpty) {
      return _compileSupabaseAnonKey;
    }
    if (key == 'SUPABASE_KEY' && _compileSupabaseKey.isNotEmpty) {
      return _compileSupabaseKey;
    }

    // Check dotenv
    try {
      final value = dotenv.env[key];
      if (value != null && value.isNotEmpty) return value;
    } catch (_) {}

    // Check asset-parsed environment
    final fromAsset = _assetEnv[key];
    if (fromAsset != null && fromAsset.isNotEmpty) return fromAsset;

    // Check platform environment
    final fromPlatform = platformEnvironment[key];
    if (fromPlatform != null && fromPlatform.isNotEmpty) return fromPlatform;

    return null;
  }

  /// Log loaded variables (masked for security)
  void _logLoadedVariables() {
    final hasUrl = getVariable('SUPABASE_URL') != null;
    final hasKey = getVariable('SUPABASE_KEY') != null;
    final hasAnon = getVariable('SUPABASE_ANON_KEY') != null;

    debugPrint(
      'Environment: SUPABASE_URL=${hasUrl ? "<set>" : "<missing>"}, '
      'SUPABASE_KEY=${hasKey ? "<set>" : "<missing>"}, '
      'SUPABASE_ANON_KEY=${hasAnon ? "<set>" : "<missing>"}',
    );

    debugPrint(
      'Environment values: '
      'SUPABASE_URL=${maskSecret(getVariable('SUPABASE_URL'))}, '
      'SUPABASE_ANON_KEY=${maskSecret(getVariable('SUPABASE_ANON_KEY'))}, '
      'SUPABASE_KEY=${maskSecret(getVariable('SUPABASE_KEY'))}',
    );
  }
}
