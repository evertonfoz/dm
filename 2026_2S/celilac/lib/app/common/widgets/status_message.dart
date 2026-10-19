import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class StatusMessage extends StatelessWidget {
  const StatusMessage({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.navy),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.navy.withValues(alpha: 0.8)),
            textAlign: TextAlign.center,
          ),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onAction, child: Text(label)),
          ],
        ],
      ),
    );
  }
}
