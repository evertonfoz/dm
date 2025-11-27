import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode, kDebugMode;
// Conditional import: use real Platform.environment when dart:io is available,
// otherwise use a safe stub (for web).
import 'package:celilac_life/utils/platform_environment_stub.dart'
    if (dart.library.io) 'package:celilac_life/utils/platform_environment_io.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:celilac_life/utils/env_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:celilac_life/features/app/food_safe_app.dart';

/// Custom LocalStorage implementation that avoids Hive migration issues
/// and prevents TimeoutException that causes IDE pauses.
/// See: https://github.com/supabase/supabase-flutter/issues/794
class CustomLocalStorage extends LocalStorage {
  final String persistSessionKey;

  CustomLocalStorage({this.persistSessionKey = 'supabase-auth-token'});

  @override
  Future<void> initialize() async {
    // SharedPreferences is ready to use immediately
  }

  @override
  Future<String?> accessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(persistSessionKey);
  }

  @override
  Future<bool> hasAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(persistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(persistSessionKey, persistSessionString);
  }

  @override
  Future<void> removePersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(persistSessionKey);
  }
}

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Try loading dotenv from the packaged assets (pubspec.yaml includes .env)
  var loadedEnv = false;
  try {
    await dotenv.load(fileName: '.env');
    loadedEnv = true;
    debugPrint('dotenv: loaded .env');
  } catch (_) {
    // ignore and try assets path
  }

  if (!loadedEnv) {
    try {
      await dotenv.load(fileName: 'assets/.env');
      loadedEnv = true;
      debugPrint('dotenv: loaded assets/.env');
    } catch (_) {
      // not available via dotenv; we'll try asset fallback below
    }
  }

  // Asset fallback parsing (for cases where rootBundle contains .env but dotenv
  // couldn't load it directly). This is a non-destructive fallback.
  Map<String, String> assetEnv = {};
  if (!loadedEnv) {
    for (final candidate in ['.env', 'assets/.env']) {
      try {
        final content = await rootBundle.loadString(candidate);
        assetEnv = parseEnvContent(content);
        debugPrint(
          'dotenv: parsed asset $candidate; SUPABASE_URL=${maskSecret(assetEnv['SUPABASE_URL'])}',
        );
        break;
      } catch (_) {
        // ignore and try next
      }
    }
  }

  // Resolution order: compile-time -> dotenv -> Platform.environment
  // Known compile-time keys (must be explicit constants)
  const compileSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  const compileSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  const compileSupabaseKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: '',
  );

  String? maybe(String key) {
    if (key == 'SUPABASE_URL' && compileSupabaseUrl.isNotEmpty) {
      return compileSupabaseUrl;
    }
    if (key == 'SUPABASE_ANON_KEY' && compileSupabaseAnonKey.isNotEmpty) {
      return compileSupabaseAnonKey;
    }
    if (key == 'SUPABASE_KEY' && compileSupabaseKey.isNotEmpty) {
      return compileSupabaseKey;
    }
    try {
      final v = dotenv.env[key];
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {}
    final fromAsset = assetEnv[key];
    if (fromAsset != null && fromAsset.isNotEmpty) return fromAsset;
    final os = platformEnvironment[key];
    if (os != null && os.isNotEmpty) return os;
    return null;
  }

  final hasUrl = maybe('SUPABASE_URL') != null;
  final hasKey = maybe('SUPABASE_KEY') != null;
  final hasAnon = maybe('SUPABASE_ANON_KEY') != null;
  debugPrint(
    'dotenv: SUPABASE_URL=${hasUrl ? "<set>" : "<missing>"}, SUPABASE_KEY=${hasKey ? "<set>" : "<missing>"}, SUPABASE_ANON_KEY=${hasAnon ? "<set>" : "<missing>"}',
  );

  final supabaseUrl = maybe('SUPABASE_URL');
  final supabaseAnonKey = maybe('SUPABASE_ANON_KEY');
  final supabaseServiceKey = maybe('SUPABASE_KEY');

  // Masked debug print of actual values (only show masked, not full secrets)
  debugPrint(
    'dotenv values: SUPABASE_URL=${maskSecret(supabaseUrl)}, SUPABASE_ANON_KEY=${maskSecret(supabaseAnonKey)}, SUPABASE_KEY=${maskSecret(supabaseServiceKey)}',
  );

  // Strict safety: never silently initialize the client with a service/admin key.
  // Desired behavior:
  // - If SUPABASE_ANON_KEY is present -> use it (safe client init).
  // - If only SUPABASE_KEY (potentially privileged) is present -> refuse to init.
  //   * In release: fail fast with a clear exception.
  //   * In debug: log a strong warning and skip Supabase initialization (so app can still run locally without leaking secrets).
  if (supabaseUrl == null) {
    if (kReleaseMode) {
      throw Exception('Missing SUPABASE_URL in production environment');
    } else {
      debugPrint(
        'Warning: SUPABASE_URL is missing; Supabase will not be initialized.',
      );
    }
  }

  if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
    if (supabaseServiceKey != null && supabaseServiceKey.isNotEmpty) {
      // Service key present but anon key missing -> refuse to use service key on client
      final msg =
          'Refusing to initialize Supabase client with a service/admin key. Provide SUPABASE_ANON_KEY for client builds.';
      if (kReleaseMode) {
        throw Exception(msg);
      } else {
        debugPrint('WARNING: $msg');
        debugPrint(
          'Supabase initialization skipped to avoid using a privileged key in client.',
        );
      }
    } else {
      // No anon key and no service key
      if (kReleaseMode) {
        throw Exception(
          'Missing SUPABASE_ANON_KEY (and SUPABASE_KEY) in production environment',
        );
      } else {
        debugPrint(
          'Warning: No SUPABASE_ANON_KEY or SUPABASE_KEY found; Supabase will not be initialized.',
        );
      }
    }
  } else {
    // anon key exists -> safe to initialize (provided we have URL)
    if (supabaseUrl != null && supabaseAnonKey.isNotEmpty) {
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
    }
  }

  FlutterNativeSplash.remove();

  // Global error handling (debug-only prints) to capture Flutter framework
  // errors and uncaught zone/isolate errors. This prevents silent pauses in
  // the debugger and ensures errors are printed to the console for diagnosis.
  FlutterError.onError = (FlutterErrorDetails details) {
    // Preserve default behavior (shows red screen in debug), but also print
    // full details to the console for easier collection in logs.
    FlutterError.presentError(details);
    if (kDebugMode) {
      try {
        print('FlutterError caught: ${details.exceptionAsString()}');
        if (details.stack != null) print(details.stack);
      } catch (_) {}
    }
  };

  // Capture errors from other isolates (engine / async errors)
  WidgetsBinding.instance.platformDispatcher.onError =
      (Object error, StackTrace stack) {
        if (kDebugMode) {
          try {
            print('PlatformDispatcher.onError: $error');
            print(stack);
          } catch (_) {}
        }
        // Return true to indicate we've handled the error and avoid further
        // propagation that might pause the debugger in some configurations.
        return true;
      };

  runApp(const FoodSafeApp());
}
