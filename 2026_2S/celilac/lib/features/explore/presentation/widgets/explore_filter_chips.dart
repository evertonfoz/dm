import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../establishments/domain/entities/dietary_option.dart';
import '../../../establishments/domain/entities/establishment_category.dart';
import '../../domain/explore_filters.dart';

/// Os filtros em linhas que quebram (`Wrap`), sem rolagem horizontal:
/// com fonte grande, nenhum chip fica escondido fora da tela.
class ExploreFilterChips extends StatelessWidget {
  const ExploreFilterChips({
    super.key,
    required this.filters,
    required this.showProfileFilter,
    required this.onCategoryToggle,
    required this.onDietaryToggle,
    required this.onProfileChanged,
    required this.onFavoritesChanged,
  });

  final ExploreFilters filters;

  /// Só faz sentido oferecer "Atende ao meu perfil" a quem tem perfil.
  final bool showProfileFilter;
  final ValueChanged<EstablishmentCategory> onCategoryToggle;
  final ValueChanged<DietaryOption> onDietaryToggle;
  final ValueChanged<bool> onProfileChanged;
  final ValueChanged<bool> onFavoritesChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        if (showProfileFilter)
          FilterChip(
            avatar: const Icon(Icons.person_pin_outlined),
            label: const Text('Atende ao meu perfil'),
            selected: filters.onlyMatchingProfile,
            onSelected: onProfileChanged,
          ),
        FilterChip(
          avatar: const Icon(Icons.favorite_outline),
          label: const Text('Só favoritos'),
          selected: filters.onlyFavorites,
          onSelected: onFavoritesChanged,
        ),
        for (final option in DietaryOption.values)
          FilterChip(
            label: Text(option.label),
            selected: filters.dietaryOptions.contains(option),
            onSelected: (_) => onDietaryToggle(option),
          ),
        for (final category in EstablishmentCategory.values)
          FilterChip(
            label: Text(category.label),
            selected: filters.categories.contains(category),
            onSelected: (_) => onCategoryToggle(category),
          ),
      ],
    );
  }
}
