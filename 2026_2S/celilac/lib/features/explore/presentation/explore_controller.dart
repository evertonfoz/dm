import 'package:flutter/foundation.dart';

import '../../establishments/domain/entities/dietary_option.dart';
import '../../establishments/domain/entities/establishment.dart';
import '../../establishments/domain/entities/establishment_category.dart';
import '../../establishments/domain/repositories/establishment_repository.dart';
import '../domain/explore_filters.dart';
import '../domain/explore_sort.dart';

enum ExploreStatus { loading, ready, failure }

/// Guarda o catálogo e as escolhas de filtro. Não guarda a lista filtrada:
/// ela é calculada na tela, juntando este estado com perfil e favoritos.
class ExploreController extends ChangeNotifier {
  ExploreController(this._repository);

  final EstablishmentRepository _repository;

  ExploreStatus _status = ExploreStatus.loading;
  List<Establishment> _catalog = const [];
  ExploreFilters _filters = ExploreFilters.initial;
  Future<void>? _loading;

  ExploreStatus get status => _status;
  List<Establishment> get catalog => _catalog;
  ExploreFilters get filters => _filters;

  /// Carrega uma única vez, mesmo que várias telas peçam.
  Future<void> load() => _loading ??= _load();

  /// Nova tentativa depois de uma falha.
  Future<void> retry() {
    _status = ExploreStatus.loading;
    notifyListeners();
    return _loading = _load();
  }

  Future<void> _load() async {
    try {
      _catalog = List.unmodifiable(await _repository.fetchNearby());
      _status = ExploreStatus.ready;
    } catch (error) {
      debugPrint('Não foi possível carregar o catálogo: $error');
      _status = ExploreStatus.failure;
    }
    notifyListeners();
  }

  void setQuery(String query) => _update(_filters.copyWith(query: query));

  void toggleCategory(EstablishmentCategory category) {
    _update(
      _filters.copyWith(categories: _toggled(_filters.categories, category)),
    );
  }

  void toggleDietaryOption(DietaryOption option) {
    _update(
      _filters.copyWith(
        dietaryOptions: _toggled(_filters.dietaryOptions, option),
      ),
    );
  }

  void setOnlyMatchingProfile(bool value) =>
      _update(_filters.copyWith(onlyMatchingProfile: value));

  void setOnlyFavorites(bool value) =>
      _update(_filters.copyWith(onlyFavorites: value));

  void setSort(ExploreSort sort) => _update(_filters.copyWith(sort: sort));

  void clearFilters() => _update(_filters.cleared());

  /// Atalho da Home: começa uma exploração só desta categoria.
  void showOnly(EstablishmentCategory category) {
    _update(_filters.cleared().copyWith(categories: {category}));
  }

  void _update(ExploreFilters next) {
    if (next == _filters) return;
    _filters = next;
    notifyListeners();
  }

  Set<T> _toggled<T>(Set<T> current, T item) {
    return current.contains(item)
        ? ({...current}..remove(item))
        : {...current, item};
  }
}
