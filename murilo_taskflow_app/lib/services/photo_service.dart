import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart'
    show getTemporaryDirectory, getApplicationDocumentsDirectory;
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'io.dart';
import 'dart:typed_data';

// Conditional import for web image compressor
import 'web_image_compress_stub.dart'
    if (dart.library.html) 'web_image_compress.dart'
    as web_image_compress;

/// Serviço responsável por gerenciar fotos do usuário
/// Inclui: seleção, compressão, armazenamento e remoção de EXIF/GPS
class PhotoService {
  static const String _photoPathKey = 'userPhotoPath';
  static const int _maxSizeKB = 200;
  static const int _imageQuality = 85;

  final ImagePicker _picker = ImagePicker();

  /// Solicita permissão de câmera ou galeria
  Future<bool> requestPermission(ImageSource source) async {
    // No desktop (macOS/Windows/Linux), web E iOS não usa permission_handler
    // O ImagePicker já pede permissão automaticamente via sistema nativo
    if (kIsWeb || isDesktop || isIOS) {
      return true; // ImagePicker vai solicitar permissão automaticamente
    }

    // Android apenas - usa permission_handler
    // For camera we only need CAMERA permission.
    if (source == ImageSource.camera) {
      final PermissionStatus status = await Permission.camera.status;
      if (status.isGranted || status.isLimited) return true;

      final PermissionStatus result = await Permission.camera.request();
      if (result.isGranted || result.isLimited) return true;

      if (result.isPermanentlyDenied) {
        if (kDebugMode) {
          print('Permissão permanentemente negada para câmera');
          print('Abra as configurações do app para habilitar a permissão.');
        }
        try {
          await openAppSettings();
        } catch (_) {}
      }
      return false;
    }

    // For gallery access on Android there are two possible permissions:
    // - Android 13+ (API 33+): READ_MEDIA_IMAGES (Permission.photos)
    // - Android <=32: READ/WRITE_EXTERNAL_STORAGE (Permission.storage)
    // Request both on Android so the correct one is granted depending on OS.
    if (isAndroid && source == ImageSource.gallery) {
      final statuses = await [Permission.photos, Permission.storage].request();

      final photosStatus = statuses[Permission.photos];
      final storageStatus = statuses[Permission.storage];

      if ((photosStatus?.isGranted == true) ||
          (photosStatus?.isLimited == true) ||
          (storageStatus?.isGranted == true)) {
        return true;
      }

      // If any of the requested permissions are permanently denied, open settings.
      final permanentlyDenied =
          (photosStatus?.isPermanentlyDenied == true) ||
          (storageStatus?.isPermanentlyDenied == true);

      if (permanentlyDenied) {
        if (kDebugMode) {
          print('Permissão permanentemente negada para galeria');
          print('Abra as configurações do app para habilitar a permissão.');
        }
        try {
          await openAppSettings();
        } catch (_) {}
      }

      return false;
    }

    // Fallback for Android — use Permission.photos
    final PermissionStatus status = await Permission.photos.status;
    if (status.isGranted || status.isLimited) return true;
    final PermissionStatus result = await Permission.photos.request();
    if (result.isGranted || result.isLimited) return true;

    if (result.isPermanentlyDenied) {
      if (kDebugMode) {
        print('Permissão permanentemente negada para galeria');
        print('Abra as configurações do app para habilitar a permissão.');
      }
      try {
        await openAppSettings();
      } catch (_) {}
    }

    return false;
  }

  /// Seleciona uma imagem da câmera ou galeria
  /// Retorna o caminho do arquivo original ou null se cancelado
  Future<String?> pickImage(ImageSource source) async {
    try {
      // Solicitar permissão
      bool hasPermission = await requestPermission(source);
      if (!hasPermission) {
        if (kDebugMode) {
          print(
            'Permissão negada para acessar ${source == ImageSource.camera ? 'câmera' : 'galeria'}',
          );
        }
        return null;
      }

      // Selecionar imagem
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (image == null) return null;
      return image.path;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao selecionar imagem: $e');
      }
      return null;
    }
  }

  /// Comprime a imagem e remove metadados EXIF/GPS
  /// Retorna o caminho do arquivo comprimido
  Future<String?> compressImage(String imagePath) async {
    try {
      // path_provider plugins are not available on web or when running in
      // certain test/isolate contexts which can produce MissingPluginException.
      // Use a fallback DirectoryWrapper for those cases. We always build a
      // DirectoryWrapper so the rest of the code can use `dir.path` safely.
      final tempDirPath = kIsWeb ? '/' : (await getTemporaryDirectory()).path;
      final dir = DirectoryWrapper.fromPath(tempDirPath);

      // Detecta se é PNG (da câmera desktop) ou outro formato
      final isPng = imagePath.toLowerCase().endsWith('.png');
      final extension = isPng ? 'png' : 'jpg';
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );

      // Comprime a imagem removendo metadados EXIF
      // Para PNG (câmera desktop), mantém PNG para preservar qualidade
      if (kIsWeb) {
        // On web, FlutterImageCompress isn't supported. Read file bytes and
        // delegate to web-specific compressor which returns a data URL (JPEG).
        try {
          final Uint8List bytes = await XFile(imagePath).readAsBytes();
          final compressedDataUrl = await web_image_compress
              .compressBytesToDataUrl(
                bytes,
                width: 1024,
                height: 1024,
                quality: 0.85,
              );
          return compressedDataUrl;
        } catch (e) {
          if (kDebugMode) print('Erro ao comprimir imagem no web: $e');
          return null;
        }
      } else {
        final result = await FlutterImageCompress.compressAndGetFile(
          imagePath,
          targetPath,
          quality: isPng ? 95 : _imageQuality, // PNG alta qualidade
          format: isPng ? CompressFormat.png : CompressFormat.jpeg,
          keepExif: false, // Remove EXIF/GPS
        );

        if (result == null) return null;

        // Verifica o tamanho
        final file = FileWrapper.fromPath(result.path);
        final sizeKB = await file.length() / 1024;

        if (kDebugMode) {
          print(
            '📦 Imagem comprimida ($extension): ${sizeKB.toStringAsFixed(2)} KB',
          );
          print('📍 Caminho: ${result.path}');
        }

        // Se ainda estiver muito grande, comprime mais
        if (sizeKB > _maxSizeKB) {
          final newQuality = (_imageQuality * (_maxSizeKB / sizeKB)).round();
          final secondPass = await FlutterImageCompress.compressAndGetFile(
            result.path,
            targetPath,
            quality: newQuality.clamp(50, 100),
            format: CompressFormat.jpeg,
            keepExif: false,
          );
          return secondPass?.path;
        }

        return result.path;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao comprimir imagem: $e');
      }
      return null;
    }
  }

  /// Salva a foto no diretório permanente do app
  /// Retorna o caminho final da foto salva
  Future<String?> savePhoto(String compressedImagePath) async {
    try {
      if (kIsWeb) {
        // On web we store the data URL directly in SharedPreferences so
        // widgets (user_avatar_web) can render it as MemoryImage.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_photoPathKey, compressedImagePath);
        return compressedImagePath;
      }

      final appDirPath = (await getApplicationDocumentsDirectory()).path;
      final appDir = DirectoryWrapper.fromPath(appDirPath);
      final photoDir = DirectoryWrapper.fromPath(
        path.join(appDir.path, 'user_photos'),
      );

      // Cria o diretório se não existir
      if (!await photoDir.exists()) {
        await photoDir.create(recursive: true);
      }

      // Remove foto anterior se existir
      final oldPhotoPath = await getPhotoPath();
      if (oldPhotoPath != null) {
        final old = FileWrapper.fromPath(oldPhotoPath);
        if (old.existsSync()) await old.delete();
      }

      // Copia a imagem comprimida para o diretório permanente
      final fileName =
          'user_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final finalPath = path.join(photoDir.path, fileName);
      await FileWrapper.fromPath(compressedImagePath).copy(finalPath);

      // Salva o caminho no SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_photoPathKey, finalPath);

      // Remove o arquivo temporário
      try {
        await FileWrapper.fromPath(compressedImagePath).delete();
      } catch (_) {}

      return finalPath;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar foto: $e');
      }
      return null;
    }
  }

  /// Recupera o caminho da foto do usuário
  Future<String?> getPhotoPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final photoPath = prefs.getString(_photoPathKey);

      // Verifica se o arquivo existe
      if (photoPath != null && FileWrapper.fromPath(photoPath).existsSync()) {
        return photoPath;
      }

      // Se não existe, remove a referência
      if (photoPath != null) {
        await prefs.remove(_photoPathKey);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao recuperar caminho da foto: $e');
      }
      return null;
    }
  }

  /// Remove a foto do usuário
  Future<bool> deletePhoto() async {
    try {
      final photoPath = await getPhotoPath();
      if (photoPath != null && FileWrapper.fromPath(photoPath).existsSync()) {
        await FileWrapper.fromPath(photoPath).delete();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_photoPathKey);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao deletar foto: $e');
      }
      return false;
    }
  }

  /// Fluxo completo: selecionar, comprimir e salvar
  Future<String?> pickCompressAndSave(ImageSource source) async {
    if (kIsWeb) {
      // On web, read bytes from the picked XFile and use web compressor
      try {
        final XFile? picked = await _picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 90,
        );
        if (picked == null) return null;

        final Uint8List bytes = await picked.readAsBytes();
        final compressedDataUrl = await web_image_compress
            .compressBytesToDataUrl(
              bytes,
              width: 1024,
              height: 1024,
              quality: 0.85,
            );
        if (compressedDataUrl == null) return null;

        final savedPath = await savePhoto(compressedDataUrl);
        return savedPath;
      } catch (e) {
        if (kDebugMode) print('Erro ao processar imagem web: $e');
        return null;
      }
    }

    final imagePath = await pickImage(source);
    if (imagePath == null) return null;

    final compressedPath = await compressImage(imagePath);
    if (compressedPath == null) return null;

    final savedPath = await savePhoto(compressedPath);
    return savedPath;
  }
}
