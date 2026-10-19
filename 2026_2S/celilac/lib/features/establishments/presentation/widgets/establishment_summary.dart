import 'package:flutter/material.dart';

import '../../../../app/common/formatters.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/establishment.dart';
import 'dietary_badge.dart';

class EstablishmentSummary extends StatelessWidget {
  const EstablishmentSummary({super.key, required this.establishment});

  final Establishment establishment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final details = [
      establishment.category.label,
      establishment.neighborhood,
      formatDistance(establishment.distanceInKm),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            establishment.name,
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          details,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.navy.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        MergeSemantics(
          child: Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 20,
                color: AppColors.gold,
                semanticLabel: 'Nota',
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                formatDecimal(establishment.rating),
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final option in establishment.dietaryOptions)
              DietaryBadge(option: option),
          ],
        ),
      ],
    );
  }
}
