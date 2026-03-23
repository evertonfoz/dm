// IO implementation: uses `dart:io` to expose Platform.environment
import 'dart:io' show Platform;

/// Map of environment variables on platforms that support `dart:io`.
final Map<String, String> platformEnvironment = Platform.environment;
