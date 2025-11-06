import '../../domain/entities/user_profile_entity.dart';
import '../dtos/user_profile_dto.dart';

/// Mapper para conversão bidirecional entre Entity e DTO
/// Centraliza conversões e normalizações (SEM regras de negócio)
class UserProfileMapper {
  /// Converte DTO (backend) para Entity (domínio)
  static UserProfileEntity toEntity(UserProfileDto dto) {
    return UserProfileEntity(
      id: dto.userId,
      name: dto.userName.trim(), // Normalização: remove espaços extras
      email: Email(dto.userEmail.toLowerCase()), // Normalização: lowercase
      photoUrl: dto.photoBase64?.isNotEmpty == true ? dto.photoBase64 : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(dto.createdTimestamp),
      lastUpdated: dto.updatedTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(dto.updatedTimestamp!)
          : null,
    );
  }

  /// Converte Entity (domínio) para DTO (backend)
  static UserProfileDto toDto(UserProfileEntity entity) {
    return UserProfileDto(
      userId: entity.id,
      userName: entity.name,
      userEmail: entity.email.value,
      photoBase64: entity.photoUrl,
      createdTimestamp: entity.createdAt.millisecondsSinceEpoch,
      updatedTimestamp: entity.lastUpdated?.millisecondsSinceEpoch,
    );
  }

  /// Converte lista de DTOs para Entities
  static List<UserProfileEntity> toEntityList(List<UserProfileDto> dtos) {
    return dtos.map(toEntity).toList();
  }

  /// Converte lista de Entities para DTOs
  static List<UserProfileDto> toDtoList(List<UserProfileEntity> entities) {
    return entities.map(toDto).toList();
  }
}
