// Interface abstrata para o DTO local da entidade MoodEntry.
// Este arquivo contém apenas a interface (sem implementação).

import '../../../../data/dtos/mood_entry_dto.dart';

abstract class MoodEntryLocalDto {
  /// Upsert em lote por id (insere novos e atualiza existentes).
  Future<void> upsertAll(List<MoodEntryDto> dtos);

  /// Lista todos os registros locais (DTOs).
  Future<List<MoodEntryDto>> listAll();

  /// Busca por id (DTO). Usa o campo `id` do DTO (String).
  Future<MoodEntryDto?> getById(String id);

  /// Limpa o cache (útil para reset/diagnóstico).
  Future<void> clear();
}
