import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../models/user_profile.dart';
import 'preferences_service.dart';
import 'local_photo_store.dart';
import 'dart:io';

class ProfileRepository extends StateNotifier<UserProfile> {
  ProfileRepository() : super(const UserProfile()) {
    // Load profile asynchronously after construction
    Future.microtask(() => _loadProfile());
  }

  /// Loads the user profile from local storage
  Future<void> _loadProfile() async {
    try {
      final name = await PreferencesService.getUserName();
      final email = await PreferencesService.getUserEmail();
      final photoPath = await PreferencesService.getUserPhotoPath();
      final photoUpdatedAt = await PreferencesService.getUserPhotoUpdatedAt();

      // Validate photo path if it exists
      String? validPhotoPath;
      if (photoPath != null && photoPath.isNotEmpty) {
        final isValid = await LocalPhotoStore.isValidAvatarPath(photoPath);
        if (isValid) {
          validPhotoPath = photoPath;
        } else {
          // Clean up invalid path
          await PreferencesService.setUserPhotoPath(null);
          await PreferencesService.setUserPhotoUpdatedAt(null);
        }
      }

      state = UserProfile(
        name: name,
        email: email,
        photoPath: validPhotoPath,
        photoUpdatedAt: photoUpdatedAt,
      );
    } catch (e) {
      // Keep default empty profile on error
      state = const UserProfile();
    }
  }

  /// Updates the user's name
  Future<void> updateName(String name) async {
    try {
      await PreferencesService.setUserName(name);
      state = state.copyWith(name: name);
    } catch (e) {
      throw Exception('Failed to update name: $e');
    }
  }

  /// Updates the user's email
  Future<void> updateEmail(String email) async {
    try {
      await PreferencesService.setUserEmail(email);
      state = state.copyWith(email: email);
    } catch (e) {
      throw Exception('Failed to update email: $e');
    }
  }

  /// Updates the user's photo from a file or bytes
  Future<void> updatePhoto(File? photoFile, {Uint8List? bytes}) async {
    try {
      // Save and compress the photo
      final photoPath = await LocalPhotoStore.savePhoto(photoFile, bytes: bytes);
      final photoUpdatedAt = DateTime.now().millisecondsSinceEpoch;

      // Update preferences
      await PreferencesService.setUserPhotoPath(photoPath);
      await PreferencesService.setUserPhotoUpdatedAt(photoUpdatedAt);

      // Update state
      state = state.copyWith(
        photoPath: photoPath,
        photoUpdatedAt: photoUpdatedAt,
      );
    } catch (e) {
      throw Exception('Failed to update photo: $e');
    }
  }

  /// Removes the user's photo
  Future<void> removePhoto() async {
    try {
      // Delete the file
      await LocalPhotoStore.deleteAvatar();

      // Clear preferences
      await PreferencesService.setUserPhotoPath(null);
      await PreferencesService.setUserPhotoUpdatedAt(null);

      // Update state
      state = state.copyWith(
        photoPath: null,
        photoUpdatedAt: null,
      );
    } catch (e) {
      throw Exception('Failed to remove photo: $e');
    }
  }

  /// Updates multiple profile fields at once
  Future<void> updateProfile({
    String? name,
    String? email,
    File? photoFile,
  }) async {
    try {
      // Update name if provided
      if (name != null) {
        await PreferencesService.setUserName(name);
      }

      // Update email if provided
      if (email != null) {
        await PreferencesService.setUserEmail(email);
      }

      // Update photo if provided
      if (photoFile != null) {
        final photoPath = await LocalPhotoStore.savePhoto(photoFile);
        final photoUpdatedAt = DateTime.now().millisecondsSinceEpoch;
        await PreferencesService.setUserPhotoPath(photoPath);
        await PreferencesService.setUserPhotoUpdatedAt(photoUpdatedAt);
      }

      // Reload profile to get updated state
      await _loadProfile();
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Clears all profile data
  Future<void> clearProfile() async {
    try {
      await LocalPhotoStore.deleteAvatar();
      await PreferencesService.clearUserProfile();
      state = const UserProfile();
    } catch (e) {
      throw Exception('Failed to clear profile: $e');
    }
  }

  /// Refreshes the profile from storage
  Future<void> refresh() async {
    await _loadProfile();
  }
}

// Provider for the ProfileRepository
final profileRepositoryProvider = StateNotifierProvider<ProfileRepository, UserProfile>((ref) {
  return ProfileRepository();
});
