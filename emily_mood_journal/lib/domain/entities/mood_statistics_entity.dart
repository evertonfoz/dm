/// Entity de domínio para Estatísticas de Humor
/// Contém invariantes de domínio e cálculos agregados
class MoodStatisticsEntity {

  MoodStatisticsEntity({
    required this.userId,
    required this.period,
    required this.averageMood,
    required this.totalEntries,
    required this.moodDistribution,
    required this.startDate,
    required this.endDate,
  })  : assert(userId.isNotEmpty, 'User ID não pode ser vazio'),
        assert(averageMood >= 1.0 && averageMood <= 5.0,
            'Média de humor deve estar entre 1.0 e 5.0'),
        assert(totalEntries >= 0, 'Total de registros não pode ser negativo'),
        assert(startDate.isBefore(endDate) || startDate.isAtSameMomentAs(endDate),
            'Data inicial deve ser anterior ou igual à data final');
  final String userId;
  final Period period;
  final double averageMood;
  final int totalEntries;
  final Map<String, int> moodDistribution; // mood level -> count
  final DateTime startDate;
  final DateTime endDate;

  /// Calcula o humor predominante no período
  String get dominantMood {
    if (moodDistribution.isEmpty) return 'neutral';
    
    var maxCount = 0;
    var dominantMoodKey = 'neutral';
    
    moodDistribution.forEach((mood, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantMoodKey = mood;
      }
    });
    
    return dominantMoodKey;
  }

  /// Verifica se há dados suficientes para análise
  bool get hasEnoughData => totalEntries >= 3;

  /// Calcula tendência (positiva, negativa, estável)
  String get trend {
    if (averageMood >= 4.0) return 'positive';
    if (averageMood <= 2.0) return 'negative';
    return 'stable';
  }

  /// Retorna descrição do período em dias
  int get periodInDays => endDate.difference(startDate).inDays;

  /// Média de registros por dia
  double get averageEntriesPerDay {
    final days = periodInDays > 0 ? periodInDays : 1;
    return totalEntries / days;
  }

  /// Cópia com modificação
  MoodStatisticsEntity copyWith({
    String? userId,
    Period? period,
    double? averageMood,
    int? totalEntries,
    Map<String, int>? moodDistribution,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return MoodStatisticsEntity(
      userId: userId ?? this.userId,
      period: period ?? this.period,
      averageMood: averageMood ?? this.averageMood,
      totalEntries: totalEntries ?? this.totalEntries,
      moodDistribution: moodDistribution ?? this.moodDistribution,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MoodStatisticsEntity &&
        other.userId == userId &&
        other.period == period &&
        other.averageMood == averageMood &&
        other.totalEntries == totalEntries &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        period.hashCode ^
        averageMood.hashCode ^
        totalEntries.hashCode ^
        startDate.hashCode ^
        endDate.hashCode;
  }

  @override
  String toString() {
    return 'MoodStatisticsEntity(userId: $userId, period: $period, avgMood: $averageMood, entries: $totalEntries)';
  }
}

/// Enum de domínio para período de análise
enum Period {
  week('Semana', 7),
  month('Mês', 30),
  quarter('Trimestre', 90),
  year('Ano', 365);

  final String description;
  final int days;

  const Period(this.description, this.days);

  /// Cria Period a partir de string
  static Period fromString(String value) {
    return Period.values.firstWhere(
      (period) => period.name == value,
      orElse: () => throw ArgumentError('Período inválido: $value'),
    );
  }
}
