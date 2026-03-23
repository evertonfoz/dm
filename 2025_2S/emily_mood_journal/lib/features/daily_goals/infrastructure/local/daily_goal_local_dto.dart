// Interface abstrata para o DTO local da entidade DailyGoal.
// Este arquivo contém apenas a interface (sem implementação).

import '../../../../data/dtos/daily_goal_dto.dart';

abstract class DailyGoalLocalDto {
  /// Upsert em lote por id (insere novos e atualiza existentes).
  Future<void> upsertAll(List<DailyGoalDto> dtos);

  /// Lista todos os registros locais (DTOs).
  Future<List<DailyGoalDto>> listAll();

  /// Busca por id (DTO).
  /// Busca por id (DTO). Usa o campo `goalId` (String) do DTO.
  Future<DailyGoalDto?> getById(String id);

  /// Limpa o cache (útil para reset/diagnóstico).
  Future<void> clear();
}
