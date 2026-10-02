import 'package:celilac/features/home/presentation/greeting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime at(int hour) => DateTime(2026, 1, 1, hour);

  test('retorna "Bom dia" das 5h às 11h59', () {
    expect(greetingFor(at(5)), 'Bom dia');
    expect(greetingFor(at(11)), 'Bom dia');
  });

  test('retorna "Boa tarde" das 12h às 17h59', () {
    expect(greetingFor(at(12)), 'Boa tarde');
    expect(greetingFor(at(17)), 'Boa tarde');
  });

  test('retorna "Boa noite" das 18h às 4h59', () {
    expect(greetingFor(at(18)), 'Boa noite');
    expect(greetingFor(at(0)), 'Boa noite');
    expect(greetingFor(at(4)), 'Boa noite');
  });
}
