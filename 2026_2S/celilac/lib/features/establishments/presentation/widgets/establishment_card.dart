import 'package:flutter/material.dart';

import '../../../../app/common/formatters.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/establishment.dart';
import '../establishment_hero_tag.dart';
import 'dietary_badge.dart';
import 'establishment_logo.dart';
import 'favorite_button.dart';

class EstablishmentCard extends StatelessWidget {
  const EstablishmentCard({
    super.key,
    required this.establishment,
    required this.onTap,
    this.matchesProfile = false,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.heroOrigin = 'home',
  });

  final Establishment establishment;
  final VoidCallback onTap;

  /// Quem decide é a tela que usa o cartão: estabelecimentos não conhecem
  /// o perfil.
  final bool matchesProfile;

  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final String heroOrigin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final details = [
      establishment.category.label,
      establishment.neighborhood,
      formatDistance(establishment.distanceInKm),
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: establishmentHeroTag(
                      establishment.id,
                      origin: heroOrigin,
                    ),
                    child: EstablishmentLogo(establishment: establishment),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          establishment.name,
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          details,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.navy.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final option in establishment.dietaryOptions)
                              DietaryBadge(option: option),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: AppColors.gold,
                            semanticLabel: 'Nota',
                          ),
                          const SizedBox(width: 2),
                          Text(
                            formatDecimal(establishment.rating),
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.navy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (onFavoriteToggle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        FavoriteButton(
                          establishmentName: establishment.name,
                          isFavorite: isFavorite,
                          onPressed: onFavoriteToggle!,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              // Abaixo da linha toda, à direita: alinhado com a nota.
              if (matchesProfile) ...[
                const SizedBox(height: AppSpacing.sm),
                const _ProfileMatchBadge(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMatchBadge extends StatelessWidget {
  const _ProfileMatchBadge();

  @override
  Widget build(BuildContext context) {
    // Navy cheio, diferente dos selos dourados: é sobre a pessoa, não
    // sobre o lugar. Ícone e texto, para não depender só da cor.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_pin_outlined, size: 14, color: Colors.white),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'Atende ao seu perfil',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
