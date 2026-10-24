import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class ProfilePrivacyNote extends StatelessWidget {
  const ProfilePrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.navy.withValues(alpha: 0.8), height: 1.4);

    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20, color: AppColors.navy),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Suas informações ficam só neste aparelho. '
              'O CeliLac não substitui orientação médica ou nutricional.',
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
