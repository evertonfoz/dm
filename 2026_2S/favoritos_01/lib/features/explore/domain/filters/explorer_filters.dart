import 'package:favoritos_01/features/establishments/domain/enums/dietary_option.dart';
import 'package:favoritos_01/features/establishments/domain/enums/establishment_category.dart';
import 'package:favoritos_01/features/establishments/presentation/widgets/establishment_card.dart';
import 'package:flutter/foundation.dart';

import '../enums/explore_sort.dart';

class ExploreFilters {
  const ExploreFilters({
    this.query = '',
    this.categories = const {},
    this.dietaryOptions = const {},
    this.onlyFavorites = false,
    this.sort = ExploreSort.distance,
  });

  final String query;
  final Set<EstablishmentCategory> categories;
  final Set<DietaryOption> dietaryOptions;
  final bool onlyFavorites;
  final ExploreSort sort;

  int get activeCount =>
      (query.isNotEmpty ? 1 : 0) +
      (categories.length) +
      (dietaryOptions.length) +
      (onlyFavorites ? 1 : 0);

  bool get hasActiveFilters => activeCount > 0;

  static const initial = ExploreFilters();

  ExploreFilters cleared() => ExploreFilters(sort: sort);

  ExploreFilters copyWith({
    String? query,
    Set<EstablishmentCategory>? categories,
    Set<DietaryOption>? dietaryOptions,
    bool? onlyFavorites,
    ExploreSort? sort,
  }) {
    return ExploreFilters(
      query: query ?? this.query,
      categories: categories ?? this.categories,
      dietaryOptions: dietaryOptions ?? this.dietaryOptions,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      sort: sort ?? this.sort,
    );
  }
}
