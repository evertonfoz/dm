import 'package:flutter/material.dart';

import '../../../establishments/domain/enums/dietary_option.dart';
import '../../../establishments/domain/enums/establishment_category.dart';
import '../../domain/filters/explorer_filters.dart';

class ExploreFilterChips extends StatelessWidget {
  const ExploreFilterChips({
    super.key,
    required this.filters,
    required this.onCategoryToggle,
    required this.onDietaryToggle,
    required this.onFavoritesChanged,
  });

  final ExploreFilters filters;
  final ValueChanged<EstablishmentCategory> onCategoryToggle;
  final ValueChanged<DietaryOption> onDietaryToggle;
  final ValueChanged<bool> onFavoritesChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        FilterChip(
          avatar: const Icon(Icons.favorite_outline),
          label: const Text('Só favoritos'),
          selected: filters.onlyFavorites,
          onSelected: onFavoritesChanged,
        ),
        for (final option in DietaryOption.values)
          FilterChip(
            label: Text(option.displayName),
            selected: filters.dietaryOptions.contains(option),
            onSelected: (_) => onDietaryToggle(option),
          ),
        for (final category in EstablishmentCategory.values)
          FilterChip(
            label: Text(category.displayName),
            selected: filters.categories.contains(category),
            onSelected: (_) => onCategoryToggle(category),
          ),
      ],
    );
  }
}
