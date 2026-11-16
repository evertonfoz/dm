import '../../establishments/domain/entities/establishment.dart';
import '../../profile/domain/entities/dietary_profile.dart';
import '../../profile/domain/profile_match.dart';
import 'explore_filters.dart';
import 'explore_sort.dart';
import 'search_text.dart';

/// Aplica [filters] ao [catalog] e devolve uma lista nova, já ordenada.
///
/// É uma função pura: o mesmo catálogo, filtros, perfil e favoritos sempre
/// dão o mesmo resultado. Por isso dá para testá-la sem Flutter.
List<Establishment> applyExploreFilters(
  List<Establishment> catalog,
  ExploreFilters filters, {
  required DietaryProfile profile,
  required Set<String> favoriteIds,
}) {
  final words = normalizeSearchText(filters.query)
      .split(' ')
      .where((word) => word.isNotEmpty)
      .toList();

  bool matches(Establishment e) {
    if (filters.categories.isNotEmpty &&
        !filters.categories.contains(e.category)) {
      return false;
    }
    if (!e.dietaryOptions.containsAll(filters.dietaryOptions)) {
      return false;
    }
    if (filters.onlyMatchingProfile && !meetsProfile(e, profile)) {
      return false;
    }
    if (filters.onlyFavorites && !favoriteIds.contains(e.id)) {
      return false;
    }
    if (words.isEmpty) return true;

    final haystack = normalizeSearchText(
      '${e.name} ${e.neighborhood} ${e.category.label}',
    );
    // Todas as palavras digitadas precisam aparecer em algum campo.
    return words.every(haystack.contains);
  }

  final results = catalog.where(matches).toList();
  results.sort(_comparatorFor(filters.sort));
  return results;
}

Comparator<Establishment> _comparatorFor(ExploreSort sort) {
  // List.sort não é estável: o desempate pelo nome deixa a ordem previsível.
  int byName(Establishment a, Establishment b) =>
      normalizeSearchText(a.name).compareTo(normalizeSearchText(b.name));

  return switch (sort) {
    ExploreSort.distance => (a, b) {
      final result = a.distanceInKm.compareTo(b.distanceInKm);
      return result != 0 ? result : byName(a, b);
    },
    ExploreSort.rating => (a, b) {
      final result = b.rating.compareTo(a.rating);
      return result != 0 ? result : byName(a, b);
    },
    ExploreSort.name => byName,
  };
}
