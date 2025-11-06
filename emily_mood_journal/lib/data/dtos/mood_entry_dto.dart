/// DTO espelhando o schema do backend/API remota
/// Mantém fidelidade com a estrutura JSON da API
class MoodEntryDto { // Backend pode retornar null

  const MoodEntryDto({
    required this.id,
    required this.moodLevel,
    required this.timestamp,
    this.notes,
    this.tagsList,
  });

  /// Converte do JSON da API
  factory MoodEntryDto.fromJson(Map<String, dynamic> json) {
    return MoodEntryDto(
      id: json['id'] as String,
      moodLevel: json['mood_level'] as int,
      timestamp: json['timestamp'] as int,
      notes: json['notes'] as String?,
      tagsList: (json['tags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
  final String id;
  final int moodLevel; // Backend usa int (1-5)
  final int timestamp; // Backend usa timestamp Unix em milissegundos
  final String? notes; // Backend usa "notes" (plural)
  final List<String>? tagsList;

  /// Converte para JSON da API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mood_level': moodLevel,
      'timestamp': timestamp,
      'notes': notes,
      'tags': tagsList,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MoodEntryDto &&
        other.id == id &&
        other.moodLevel == moodLevel &&
        other.timestamp == timestamp &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        moodLevel.hashCode ^
        timestamp.hashCode ^
        notes.hashCode;
  }

  @override
  String toString() {
    return 'MoodEntryDto(id: $id, moodLevel: $moodLevel, timestamp: $timestamp)';
  }
}
