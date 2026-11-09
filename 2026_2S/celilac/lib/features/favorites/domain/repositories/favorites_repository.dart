import '../../../establishments/domain/entities/establishment.dart';

abstract interface class FavoritesRepository {
  Future<List<Establishment>> loadAll();

  Future<bool> isFavorite(String establishmentId);

  Future<void> add(Establishment establishment, {DateTime? savedAt});

  Future<void> remove(String establishmentId);
}
