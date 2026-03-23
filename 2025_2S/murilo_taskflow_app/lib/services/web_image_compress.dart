// Web implementation: compress image bytes using a temporary canvas and return
// a data URL (JPEG) with requested quality.

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<String?> compressBytesToDataUrl(
  Uint8List bytes, {
  int width = 1024,
  int height = 1024,
  double quality = 0.85,
}) async {
  try {
    // Create blob and object URL
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final img = html.ImageElement();
    final completer = Completer<String?>();

    img.onLoad.listen((_) {
      // Create canvas sized to requested dimensions while preserving aspect
      final canvas = html.CanvasElement(width: width, height: height);
      final ctx = canvas.context2D;
      // Draw scaled image
      ctx.drawImageScaled(img, 0, 0, width, height);
      // Convert to JPEG with quality
      final dataUrl = canvas.toDataUrl('image/jpeg', quality);
      html.Url.revokeObjectUrl(url);
      completer.complete(dataUrl);
    });

    img.onError.listen((event) {
      html.Url.revokeObjectUrl(url);
      completer.completeError('Erro ao carregar imagem para compressão');
    });

    img.src = url;
    return completer.future;
  } catch (e) {
    return Future.error('Erro ao comprimir imagem no web: $e');
  }
}
