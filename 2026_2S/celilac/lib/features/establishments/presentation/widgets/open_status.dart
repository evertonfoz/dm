import 'package:flutter/material.dart';

import '../../../../app/common/formatters.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/establishment_details.dart';

class OpenStatus extends StatelessWidget {
  const OpenStatus({super.key, required this.details, required this.now});

  final EstablishmentDetails details;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final openPeriod = details.openPeriodAt(now);
    final isOpen = openPeriod != null;
    final label = isOpen
        ? 'Aberto agora · fecha às ${formatHour(openPeriod.closesAt)}'
        : 'Fechado agora';

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isOpen
              ? AppColors.gold.withValues(alpha: 0.18)
              : AppColors.navy.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOpen ? Icons.schedule : Icons.do_not_disturb_on_outlined,
              size: 18,
              color: AppColors.navy,
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
