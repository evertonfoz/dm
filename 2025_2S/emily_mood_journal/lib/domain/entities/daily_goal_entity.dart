/// Entity de domínio para Meta Diária
/// Contém invariantes de domínio e validações
class DailyGoalEntity {

  DailyGoalEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.date,
    required this.isCompleted,
  })  : assert(id.isNotEmpty, 'ID não pode ser vazio'),
        assert(userId.isNotEmpty, 'User ID não pode ser vazio'),
        assert(targetValue > 0, 'Valor alvo deve ser positivo'),
        assert(currentValue >= 0, 'Valor atual não pode ser negativo');
  final String id;
  final String userId;
  final GoalType type;
  final int targetValue;
  final int currentValue;
  final DateTime date;
  final bool isCompleted;

  /// Invariante: progresso não pode exceder 100%
  double get progress {
    final calculated = (currentValue / targetValue).clamp(0.0, 1.0);
    return calculated;
  }

  /// Progresso em porcentagem
  int get progressPercentage => (progress * 100).round();

  /// Verifica se a meta foi atingida
  bool get isAchieved => currentValue >= targetValue;

  /// Quantidade restante para completar a meta
  int get remaining => (targetValue - currentValue).clamp(0, targetValue);

  /// Verifica se é de hoje
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Cópia com modificação
  DailyGoalEntity copyWith({
    String? id,
    String? userId,
    GoalType? type,
    int? targetValue,
    int? currentValue,
    DateTime? date,
    bool? isCompleted,
  }) {
    return DailyGoalEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DailyGoalEntity &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.targetValue == targetValue &&
        other.currentValue == currentValue;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        type.hashCode ^
        targetValue.hashCode ^
        currentValue.hashCode;
  }

  @override
  String toString() {
    return 'DailyGoalEntity(id: $id, type: $type, progress: $progressPercentage%)';
  }
}

/// Enum de domínio para tipos de meta
enum GoalType {
  moodEntries('Registros de Humor', '📝'),
  positiveEntries('Registros Positivos', '😊'),
  reflection('Momentos de Reflexão', '🧘'),
  gratitude('Gratidão', '🙏');

  final String description;
  final String icon;

  const GoalType(this.description, this.icon);

  /// Cria GoalType a partir de string
  static GoalType fromString(String value) {
    return GoalType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => throw ArgumentError('Tipo de meta inválido: $value'),
    );
  }
}
