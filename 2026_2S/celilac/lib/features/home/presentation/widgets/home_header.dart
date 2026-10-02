import 'package:flutter/material.dart';

import '../../../../app/common/widgets/gold_accent.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting!',
          style: textTheme.headlineSmall?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const GoldAccent(),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'O que você procura hoje?',
          style: textTheme.bodyLarge?.copyWith(
            color: AppColors.navy.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
