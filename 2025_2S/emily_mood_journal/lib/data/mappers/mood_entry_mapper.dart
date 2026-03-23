import '../../domain/entities/mood_entry_entity.dart';
import '../dtos/mood_entry_dto.dart';

/// Mapper para conversão bidirecional entre Entity e DTO
/// Centraliza conversões e normalizações (SEM regras de negócio)
class MoodEntryMapper {
  /// Converte DTO (backend) para Entity (domínio)
  static MoodEntryEntity toEntity(MoodEntryDto dto) {
    return MoodEntryEntity(
      id: dto.id,
      level: MoodLevel.fromValue(dto.moodLevel),
      timestamp: DateTime.fromMillisecondsSinceEpoch(dto.timestamp),
      note: dto.notes?.trim(), // Normalização: remove espaços
      tags: dto.tagsList ?? [], // Normalização: null para lista vazia
    );
  }

  /// Converte Entity (domínio) para DTO (backend)
  static MoodEntryDto toDto(MoodEntryEntity entity) {
    return MoodEntryDto(
      id: entity.id,
      moodLevel: entity.level.value,
      timestamp: entity.timestamp.millisecondsSinceEpoch,
      notes: entity.note,
      tagsList: entity.tags.isEmpty ? null : entity.tags, // Backend espera null se vazio
    );
  }

  /// Converte lista de DTOs para Entities
  static List<MoodEntryEntity> toEntityList(List<MoodEntryDto> dtos) {
    return dtos.map(toEntity).toList();
  }

  /// Converte lista de Entities para DTOs
  static List<MoodEntryDto> toDtoList(List<MoodEntryEntity> entities) {
    return entities.map(toDto).toList();
  }
}
