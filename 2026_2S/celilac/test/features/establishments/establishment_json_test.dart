import 'dart:convert';

import 'package:celilac/features/establishments/data/establishment_json.dart';
import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/establishments/domain/entities/establishment_category.dart';
import 'package:celilac/features/establishments/domain/entities/safety_practice.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/supabase_api_json.dart';

/// A primeira linha de uma resposta da API, já decodificada.
Map<String, dynamic> _firstRow(String responseJson) =>
    (jsonDecode(responseJson) as List<dynamic>).first as Map<String, dynamic>;

void main() {
  group('establishmentFromJson', () {
    test('converte snake_case, enums, números e o caminho do logo', () {
      final cafe = establishmentFromJson(
        _firstRow(nearbyResponseJson),
        publicUrl: testPublicUrl,
      );

      expect(cafe.id, cafeAconchegoId);
      expect(cafe.name, 'Café Aconchego');
      expect(cafe.category, EstablishmentCategory.cafe);
      expect(cafe.neighborhood, 'Centro');
      expect(cafe.distanceInKm, 0.35);
      expect(cafe.rating, 4.8);
      expect(cafe.dietaryOptions, {
        DietaryOption.glutenFree,
        DietaryOption.lactoseFree,
      });
      expect(
        cafe.logoSource,
        '$testSupabaseUrl/storage/v1/object/public/establishments/'
        'cafe_aconchego/logo.png',
      );
    });

    test('logo nulo continua nulo (o card usa o ícone da categoria)', () {
      final rows = jsonDecode(nearbyResponseJson) as List<dynamic>;
      final emporio = establishmentFromJson(
        rows.last as Map<String, dynamic>,
        publicUrl: testPublicUrl,
      );

      expect(emporio.logoSource, isNull);
      expect(emporio.distanceInKm, 5.0);
      expect(emporio.rating, 4.0);
    });

    test('aceita números inteiros no JSON (5 em vez de 5.0)', () {
      final row = _firstRow(nearbyResponseJson)
        ..['distance_in_km'] = 5
        ..['rating'] = 4;

      final cafe = establishmentFromJson(row, publicUrl: testPublicUrl);

      expect(cafe.distanceInKm, 5.0);
      expect(cafe.rating, 4.0);
    });

    test('valor de enum desconhecido é erro, não um palpite', () {
      final row = _firstRow(nearbyResponseJson)..['category'] = 'bar';

      expect(
        () => establishmentFromJson(row, publicUrl: testPublicUrl),
        throwsArgumentError,
      );
    });
  });

  group('establishmentDetailsFromJson', () {
    test('lê o objeto 1:1 e as listas 1:N embutidas', () {
      final details = establishmentDetailsFromJson(
        _firstRow(cafeAconchegoDetailsResponseJson),
        publicUrl: testPublicUrl,
      )!;

      expect(details.establishmentId, cafeAconchegoId);
      expect(details.address, 'Rua das Palmeiras, 120 - Centro');
      expect(details.phone, '(44) 0000-0101');
      expect(details.description, startsWith('Café de bairro'));
      expect(details.safetyPractices, SafetyPractice.values.toSet());

      expect(details.openingHours, hasLength(7));
      final monday = details.hoursOn(DateTime.monday).single;
      expect(monday.opensAt, const Duration(hours: 7));
      expect(monday.closesAt, const Duration(hours: 19));
      final sunday = details.hoursOn(DateTime.sunday).single;
      expect(sunday.opensAt, const Duration(hours: 8));
      expect(sunday.closesAt, const Duration(hours: 12));

      expect(details.photos, hasLength(3));
      expect(
        details.photos.first.source,
        testPublicUrl('cafe_aconchego/photo_1.jpg'),
      );
      expect(details.photos.first.description, startsWith('Salão do café'));
    });

    test('lugar sem telefone e sem fotos', () {
      final details = establishmentDetailsFromJson(
        _firstRow(emporioDaTerraDetailsResponseJson),
        publicUrl: testPublicUrl,
      )!;

      expect(details.phone, isNull);
      expect(details.photos, isEmpty);
      expect(details.safetyPractices, {SafetyPractice.ingredientList});
    });

    test('ordena fotos por position e horários por dia e abertura', () {
      final row = _firstRow(cafeAconchegoDetailsResponseJson);
      row['establishment_photos'] = (row['establishment_photos'] as List)
          .reversed
          .toList();
      row['opening_hours'] = [
        {'weekday': 5, 'opens_at': '19:00:00', 'closes_at': '23:00:00'},
        {'weekday': 5, 'opens_at': '11:30:00', 'closes_at': '15:00:00'},
        {'weekday': 2, 'opens_at': '11:30:00', 'closes_at': '15:00:00'},
      ];

      final details = establishmentDetailsFromJson(
        row,
        publicUrl: testPublicUrl,
      )!;

      expect(details.photos.map((p) => p.source.split('/').last).toList(), [
        'photo_1.jpg',
        'photo_2.jpg',
        'photo_3.jpg',
      ]);
      expect(
        details.openingHours
            .map((h) => '${h.weekday} ${h.opensAt.inMinutes}')
            .toList(),
        ['2 690', '5 690', '5 1140'],
      );
    });

    test('devolve null quando o lugar não tem detalhes cadastrados', () {
      final row = _firstRow(cafeAconchegoDetailsResponseJson)
        ..['establishment_details'] = null;

      expect(
        establishmentDetailsFromJson(row, publicUrl: testPublicUrl),
        isNull,
      );
    });
  });

  group('durationFromPostgresTime', () {
    test('converte o formato time do Postgres', () {
      expect(durationFromPostgresTime('07:00:00'), const Duration(hours: 7));
      expect(
        durationFromPostgresTime('06:30:00'),
        const Duration(hours: 6, minutes: 30),
      );
      expect(
        durationFromPostgresTime('11:30'),
        const Duration(hours: 11, minutes: 30),
      );
      expect(
        durationFromPostgresTime('08:15:30.250'),
        const Duration(hours: 8, minutes: 15, seconds: 30),
      );
      // O Postgres aceita 24:00:00 como "meia-noite do fim do dia".
      expect(durationFromPostgresTime('24:00:00'), const Duration(hours: 24));
    });

    test('recusa textos que não são horários', () {
      expect(() => durationFromPostgresTime('7h'), throwsFormatException);
      expect(() => durationFromPostgresTime(''), throwsFormatException);
    });
  });
}
