import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../domain/entities/establishment_category.dart';
import '../establishment_category_icon.dart';

class CategoryIconTile extends StatelessWidget {
  const CategoryIconTile({super.key, required this.category, this.size = 56});

  final EstablishmentCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(category.icon, color: AppColors.navy, size: size * 3 / 7),
    );
  }
}
