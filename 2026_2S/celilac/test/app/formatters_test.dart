import 'package:celilac/app/common/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formata distâncias menores que 1 km em metros', () {
    expect(formatDistance(0.35), '350 m');
  });

  test('formata distâncias a partir de 1 km com vírgula decimal', () {
    expect(formatDistance(1.2), '1,2 km');
    expect(formatDistance(1), '1,0 km');
  });

  test('formata horários sem minutos e com minutos', () {
    expect(formatHour(const Duration(hours: 7)), '7h');
    expect(formatHour(const Duration(hours: 6, minutes: 30)), '6h30');
    expect(formatHour(const Duration(hours: 9, minutes: 5)), '9h05');
  });

  test('formata os dias da semana a partir do DateTime.weekday', () {
    expect(formatWeekday(DateTime.monday), 'Segunda-feira');
    expect(formatWeekday(DateTime.sunday), 'Domingo');
  });
}
