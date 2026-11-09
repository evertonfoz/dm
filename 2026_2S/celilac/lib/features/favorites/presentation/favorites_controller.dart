import 'package:flutter/foundation.dart';

import '../../establishments/domain/entities/establishment.dart';
import '../domain/repositories/favorites_repository.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController(this._repository);

  final FavoritesRepository _repository;

  List<Establishment> _favorites = const [];
  Set<String> _favoriteIds = const {};
  bool _isLoaded = false;
  Future<void>? _loading;

  List<Establishment> get favorites => _favorites;
  bool get isLoaded => _isLoaded;

  bool isFavorite(String establishmentId) =>
      _favoriteIds.contains(establishmentId);

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final loaded = await _repository.loadAll();
      _setFavorites(loaded);
    } catch (error) {
      // Os favoritos não podem impedir que o app abra.
      debugPrint('Não foi possível carregar os favoritos: $error');
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Alterna o estado de favorito de [establishment].
  /// Devolve `true` se passou a ser favorito, ou `false` se foi removido.
  Future<bool> toggle(Establishment establishment) async {
    if (isFavorite(establishment.id)) {
      await _repository.remove(establishment.id);
      _setFavorites([
        for (final item in _favorites)
          if (item.id != establishment.id) item,
      ]);
      _isLoaded = true;
      notifyListeners();
      return false;
    } else {
      await _repository.add(establishment);
      _setFavorites([
        establishment,
        for (final item in _favorites)
          if (item.id != establishment.id) item,
      ]);
      _isLoaded = true;
      notifyListeners();
      return true;
    }
  }

  void _setFavorites(List<Establishment> items) {
    _favorites = List.unmodifiable(items);
    _favoriteIds = {for (final item in items) item.id};
  }
}

