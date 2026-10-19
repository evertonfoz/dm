String formatDecimal(double value, {int digits = 1}) {
  return value.toStringAsFixed(digits).replaceAll('.', ',');
}

String formatDistance(double kilometers) {
  if (kilometers < 1) {
    return '${(kilometers * 1000).round()} m';
  }
  return '${formatDecimal(kilometers)} km';
}

String formatHour(Duration timeOfDay) {
  final hours = timeOfDay.inHours;
  final minutes = timeOfDay.inMinutes % 60;
  if (minutes == 0) {
    return '${hours}h';
  }
  return '${hours}h${minutes.toString().padLeft(2, '0')}';
}

const List<String> _weekdayNames = [
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
  'Domingo',
];

String formatWeekday(int weekday) => _weekdayNames[weekday - 1];
