import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';
import '../providers/profile_provider.dart';
import '../services/local_photo_store.dart';

class AvatarWidget extends ConsumerWidget {

  const AvatarWidget({
    super.key,
    this.size = 80.0,
    this.showEditIcon = false,
    this.onTap,
  });
  final double size;
  final bool showEditIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return GestureDetector(
      onTap: () {
        debugPrint('👆 Avatar clicado! onTap callback: ${onTap != null}');
        onTap?.call();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.primaryRose.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Avatar circle
            if (profile.hasPhoto && kIsWeb)
              // For web, load from base64 using FutureBuilder
              FutureBuilder<String?>(
                future: LocalPhotoStore.getAvatarAsBase64(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    try {
                      final bytes = base64Decode(snapshot.data!);
                      return CircleAvatar(
                        radius: size / 2,
                        backgroundColor: AppTheme.primaryRose.withOpacity(0.1),
                        backgroundImage: MemoryImage(bytes),
                      );
                    } catch (e) {
                      return _buildInitialsAvatar(profile.initials);
                    }
                  }
                  return _buildInitialsAvatar(profile.initials);
                },
              )
            else if (profile.hasPhoto && !kIsWeb)
              // For mobile, load from file
              CircleAvatar(
                radius: size / 2,
                backgroundColor: AppTheme.primaryRose.withOpacity(0.1),
                backgroundImage: FileImage(File(profile.photoPath!)),
              )
            else
              // No photo, show initials
              _buildInitialsAvatar(profile.initials),
            
            // Edit icon overlay
            if (showEditIcon)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRose,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.edit,
                    size: size * 0.15,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppTheme.primaryRose.withOpacity(0.1),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryRose,
        ),
      ),
    );
  }
}

