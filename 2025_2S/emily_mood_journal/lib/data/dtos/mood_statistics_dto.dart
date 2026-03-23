/// DTO espelhando o schema do backend/API remota
/// Mantém fidelidade com a estrutura JSON da API
class MoodStatisticsDto { // Timestamp Unix em milissegundos

  const MoodStatisticsDto({
    required this.uid,
    required this.periodType,
    required this.avg,
    required this.count,
    required this.distribution,
    required this.startTs,
    required this.endTs,
  });

  /// Converte do JSON da API
  factory MoodStatisticsDto.fromJson(Map<String, dynamic> json) {
    return MoodStatisticsDto(
      uid: json['uid'] as String,
      periodType: json['period_type'] as String,
      avg: (json['avg'] as num).toDouble(),
      count: json['count'] as int,
      distribution: json['distribution'] as Map<String, dynamic>,
      startTs: json['start_ts'] as int,
      endTs: json['end_ts'] as int,
    );
  }
  final String uid; // Backend usa "uid" para user ID
  final String periodType; // Backend armazena como string: "week", "month", etc
  final double avg; // Backend usa "avg" abreviado
  final int count; // Backend usa "count" para total
  final Map<String, dynamic> distribution; // Backend retorna Map<String, dynamic>
  final int startTs; // Timestamp Unix em milissegundos
  final int endTs;

  /// Converte para JSON da API
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'period_type': periodType,
      'avg': avg,
      'count': count,
      'distribution': distribution,
      'start_ts': startTs,
      'end_ts': endTs,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MoodStatisticsDto &&
        other.uid == uid &&
        other.periodType == periodType &&
        other.avg == avg &&
        other.count == count &&
        other.startTs == startTs &&
        other.endTs == endTs;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        periodType.hashCode ^
        avg.hashCode ^
        count.hashCode ^
        startTs.hashCode ^
        endTs.hashCode;
  }

  @override
  String toString() {
    return 'MoodStatisticsDto(uid: $uid, period: $periodType, avg: $avg, count: $count)';
  }
}
