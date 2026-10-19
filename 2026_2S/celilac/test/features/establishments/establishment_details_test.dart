import 'package:celilac/features/establishments/domain/entities/establishment_details.dart';
import 'package:celilac/features/establishments/domain/entities/opening_hours.dart';
import 'package:flutter_test/flutter_test.dart';

// 15/10/2026 é uma quinta-feira (DateTime.thursday == 4).
DateTime _thursdayAt(int hour, [int minute = 0]) =>
    DateTime(2026, 10, 15, hour, minute);

const _lunch = OpeningHours(
  weekday: DateTime.thursday,
  opensAt: Duration(hours: 11, minutes: 30),
  closesAt: Duration(hours: 15),
);

const _dinner = OpeningHours(
  weekday: DateTime.thursday,
  opensAt: Duration(hours: 19),
  closesAt: Duration(hours: 23),
);

const _details = EstablishmentDetails(
  establishmentId: '1',
  description: '',
  address: '',
  openingHours: [_lunch, _dinner],
  safetyPractices: {},
);

void main() {
  group('OpeningHours.contains', () {
    test('está aberto entre a abertura e o fechamento', () {
      expect(_lunch.contains(_thursdayAt(11, 30)), isTrue);
      expect(_lunch.contains(_thursdayAt(14, 59)), isTrue);
    });

    test('está fechado antes de abrir e a partir do horário de fechar', () {
      expect(_lunch.contains(_thursdayAt(11, 29)), isFalse);
      expect(_lunch.contains(_thursdayAt(15)), isFalse);
    });

    test('está fechado em outro dia da semana, no mesmo horário', () {
      final friday = DateTime(2026, 10, 16, 12);
      expect(_lunch.contains(friday), isFalse);
    });
  });

  group('EstablishmentDetails', () {
    test('encontra o período aberto em um dia com dois turnos', () {
      expect(_details.openPeriodAt(_thursdayAt(12)), same(_lunch));
      expect(_details.openPeriodAt(_thursdayAt(20)), same(_dinner));
      expect(_details.openPeriodAt(_thursdayAt(17)), isNull);
    });

    test('lista os períodos de um dia, ou nenhum se estiver fechado', () {
      expect(_details.hoursOn(DateTime.thursday), [_lunch, _dinner]);
      expect(_details.hoursOn(DateTime.sunday), isEmpty);
    });
  });
}
