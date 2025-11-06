/// DTO espelhando o schema do backend/API remota
/// Mantém fidelidade com a estrutura JSON da API
class DailyGoalDto {

  const DailyGoalDto({
    required this.goalId,
    required this.uid,
    required this.goalType,
    required this.target,
    required this.current,
    required this.dateIso,
    required this.completed,
  });

  /// Converte do JSON da API
  factory DailyGoalDto.fromJson(Map<String, dynamic> json) {
    return DailyGoalDto(
      goalId: json['goal_id'] as String,
      uid: json['uid'] as String,
      goalType: json['goal_type'] as String,
      target: json['target'] as int,
      current: json['current'] as int,
      dateIso: json['date_iso'] as String,
      completed: json['completed'] as bool,
    );
  }
  final String goalId;
  final String uid; // Backend usa "uid" para user ID
  final String goalType; // Backend armazena como string
  final int target;
  final int current;
  final String dateIso; // Backend usa ISO 8601 string
  final bool completed;

  /// Converte para JSON da API
  Map<String, dynamic> toJson() {
    return {
      'goal_id': goalId,
      'uid': uid,
      'goal_type': goalType,
      'target': target,
      'current': current,
      'date_iso': dateIso,
      'completed': completed,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DailyGoalDto &&
        other.goalId == goalId &&
        other.uid == uid &&
        other.goalType == goalType &&
        other.target == target &&
        other.current == current;
  }

  @override
  int get hashCode {
    return goalId.hashCode ^
        uid.hashCode ^
        goalType.hashCode ^
        target.hashCode ^
        current.hashCode;
  }

  @override
  String toString() {
    return 'DailyGoalDto(goalId: $goalId, goalType: $goalType, current: $current/$target)';
  }
}
