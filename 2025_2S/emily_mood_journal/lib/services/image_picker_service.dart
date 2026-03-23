import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ImagePickerService {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Picks an image from gallery - works on both mobile and web
  /// Returns a Map with 'file' (File?) and 'bytes' (Uint8List?)
  static Future<Map<String, dynamic>?> pickImageFromGallery() async {
    debugPrint('📸 ImagePickerService.pickImageFromGallery() - kIsWeb: $kIsWeb');
    
    try {
      if (kIsWeb) {
        debugPrint('📸 Usando FilePicker para web');
        // For web, use file_picker which has better web support
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true, // Important for web - get the bytes
        );

        debugPrint('📸 FilePicker result: ${result?.files.length ?? 0} arquivos');

        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          debugPrint('📸 Arquivo selecionado: ${file.name}, bytes: ${file.bytes?.length}');
          
          if (file.bytes != null) {
            debugPrint('📸 Retornando bytes para web');
            return {
              'bytes': file.bytes,
              'name': file.name,
              'file': null,
            };
          }
        }
        debugPrint('📸 Nenhum arquivo selecionado em web');
        return null;
      } else {
        debugPrint('📸 Usando ImagePicker para mobile');
        // For mobile, use image_picker
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          debugPrint('📸 Imagem selecionada (mobile): ${pickedFile.path}');
          return {
            'file': File(pickedFile.path),
            'bytes': null,
            'name': pickedFile.name,
          };
        }
        debugPrint('📸 Nenhuma imagem selecionada em mobile');
        return null;
      }
    } catch (e) {
      debugPrint('📸 ERRO ao selecionar imagem: $e');
      return null;
    }
  }

  /// Picks an image from camera (mobile only)
  static Future<File?> pickImageFromCamera() async {
    try {
      if (kIsWeb) {
        return null;
      }

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
