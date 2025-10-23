import '../dtos/provider_dto.dart';

abstract class ProvidersLocalDao {
  /// Upsert em lote por id (insere novos e atualiza existentes).
  Future<void> upsertAll(List<ProviderDto> dtos);

  /// Lista todos os registros locais (DTOs).
  Future<List<ProviderDto>> listAll();

  /// Busca por id (DTO).
  Future<ProviderDto?> getById(int id);

  /// Limpa o cache (útil para reset/diagnóstico).
  Future<void> clear();
}
