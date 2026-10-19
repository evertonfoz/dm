import 'package:flutter/material.dart';

import '../../../../app/common/widgets/source_image.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/establishment_photo.dart';

class PhotoCarousel extends StatelessWidget {
  const PhotoCarousel({super.key, required this.photos});

  final List<EstablishmentPhoto> photos;

  static const double _itemWidthFactor = 0.85;
  static const double _photoAspectRatio = 4 / 3;

  static double heightFor(double availableWidth) {
    return availableWidth * _itemWidthFactor / _photoAspectRatio;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemWidth = width * _itemWidthFactor;

        return SizedBox(
          height: heightFor(width),
          child: CarouselView(
            itemExtent: itemWidth,
            itemSnapping: true,
            enableSplash: false,
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            backgroundColor: AppColors.navy.withValues(alpha: 0.06),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            children: [
              for (final photo in photos)
                SourceImage(
                  source: photo.source,
                  displayWidth: itemWidth,
                  semanticLabel: photo.description,
                  fallback: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.navy,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
