import '../../establishments/domain/entities/establishment.dart';
import 'enums/explore_sort.dart';
import 'filters/explorer_filters.dart';
import 'search_text.dart';

/// Devolve os lugares que passam em [filters], já ordenados.
///
/// Função pura: tudo o que a regra precisa entra por parâmetro e a resposta
/// sai pelo retorno. Não altera [catalog].
List<Establishment> applyExploreFilters(
  List<Establishment> catalog,
  ExploreFilters filters, {
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
    // containsAll com conjunto vazio é true: sem opção escolhida, todo lugar passa.
    if (!e.dietaryOptions.containsAll(filters.dietaryOptions)) {
      return false;
    }
    if (filters.onlyFavorites && !favoriteIds.contains(e.establishmentId)) {
      return false;
    }
    if (words.isEmpty) return true;

    final haystack = normalizeSearchText(
      '${e.name} ${e.neighborhood} ${e.category.displayName} ${e.dietaryOptions.map((o) => o.displayName).join(' ')}',
    );
    return words.every(haystack.contains);
  }

  // where(...).toList() cria uma lista nova: o catálogo original fica intacto.
  final results = catalog.where(matches).toList();
  results.sort(_comparatorFor(filters.sort));
  return results;
}

Comparator<Establishment> _comparatorFor(ExploreSort sort) {
  int byName(Establishment a, Establishment b) =>
      normalizeSearchText(a.name).compareTo(normalizeSearchText(b.name));

  return switch (sort) {
    ExploreSort.distance => (a, b) {
      final result = a.distanceInKm.compareTo(b.distanceInKm);
      return result != 0 ? result : byName(a, b);
    },
    ExploreSort.rating => (a, b) {
      final result = b.rating.compareTo(a.rating); // maior nota primeiro
      return result != 0 ? result : byName(a, b);
    },
    ExploreSort.name => byName,
  };
}
