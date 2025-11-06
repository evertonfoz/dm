import '../../domain/entities/daily_goal_entity.dart';
import '../dtos/daily_goal_dto.dart';

/// Mapper para conversão bidirecional entre Entity e DTO
/// Centraliza conversões e normalizações (SEM regras de negócio)
class DailyGoalMapper {
  /// Converte DTO (backend) para Entity (domínio)
  static DailyGoalEntity toEntity(DailyGoalDto dto) {
    return DailyGoalEntity(
      id: dto.goalId,
      userId: dto.uid,
      type: GoalType.fromString(dto.goalType),
      targetValue: dto.target,
      currentValue: dto.current,
      date: DateTime.parse(dto.dateIso), // Converte ISO 8601 para DateTime
      isCompleted: dto.completed,
    );
  }

  /// Converte Entity (domínio) para DTO (backend)
  static DailyGoalDto toDto(DailyGoalEntity entity) {
    return DailyGoalDto(
      goalId: entity.id,
      uid: entity.userId,
      goalType: entity.type.name,
      target: entity.targetValue,
      current: entity.currentValue,
      dateIso: _formatDateToIso(entity.date), // Normalização: formato ISO 8601
      completed: entity.isCompleted,
    );
  }

  /// Formata DateTime para ISO 8601 (apenas data, sem hora)
  static String _formatDateToIso(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Converte lista de DTOs para Entities
  static List<DailyGoalEntity> toEntityList(List<DailyGoalDto> dtos) {
    return dtos.map(toEntity).toList();
  }

  /// Converte lista de Entities para DTOs
  static List<DailyGoalDto> toDtoList(List<DailyGoalEntity> entities) {
    return entities.map(toDto).toList();
  }
}
