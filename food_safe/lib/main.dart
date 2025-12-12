import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'config/error_handlers.dart';
import 'features/app/food_safe_app.dart';
import 'services/auth/supabase_initializer.dart';
import 'services/environment_loader.dart';

/// Application entry point
///
/// Initializes core services and launches the app:
/// - Environment variables loading
/// - Supabase authentication
/// - Global error handlers
/// - Native splash screen
Future<void> main() async {
  // Initialize Flutter bindings
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve native splash screen during initialization
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Configure global error handlers to prevent debugger pauses
  ErrorHandlers.configure();

  // Load environment variables from all sources
  final envLoader = EnvironmentLoader();
  await envLoader.load();

  // Initialize Supabase with loaded credentials
  await SupabaseInitializer.initialize(
    supabaseUrl: envLoader.getVariable('SUPABASE_URL'),
    supabaseAnonKey: envLoader.getVariable('SUPABASE_ANON_KEY'),
    supabaseServiceKey: envLoader.getVariable('SUPABASE_KEY'),
  );

  // Remove splash screen - app is ready to launch
  FlutterNativeSplash.remove();

  // Launch application
  runApp(const FoodSafeApp());
}
