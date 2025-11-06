/// Entity de domínio para Perfil do Usuário
/// Contém invariantes de domínio e validações
class UserProfileEntity {

  UserProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    this.lastUpdated,
  })  : assert(id.isNotEmpty, 'ID não pode ser vazio'),
        assert(name.isNotEmpty, 'Nome não pode ser vazio'),
        assert(name.length >= 2, 'Nome deve ter no mínimo 2 caracteres'),
        assert(name.length <= 100, 'Nome não pode exceder 100 caracteres');
  final String id;
  final String name;
  final Email email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastUpdated;

  /// Invariante: nome deve ter pelo menos duas letras
  bool get hasValidName => name.trim().length >= 2;

  /// Verifica se tem foto de perfil
  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  /// Retorna iniciais do nome (até 2 caracteres)
  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  /// Verifica se perfil está completo
  bool get isComplete => hasValidName && email.isValid;

  /// Cópia com modificação
  UserProfileEntity copyWith({
    String? id,
    String? name,
    Email? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return UserProfileEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfileEntity &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.photoUrl == photoUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        photoUrl.hashCode;
  }

  @override
  String toString() {
    return 'UserProfileEntity(id: $id, name: $name, email: ${email.value})';
  }
}

/// Value Object para Email com validação
class Email {

  Email(this.value) : assert(_isValidEmail(value), 'Email inválido: $value');
  final String value;

  static bool _isValidEmail(String email) {
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return regex.hasMatch(email);
  }

  bool get isValid => _isValidEmail(value);

  String get domain => value.split('@').last;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Email && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
