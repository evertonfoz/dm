import '../../establishments/domain/entities/dietary_option.dart';
import '../../establishments/domain/entities/establishment_category.dart';
import 'explore_sort.dart';

/// Tudo o que a pessoa escolheu na tela Explorar, num único valor imutável.
class ExploreFilters {
  const ExploreFilters({
    this.query = '',
    this.categories = const {},
    this.dietaryOptions = const {},
    this.onlyMatchingProfile = false,
    this.onlyFavorites = false,
    this.sort = ExploreSort.distance,
  });

  static const ExploreFilters initial = ExploreFilters();

  final String query;

  /// Vazio significa "qualquer categoria". Com mais de uma, vale qualquer uma.
  final Set<EstablishmentCategory> categories;

  /// O lugar precisa oferecer todas as opções escolhidas.
  final Set<DietaryOption> dietaryOptions;

  final bool onlyMatchingProfile;
  final bool onlyFavorites;
  final ExploreSort sort;

  /// Quantos filtros estão ligados. A ordenação não conta: ela não esconde nada.
  int get activeCount =>
      (query.trim().isEmpty ? 0 : 1) +
      categories.length +
      dietaryOptions.length +
      (onlyMatchingProfile ? 1 : 0) +
      (onlyFavorites ? 1 : 0);

  bool get hasActiveFilters => activeCount > 0;

  /// Volta tudo ao início, mas mantém a ordenação que a pessoa escolheu.
  ExploreFilters cleared() => ExploreFilters(sort: sort);

  ExploreFilters copyWith({
    String? query,
    Set<EstablishmentCategory>? categories,
    Set<DietaryOption>? dietaryOptions,
    bool? onlyMatchingProfile,
    bool? onlyFavorites,
    ExploreSort? sort,
  }) {
    return ExploreFilters(
      query: query ?? this.query,
      categories: categories ?? this.categories,
      dietaryOptions: dietaryOptions ?? this.dietaryOptions,
      onlyMatchingProfile: onlyMatchingProfile ?? this.onlyMatchingProfile,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      sort: sort ?? this.sort,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExploreFilters &&
        other.query == query &&
        other.categories.length == categories.length &&
        other.categories.containsAll(categories) &&
        other.dietaryOptions.length == dietaryOptions.length &&
        other.dietaryOptions.containsAll(dietaryOptions) &&
        other.onlyMatchingProfile == onlyMatchingProfile &&
        other.onlyFavorites == onlyFavorites &&
        other.sort == sort;
  }

  @override
  int get hashCode => Object.hash(
    query,
    Object.hashAllUnordered(categories),
    Object.hashAllUnordered(dietaryOptions),
    onlyMatchingProfile,
    onlyFavorites,
    sort,
  );
}
