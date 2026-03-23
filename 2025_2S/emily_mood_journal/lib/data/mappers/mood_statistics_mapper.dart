import '../../domain/entities/mood_statistics_entity.dart';
import '../dtos/mood_statistics_dto.dart';

/// Mapper para conversão bidirecional entre Entity e DTO
/// Centraliza conversões e normalizações (SEM regras de negócio)
class MoodStatisticsMapper {
  /// Converte DTO (backend) para Entity (domínio)
  static MoodStatisticsEntity toEntity(MoodStatisticsDto dto) {
    return MoodStatisticsEntity(
      userId: dto.uid,
      period: Period.fromString(dto.periodType),
      averageMood: dto.avg,
      totalEntries: dto.count,
      moodDistribution: _normalizeDistribution(dto.distribution),
      startDate: DateTime.fromMillisecondsSinceEpoch(dto.startTs),
      endDate: DateTime.fromMillisecondsSinceEpoch(dto.endTs),
    );
  }

  /// Converte Entity (domínio) para DTO (backend)
  static MoodStatisticsDto toDto(MoodStatisticsEntity entity) {
    return MoodStatisticsDto(
      uid: entity.userId,
      periodType: entity.period.name,
      avg: entity.averageMood,
      count: entity.totalEntries,
      distribution: _denormalizeDistribution(entity.moodDistribution),
      startTs: entity.startDate.millisecondsSinceEpoch,
      endTs: entity.endDate.millisecondsSinceEpoch,
    );
  }

  /// Normaliza distribuição do backend (Map<String, dynamic>) para Map<String, int>
  static Map<String, int> _normalizeDistribution(Map<String, dynamic> distribution) {
    final normalized = <String, int>{};
    distribution.forEach((key, value) {
      normalized[key] = (value as num).toInt();
    });
    return normalized;
  }

  /// Denormaliza distribuição para formato do backend
  static Map<String, dynamic> _denormalizeDistribution(Map<String, int> distribution) {
    final denormalized = <String, dynamic>{};
    distribution.forEach((key, value) {
      denormalized[key] = value;
    });
    return denormalized;
  }

  /// Converte lista de DTOs para Entities
  static List<MoodStatisticsEntity> toEntityList(List<MoodStatisticsDto> dtos) {
    return dtos.map(toEntity).toList();
  }

  /// Converte lista de Entities para DTOs
  static List<MoodStatisticsDto> toDtoList(List<MoodStatisticsEntity> entities) {
    return entities.map(toDto).toList();
  }
}
