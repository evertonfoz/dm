// Conditional export: use real dart:io-based implementation for non-web,
// and stub for web to avoid import errors.
// Usage: import 'services/io.dart';

export 'io_stub.dart' if (dart.library.io) 'io_real.dart';
