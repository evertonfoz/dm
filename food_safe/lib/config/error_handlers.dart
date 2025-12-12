import 'package:flutter/foundation.dart' show FlutterError, kDebugMode;
import 'package:flutter/material.dart';

/// Configure global error handlers to prevent debugger pauses
/// and ensure errors are properly logged
class ErrorHandlers {
  /// Setup global error handling for the application
  static void configure() {
    _configureFlutterErrorHandler();
    _configurePlatformErrorHandler();
  }

  /// Configure Flutter framework error handler
  ///
  /// Captures Flutter framework errors and prints full details to console
  /// while preserving default debug behavior (red screen)
  static void _configureFlutterErrorHandler() {
    FlutterError.onError = (FlutterErrorDetails details) {
      // Preserve default behavior (shows red screen in debug)
      FlutterError.presentError(details);

      // Print full details to console for easier log collection
      if (kDebugMode) {
        try {
          // TEMPORÁRIO: Usando print ao invés de debugPrint para garantir visibilidade
          print('═══════════════════════════════════════════════════════');
          print('FlutterError caught: ${details.exceptionAsString()}');
          if (details.stack != null) {
            print('Stack trace:\n${details.stack}');
          }
          print('═══════════════════════════════════════════════════════');
        } catch (_) {
          // Ignore errors while logging
        }
      }
    };
  }

  /// Configure platform dispatcher error handler
  ///
  /// Captures errors from other isolates and async errors.
  /// Returns true to prevent further propagation that might pause debugger.
  static void _configurePlatformErrorHandler() {
    WidgetsBinding.instance.platformDispatcher.onError =
        (Object error, StackTrace stack) {
      if (kDebugMode) {
        try {
          // TEMPORÁRIO: Usando print ao invés de debugPrint para garantir visibilidade
          print('═══════════════════════════════════════════════════════');
          print('PlatformDispatcher.onError: $error');
          print('Stack trace:\n$stack');
          print('═══════════════════════════════════════════════════════');
        } catch (_) {
          // Ignore errors while logging
        }
      }

      // Return true to indicate we've handled the error and avoid further
      // propagation that might pause the debugger
      return true;
    };
  }
}
