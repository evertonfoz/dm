import 'package:flutter/material.dart';

import '../../../../app/common/widgets/source_image.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../domain/entities/establishment.dart';
import '../establishment_category_icon.dart';
import 'category_icon_tile.dart';

class EstablishmentLogo extends StatelessWidget {
  const EstablishmentLogo({
    super.key,
    required this.establishment,
    this.size = 56,
  });

  final Establishment establishment;
  final double size;

  @override
  Widget build(BuildContext context) {
    final logo = establishment.logoSource;
    if (logo == null) {
      return CategoryIconTile(category: establishment.category, size: size);
    }

    final padding = size * 0.1;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.12)),
      ),
      child: SourceImage(
        source: logo,
        displayWidth: size - padding * 2,
        fit: BoxFit.contain,
        fallback: Icon(
          establishment.category.icon,
          color: AppColors.navy,
          size: size * 3 / 7,
        ),
      ),
    );
  }
}
