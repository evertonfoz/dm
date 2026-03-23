import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lite_camera/flutter_lite_camera.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/photo_service.dart';

/// Tela de câmera desktop usando flutter_lite_camera
/// IMPORTANTE: Salva imagem direto sem preview complexo
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _camera = FlutterLiteCamera();
  bool _isOpen = false;
  bool _isCapturing = false;
  String? _errorMessage;
  Timer? _previewTimer;
  ui.Image? _currentPreviewImage;
  int _previewWidth = 640;
  int _previewHeight = 480;

  // Adicionado para reforçar permissão
  final PhotoService _photoService = PhotoService();

  // Controle do crop ajustável
  double _cropScale = 0.8; // 80% da menor dimensão por padrão
  Offset _cropOffset =
      Offset.zero; // Deslocamento do centro (em pixels do preview)
  Offset? _initialFocalPoint; // Posição inicial do gesto
  Offset _initialOffset = Offset.zero; // Offset inicial antes do gesto

  @override
  void initState() {
    super.initState();
    _requestCameraPermissionAndInit();
  }

  Future<void> _requestCameraPermissionAndInit() async {
    // Solicita permissão antes de inicializar a câmera
    bool granted = await _photoService.requestPermission(ImageSource.camera);
    if (!granted) {
      setState(() {
        _errorMessage =
            'Permissão de câmera não concedida. Vá em Ajustes > Taskflow App e habilite a Câmera.';
      });
      return;
    }
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final devices = await _camera.getDeviceList();

      if (devices.isEmpty) {
        setState(() {
          _errorMessage = 'Nenhuma câmera encontrada';
        });
        return;
      }

      // Abre a primeira câmera disponível (geralmente webcam frontal)
      await _camera.open(0);
      setState(() {
        _isOpen = true;
        // Reset offset quando abre a câmera
        _cropOffset = Offset.zero;
        _cropScale = 0.8;
      });

      // Inicia preview em tempo real
      _startPreview();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao inicializar câmera: $e';
      });
    }
  }

  /// Inicia captura periódica de frames para preview
  void _startPreview() {
    _previewTimer = Timer.periodic(
      const Duration(milliseconds: 100), // 10 FPS
      (_) => _updatePreview(),
    );
  }

  /// Atualiza o preview com novo frame
  Future<void> _updatePreview() async {
    if (!_isOpen || _isCapturing) return;

    try {
      final frameMap = await _camera.captureFrame();
      final rgbData = frameMap['data'] as Uint8List;
      final width = frameMap['width'] as int? ?? 640;
      final height = frameMap['height'] as int? ?? 480;

      final rgba = _convertRgbToRgba(rgbData, width, height);

      // Converte para ui.Image para exibição
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(rgba, width, height, ui.PixelFormat.rgba8888, (
        ui.Image image,
      ) {
        completer.complete(image);
      });

      final image = await completer.future;

      if (mounted) {
        setState(() {
          _currentPreviewImage?.dispose();
          _currentPreviewImage = image;
          _previewWidth = width;
          _previewHeight = height;
        });
      }
    } catch (e) {
      // Silenciosamente ignora erros de preview
    }
  }

  Future<void> _capturePhoto() async {
    if (!_isOpen || _isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // Captura um frame da câmera
      final frameMap = await _camera.captureFrame();
      final rgbData = frameMap['data'] as Uint8List;
      final width = frameMap['width'] as int? ?? 640;
      final height = frameMap['height'] as int? ?? 480;

      // Converte RGB para RGBA (adiciona canal alpha)
      final rgba = _convertRgbToRgba(rgbData, width, height);

      // Crop para quadrado usando a escala e offset ajustados pelo usuário
      final croppedRgba = _cropToSquare(
        rgba,
        width,
        height,
        _cropScale,
        _cropOffset,
      );
      final minDimension = width < height ? width : height;
      final squareSize = (minDimension * _cropScale).round();

      // Converte RGBA para PNG usando dart:ui
      final pngBytes = await _convertRgbaToPng(
        croppedRgba,
        squareSize,
        squareSize,
      );

      if (kDebugMode) {
        print('📸 Captura: ${squareSize}x$squareSize (quadrado perfeito)');
      }

      // Salva PNG em arquivo temporário
      final tempDir = await getTemporaryDirectory();
      final fileName = 'camera_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = path.join(tempDir.path, fileName);

      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        // Retorna o caminho do arquivo PNG válido
        Navigator.of(context).pop(filePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao capturar foto: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  /// Converte RGB888 para RGBA8888
  Uint8List _convertRgbToRgba(Uint8List rgb, int width, int height) {
    final rgba = Uint8List(width * height * 4);
    int rgbIndex = 0;
    int rgbaIndex = 0;

    while (rgbIndex < rgb.length && rgbaIndex < rgba.length) {
      rgba[rgbaIndex++] = rgb[rgbIndex++]; // R
      rgba[rgbaIndex++] = rgb[rgbIndex++]; // G
      rgba[rgbaIndex++] = rgb[rgbIndex++]; // B
      rgba[rgbaIndex++] = 0xFF; // A (opaco)
    }

    return rgba;
  }

  /// Crop RGBA para quadrado (centro da imagem + offset ajustável)
  /// Remove barras pretas ao usar em CircleAvatar
  /// Usa cropScale para ajustar o tamanho e cropOffset para posição
  Uint8List _cropToSquare(
    Uint8List rgba,
    int width,
    int height,
    double cropScale,
    Offset cropOffset,
  ) {
    final minDimension = width < height ? width : height;
    final squareSize = (minDimension * cropScale).round();

    // Calcula offset base (centro da imagem)
    final baseOffsetX = ((width - squareSize) / 2).round();
    final baseOffsetY = ((height - squareSize) / 2).round();

    // O cropOffset já vem em pixels da imagem (não da tela)
    // Soma com o offset base
    final offsetX = (baseOffsetX + cropOffset.dx.round()).clamp(
      0,
      width - squareSize,
    );
    final offsetY = (baseOffsetY + cropOffset.dy.round()).clamp(
      0,
      height - squareSize,
    );

    if (kDebugMode) {
      print('🔍 Crop: ${width}x$height -> ${squareSize}x$squareSize');
      print(
        '📐 Offset: base($baseOffsetX,$baseOffsetY) + user(${cropOffset.dx},${cropOffset.dy}) = ($offsetX,$offsetY)',
      );
    }

    final cropped = Uint8List(squareSize * squareSize * 4);
    int croppedIndex = 0;

    for (int y = 0; y < squareSize; y++) {
      for (int x = 0; x < squareSize; x++) {
        final srcX = x + offsetX;
        final srcY = y + offsetY;
        final srcIndex = (srcY * width + srcX) * 4;

        cropped[croppedIndex++] = rgba[srcIndex]; // R
        cropped[croppedIndex++] = rgba[srcIndex + 1]; // G
        cropped[croppedIndex++] = rgba[srcIndex + 2]; // B
        cropped[croppedIndex++] = rgba[srcIndex + 3]; // A
      }
    }

    return cropped;
  }

  /// Converte RGBA para PNG usando dart:ui
  Future<Uint8List> _convertRgbaToPng(
    Uint8List rgba,
    int width,
    int height,
  ) async {
    final completer = Completer<Uint8List>();

    ui.decodeImageFromPixels(rgba, width, height, ui.PixelFormat.rgba8888, (
      ui.Image image,
    ) async {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      completer.complete(byteData!.buffer.asUint8List());
      image.dispose();
    });

    return completer.future;
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _currentPreviewImage?.dispose();
    if (_isOpen) {
      _camera.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Câmera'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: _errorMessage != null
          ? _buildError()
          : _isOpen
          ? _buildCameraView()
          : _buildLoading(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Inicializando câmera...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: _currentPreviewImage == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Carregando preview...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  )
                : _buildPreview(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: _isCapturing
                    ? null
                    : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: _isCapturing ? null : _capturePhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                icon: _isCapturing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(_isCapturing ? 'Capturando...' : 'Tirar Foto'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Constrói o preview da câmera com aspect ratio correto
  Widget _buildPreview() {
    if (_currentPreviewImage == null) return const SizedBox.shrink();

    // Calcula dimensões para preview quadrado (crop visual)
    final previewAspect = _previewWidth / _previewHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Área disponível
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // Calcula tamanho do preview mantendo aspect ratio original
        double previewWidth, previewHeight;
        if (availableWidth / availableHeight > previewAspect) {
          // Limitado pela altura
          previewHeight = availableHeight;
          previewWidth = previewHeight * previewAspect;
        } else {
          // Limitado pela largura
          previewWidth = availableWidth;
          previewHeight = previewWidth / previewAspect;
        }

        // Tamanho do quadrado de crop (ajustável)
        final minDimension = previewWidth < previewHeight
            ? previewWidth
            : previewHeight;
        final cropSize = minDimension * _cropScale;

        // Limites para o offset (para não sair do preview)
        final maxOffsetX = (previewWidth - cropSize) / 2;
        final maxOffsetY = (previewHeight - cropSize) / 2;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Preview completo da câmera
            SizedBox(
              width: previewWidth,
              height: previewHeight,
              child: CustomPaint(painter: _ImagePainter(_currentPreviewImage!)),
            ),
            // Overlay escuro com buraco quadrado (com offset)
            CustomPaint(
              size: Size(availableWidth, availableHeight),
              painter: _CropOverlayPainter(cropSize, _cropOffset),
            ),
            // Borda do quadrado de crop (ajustável e arrastável)
            Positioned(
              left: (availableWidth / 2) - (cropSize / 2) + _cropOffset.dx,
              top: (availableHeight / 2) - (cropSize / 2) + _cropOffset.dy,
              child: GestureDetector(
                onScaleStart: (details) {
                  // Salva posição inicial e offset atual
                  _initialFocalPoint = details.focalPoint;
                  _initialOffset = _cropOffset;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    // Se scale mudou significativamente, é pinch (zoom)
                    if ((details.scale - 1.0).abs() > 0.05) {
                      _cropScale = (_cropScale * details.scale).clamp(0.5, 1.0);
                    }
                    // Se focalPoint mudou, é drag (arrastar)
                    // Calcula delta desde o início do gesto
                    else if (_initialFocalPoint != null) {
                      final delta = details.focalPoint - _initialFocalPoint!;
                      final newOffset = _initialOffset + delta;
                      _cropOffset = Offset(
                        newOffset.dx.clamp(-maxOffsetX, maxOffsetX),
                        newOffset.dy.clamp(-maxOffsetY, maxOffsetY),
                      );
                    }
                  });
                },
                onScaleEnd: (_) {
                  // Limpa estado do gesto
                  _initialFocalPoint = null;
                },
                child: Container(
                  width: cropSize,
                  height: cropSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.open_with,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          Icons.zoom_out_map,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Texto explicativo
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Arraste com 1 dedo • Pinch com 2 dedos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Painter para overlay escuro com buraco quadrado
class _CropOverlayPainter extends CustomPainter {
  final double cropSize;
  final Offset offset;

  _CropOverlayPainter(this.cropSize, this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2 + offset.dx;
    final centerY = size.height / 2 + offset.dy;
    final halfCrop = cropSize / 2;

    final cropRect = Rect.fromLTRB(
      centerX - halfCrop,
      centerY - halfCrop,
      centerX + halfCrop,
      centerY + halfCrop,
    );

    // Desenha overlay completo
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(RRect.fromRectAndRadius(cropRect, const Radius.circular(8)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CropOverlayPainter oldDelegate) {
    return oldDelegate.cropSize != cropSize || oldDelegate.offset != offset;
  }
}

/// Painter para desenhar ui.Image no canvas
class _ImagePainter extends CustomPainter {
  final ui.Image image;

  _ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(_ImagePainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
