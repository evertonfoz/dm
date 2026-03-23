// Web-only implementation that opens a small DOM overlay to capture a photo
// using navigator.mediaDevices.getUserMedia. Returns a data URL (PNG) or null
// if the user cancels.

import 'dart:async';
import 'dart:html' as html;

Future<String?> pickImageFromWebCamera({
  int width = 640,
  int height = 480,
}) async {
  final completer = Completer<String?>();

  // Create overlay
  final overlay = html.DivElement()
    ..style.position = 'fixed'
    ..style.left = '0'
    ..style.top = '0'
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.backgroundColor = 'rgba(0,0,0,0.6)'
    ..style.zIndex = '999999'
    ..style.display = 'flex'
    ..style.alignItems = 'center'
    ..style.justifyContent = 'center'
    ..style.flexDirection = 'column';

  // Video element
  final video = html.VideoElement()
    ..width = width
    ..height = height
    ..autoplay = true
    ..style.borderRadius = '8px'
    ..style.boxShadow = '0 4px 24px rgba(0,0,0,0.5)';
  // playsinline attribute helps mobile browsers. Use setAttribute because
  // the Dart VideoElement may not expose a playsInline setter.
  video.setAttribute('playsinline', '');

  // Buttons container
  final btnRow = html.DivElement()..style.marginTop = '12px';

  final captureBtn = html.ButtonElement()
    ..text = 'Tirar foto'
    ..style.marginRight = '8px'
    ..style.padding = '8px 14px'
    ..style.fontSize = '14px';

  final cancelBtn = html.ButtonElement()
    ..text = 'Cancelar'
    ..style.padding = '8px 14px'
    ..style.fontSize = '14px';

  btnRow.children.addAll([captureBtn, cancelBtn]);

  overlay.children.addAll([video, btnRow]);
  html.document.body?.append(overlay);

  html.MediaStream? stream;

  void cleanUp() {
    try {
      if (stream != null) {
        for (final track in stream.getTracks()) {
          track.stop();
        }
      }
    } catch (_) {}
    try {
      overlay.remove();
    } catch (_) {}
  }

  // Request camera
  try {
    final p = html.window.navigator.mediaDevices?.getUserMedia({'video': true});
    if (p == null) throw 'getUserMedia not supported';

    stream = await p;
    video.srcObject = stream;
    await video.play();
  } catch (e) {
    cleanUp();
    completer.completeError('Erro ao acessar a câmera: $e');
    return completer.future;
  }

  // Capture handler
  captureBtn.onClick.listen((_) {
    try {
      final canvas = html.CanvasElement(width: width, height: height);
      final ctx = canvas.context2D;
      ctx.drawImageScaled(video, 0, 0, width, height);
      final dataUrl = canvas.toDataUrl('image/png');
      cleanUp();
      completer.complete(dataUrl);
    } catch (e) {
      cleanUp();
      completer.completeError('Erro ao capturar foto: $e');
    }
  });

  // Cancel handler
  cancelBtn.onClick.listen((_) {
    cleanUp();
    completer.complete(null);
  });

  // If the user navigates away or closes, ensure cleanup
  html.window.onBeforeUnload.listen((_) {
    cleanUp();
  });

  return completer.future;
}
