import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';

class NearbyLoading extends StatelessWidget {
  const NearbyLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carregando estabelecimentos',
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            Container(
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
