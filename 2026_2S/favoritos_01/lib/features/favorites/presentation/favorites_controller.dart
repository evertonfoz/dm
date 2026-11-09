import 'package:flutter/foundation.dart';

import '../../establishments/domain/entities/establishment.dart';

class FavoritesController extends ChangeNotifier {
  // 1. Lista privada: preserva a ordem de inserção (mais recente no índice 0).
  List<Establishment> _favorites = const [];

  // 2. Conjunto privado de IDs: garante consulta isFavorite(id) em tempo O(1).
  Set<String> _favoriteIds = const {};

  // Exposição somente-leitura da lista ordenada.
  List<Establishment> get favorites => _favorites;

  // Consulta em tempo constante O(1) chamada no build de cada cartão.
  bool isFavorite(String establishmentId) =>
      _favoriteIds.contains(establishmentId);

  /// Alterna o estado de favorito de [establishment].
  ///
  /// Devolve `true` se o lugar passou a ser favorito e `false` se foi removido.
  bool toggle(Establishment establishment) {
    if (isFavorite(establishment.establishmentId)) {
      // Remoção: cria nova lista imutável sem o item e remove o ID do Set.
      _favorites = List.unmodifiable(
        _favorites.where(
          (item) => item.establishmentId != establishment.establishmentId,
        ),
      );
      _favoriteIds = {..._favoriteIds}..remove(establishment.establishmentId);

      // Avisa todos os widgets inscritos via context.watch!
      notifyListeners();
      return false;
    }

    // Adição: posiciona o novo favorito no índice 0 (topo da lista).
    _favorites = List.unmodifiable([
      establishment,
      ..._favorites.where(
        (item) => item.establishmentId != establishment.establishmentId,
      ),
    ]);
    _favoriteIds = {..._favoriteIds, establishment.establishmentId};

    // Avisa todos os widgets inscritos via context.watch!
    notifyListeners();
    return true;
  }
}
