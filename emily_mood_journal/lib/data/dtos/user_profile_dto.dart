/// DTO espelhando o schema do backend/API remota
/// Mantém fidelidade com a estrutura JSON da API
class UserProfileDto { // Pode ser null se nunca foi atualizado

  const UserProfileDto({
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.photoBase64,
    required this.createdTimestamp,
    this.updatedTimestamp,
  });

  /// Converte do JSON da API
  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userEmail: json['user_email'] as String,
      photoBase64: json['photo_base64'] as String?,
      createdTimestamp: json['created_timestamp'] as int,
      updatedTimestamp: json['updated_timestamp'] as int?,
    );
  }
  final String userId;
  final String userName;
  final String userEmail;
  final String? photoBase64; // Backend pode armazenar foto em base64
  final int createdTimestamp; // Timestamp Unix em milissegundos
  final int? updatedTimestamp;

  /// Converte para JSON da API
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'photo_base64': photoBase64,
      'created_timestamp': createdTimestamp,
      'updated_timestamp': updatedTimestamp,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfileDto &&
        other.userId == userId &&
        other.userName == userName &&
        other.userEmail == userEmail &&
        other.photoBase64 == photoBase64;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        userName.hashCode ^
        userEmail.hashCode ^
        photoBase64.hashCode;
  }

  @override
  String toString() {
    return 'UserProfileDto(userId: $userId, userName: $userName, userEmail: $userEmail)';
  }
}
