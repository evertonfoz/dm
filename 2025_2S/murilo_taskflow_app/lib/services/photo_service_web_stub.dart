// Stub for non-web platforms. Provides the same API as the web implementation
// but returns null so non-web builds don't try to call dart:html APIs.

import 'dart:async';

Future<String?> pickImageFromWebCamera({
  int width = 640,
  int height = 480,
}) async {
  // Not available on non-web platforms
  return null;
}
