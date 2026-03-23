import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';

// On web we support data URLs (data:image/...) and blob/object URLs.
bool fileExists(String? path) {
  if (path == null) return false;
  return path.startsWith('data:') ||
      path.startsWith('blob:') ||
      path.startsWith('http');
}

ImageProvider? imageProviderForPath(String path) {
  if (path.startsWith('data:image/')) {
    final comma = path.indexOf(',');
    if (comma == -1) return null;
    final b64 = path.substring(comma + 1);
    try {
      final bytes = base64Decode(b64);
      return MemoryImage(Uint8List.fromList(bytes));
    } catch (_) {
      return null;
    }
  }

  // blob: and http(s): can be loaded via NetworkImage
  if (path.startsWith('blob:') || path.startsWith('http')) {
    return NetworkImage(path);
  }

  return null;
}
