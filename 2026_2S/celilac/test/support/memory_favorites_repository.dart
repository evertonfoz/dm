import 'package:celilac/features/establishments/domain/entities/establishment.dart';
import 'package:celilac/features/favorites/domain/repositories/favorites_repository.dart';

class MemoryFavoritesRepository implements FavoritesRepository {
  MemoryFavoritesRepository({
    List<Establishment> stored = const [],
    this.failOnLoad = false,
    this.failOnChange = false,
  }) : _stored = List.of(stored);

  final List<Establishment> _stored;
  bool failOnLoad;
  bool failOnChange;
  int loadCalls = 0;
  int addCalls = 0;
  int removeCalls = 0;

  List<Establishment> get stored => List.unmodifiable(_stored);

  @override
  Future<List<Establishment>> loadAll() async {
    loadCalls++;
    if (failOnLoad) {
      throw Exception('falha ao ler favoritos');
    }
    return List.of(_stored);
  }

  @override
  Future<bool> isFavorite(String establishmentId) async {
    return _stored.any((item) => item.id == establishmentId);
  }

  @override
  Future<void> add(Establishment establishment, {DateTime? savedAt}) async {
    addCalls++;
    if (failOnChange) {
      throw Exception('falha ao salvar favorito');
    }
    _stored.removeWhere((item) => item.id == establishment.id);
    _stored.insert(0, establishment);
  }

  @override
  Future<void> remove(String establishmentId) async {
    removeCalls++;
    if (failOnChange) {
      throw Exception('falha ao remover favorito');
    }
    _stored.removeWhere((item) => item.id == establishmentId);
  }
}

