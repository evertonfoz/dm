import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import 'photo_carousel.dart';

class DetailsLoading extends StatelessWidget {
  const DetailsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carregando informações do estabelecimento',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final heights = [
            PhotoCarousel.heightFor(constraints.maxWidth),
            48.0,
            140.0,
            96.0,
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final height in heights) ...[
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ],
          );
        },
      ),
    );
  }
}
