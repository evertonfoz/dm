import '../entities/provider.dart';

abstract class ProvidersRepository {
  /// Render inicial rápido a partir do cache local.
  Future<List<Provider>> loadFromCache();

  /// Sincronização incremental (>= lastSync). Retorna quantos registros mudaram.
  Future<int> syncFromServer();

  /// Listagem completa (normalmente do cache após sync).
  Future<List<Provider>> listAll();

  /// Destaques (filtrados do cache por `featured`).
  Future<List<Provider>> listFeatured();

  /// Opcional: busca direta por ID no cache.
  Future<Provider?> getById(int id);
}
