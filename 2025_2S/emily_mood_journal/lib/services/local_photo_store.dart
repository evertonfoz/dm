import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalPhotoStore {
  static const String _avatarFileName = 'avatar.jpg';
  static const String _webPhotoKey = 'avatar_photo_base64';
  static const int _quality = 80;

  /// Saves and compresses a photo file, removing EXIF data
  /// Returns the local file path where the compressed image was saved (or a marker for web)
  /// For web, pass bytes directly instead of a file
  static Future<String> savePhoto(File? originalFile, {Uint8List? bytes}) async {
    try {
      if (kIsWeb) {
        // For web, save as base64 in shared_preferences
        if (bytes == null) {
          throw Exception('Bytes are required for web');
        }
        
        final base64String = base64Encode(bytes);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_webPhotoKey, base64String);
        
        debugPrint('💾 Foto salva em web (base64), tamanho: ${base64String.length}');
        
        // Return a marker that indicates web photo
        return 'web_photo_saved';
      } else {
        // For mobile, compress and save the image
        if (originalFile == null) {
          throw Exception('File is required for mobile');
        }
        
        final appDir = await getApplicationDocumentsDirectory();
        final avatarPath = path.join(appDir.path, _avatarFileName);

        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          originalFile.absolute.path,
          avatarPath,
          quality: _quality,
          minWidth: 100,
          minHeight: 100,
          keepExif: false, // Remove EXIF data for privacy
        );

        if (compressedFile == null) {
          throw Exception('Failed to compress image');
        }

        return compressedFile.path;
      }
    } catch (e) {
      throw Exception('Failed to save photo: $e');
    }
  }

  /// Gets the avatar file if it exists (mobile only)
  static Future<File?> getAvatarFile() async {
    try {
      if (kIsWeb) {
        return null; // Web doesn't support File objects in the same way
      }

      final appDir = await getApplicationDocumentsDirectory();
      final avatarPath = path.join(appDir.path, _avatarFileName);
      final file = File(avatarPath);
      
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Gets the avatar file path or web photo indicator
  static Future<String?> getAvatarPath() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final hasPhoto = prefs.containsKey(_webPhotoKey);
        return hasPhoto ? 'web_photo' : null;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final avatarPath = path.join(appDir.path, _avatarFileName);
      final file = File(avatarPath);
      
      if (await file.exists()) {
        return avatarPath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Gets the avatar as base64 string (for web display)
  static Future<String?> getAvatarAsBase64() async {
    try {
      if (!kIsWeb) {
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_webPhotoKey);
    } catch (e) {
      return null;
    }
  }

  /// Deletes the avatar file
  static Future<bool> deleteAvatar() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_webPhotoKey);
        return true;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final avatarPath = path.join(appDir.path, _avatarFileName);
      final file = File(avatarPath);
      
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return true; // File didn't exist, consider it deleted
    } catch (e) {
      return false;
    }
  }

  /// Validates if a file path points to an existing avatar
  static Future<bool> isValidAvatarPath(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return false;
    
    try {
      if (kIsWeb) {
        // For web, check if it's a web photo marker
        if (filePath == 'web_photo' || filePath == 'web_photo_saved') {
          final base64 = await getAvatarAsBase64();
          return base64 != null && base64.isNotEmpty;
        }
        return false;
      }

      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Gets file size in bytes
  static Future<int> getFileSize(String filePath) async {
    try {
      if (kIsWeb) {
        final base64 = await getAvatarAsBase64();
        if (base64 != null) {
          return base64.length;
        }
        return 0;
      }

      final file = File(filePath);
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  /// Checks if file size is within acceptable limits (≤200KB)
  static Future<bool> isFileSizeAcceptable(String filePath) async {
    const maxSizeBytes = 200 * 1024; // 200KB
    final size = await getFileSize(filePath);
    return size <= maxSizeBytes;
  }
}

