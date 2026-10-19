import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/safety_practice.dart';
import '../safety_practice_icon.dart';

class SafetyPracticesList extends StatelessWidget {
  const SafetyPracticesList({super.key, required this.practices});

  final Set<SafetyPractice> practices;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bodyStyle = textTheme.bodyMedium?.copyWith(color: AppColors.navy);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (practices.isEmpty)
          Text(
            'O estabelecimento ainda não informou os seus cuidados.',
            style: bodyStyle,
          ),
        for (final practice in SafetyPractice.values)
          if (practices.contains(practice))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(practice.icon, size: 20, color: AppColors.navy),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(practice.label, style: bodyStyle)),
                ],
              ),
            ),
        const Divider(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: AppColors.navy.withValues(alpha: 0.8),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Informações fornecidas pelo estabelecimento. Em caso de '
                'dúvida, confirme no local antes de consumir.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.navy.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
