import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../establishments/domain/entities/dietary_option.dart';
import '../../../establishments/presentation/widgets/dietary_badge.dart';
import '../../domain/entities/dietary_profile.dart';

class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.profile,
    required this.onEdit,
  });

  final DietaryProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = profile.name;
    final secondaryStyle = textTheme.bodyMedium?.copyWith(
      color: AppColors.navy.withValues(alpha: 0.8),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    child: name == null
                        ? const Icon(Icons.person_outline)
                        : Text(
                            name.characters.first.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      name ?? 'Seu perfil',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Você procura opções', style: secondaryStyle),
            const SizedBox(height: AppSpacing.sm),
            // O mesmo selo dos cartões: a pessoa reconhece o que combina.
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final option in DietaryOption.values)
                  if (profile.restrictions.contains(option))
                    DietaryBadge(option: option),
              ],
            ),
            if (profile.needsCrossContactCare) ...[
              const SizedBox(height: AppSpacing.md),
              MergeSemantics(
                child: Row(
                  children: [
                    const Icon(
                      Icons.health_and_safety_outlined,
                      size: 20,
                      color: AppColors.navy,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Com cuidado contra contaminação cruzada',
                        style: secondaryStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar perfil'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
