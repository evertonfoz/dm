/// Entity de domínio para Registro de Humor
/// Contém invariantes de domínio e tipos fortes
class MoodEntryEntity {

  MoodEntryEntity({
    required this.id,
    required this.level,
    required this.timestamp,
    this.note,
    List<String>? tags,
  })  : tags = tags ?? [],
        assert(id.isNotEmpty, 'ID não pode ser vazio'),
        assert(
            note == null || note.length <= 500, 'Nota não pode exceder 500 caracteres');
  final String id;
  final MoodLevel level;
  final DateTime timestamp;
  final String? note;
  final List<String> tags;

  /// Invariante: horário não pode ser no futuro
  bool get isValid => !timestamp.isAfter(DateTime.now());

  /// Verifica se o registro tem anotações
  bool get hasNote => note != null && note!.isNotEmpty;

  /// Retorna a intensidade numérica do humor (1-5)
  int get intensity => level.value;

  /// Cópia com modificação
  MoodEntryEntity copyWith({
    String? id,
    MoodLevel? level,
    DateTime? timestamp,
    String? note,
    List<String>? tags,
  }) {
    return MoodEntryEntity(
      id: id ?? this.id,
      level: level ?? this.level,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MoodEntryEntity &&
        other.id == id &&
        other.level == level &&
        other.timestamp == timestamp &&
        other.note == note;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        level.hashCode ^
        timestamp.hashCode ^
        note.hashCode;
  }

  @override
  String toString() {
    return 'MoodEntryEntity(id: $id, level: $level, timestamp: $timestamp, hasNote: $hasNote)';
  }
}

/// Enum de domínio com valor semântico
enum MoodLevel {
  veryHappy(5, '😄', 'Muito feliz'),
  happy(4, '😊', 'Feliz'),
  neutral(3, '😐', 'Neutro'),
  sad(2, '😔', 'Triste'),
  verySad(1, '😢', 'Muito triste');

  final int value;
  final String emoji;
  final String description;

  const MoodLevel(this.value, this.emoji, this.description);

  /// Cria MoodLevel a partir de valor numérico
  static MoodLevel fromValue(int value) {
    switch (value) {
      case 5:
        return MoodLevel.veryHappy;
      case 4:
        return MoodLevel.happy;
      case 3:
        return MoodLevel.neutral;
      case 2:
        return MoodLevel.sad;
      case 1:
        return MoodLevel.verySad;
      default:
        throw ArgumentError('Valor de humor inválido: $value. Deve ser entre 1 e 5.');
    }
  }

  /// Cria MoodLevel a partir de string
  static MoodLevel fromString(String value) {
    return MoodLevel.values.firstWhere(
      (level) => level.name == value,
      orElse: () => throw ArgumentError('Tipo de humor inválido: $value'),
    );
  }
}
