// Stub for non-web platforms. The functions return null so non-web builds
// won't try to call dart:html APIs.

import 'dart:typed_data';

Future<String?> compressBytesToDataUrl(
  Uint8List bytes, {
  int width = 1024,
  int height = 1024,
  double quality = 0.85,
}) async {
  return null;
}
