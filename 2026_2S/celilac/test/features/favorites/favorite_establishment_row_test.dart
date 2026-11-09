import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/establishments/domain/entities/establishment.dart';
import 'package:celilac/features/establishments/domain/entities/establishment_category.dart';
import 'package:celilac/features/favorites/data/favorite_establishment_row.dart';
import 'package:flutter_test/flutter_test.dart';

const _cafe = Establishment(
  id: '1',
  name: 'Café Aconchego',
  category: EstablishmentCategory.cafe,
  neighborhood: 'Centro',
  distanceInKm: 0.35,
  rating: 4.8,
  dietaryOptions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
  logoSource: 'assets/images/establishments/cafe_aconchego_logo.png',
);

void main() {
  test('converte ida e volta preservando todos os campos', () {
    final savedAt = DateTime.utc(2026, 11, 4, 12, 30);
    final row = _cafe.toRow(savedAt: savedAt);

    expect(row['id'], '1');
    expect(row['category'], 'cafe');
    expect(row['dietary_options'], 'glutenFree,lactoseFree');
    expect(row['saved_at'], savedAt.millisecondsSinceEpoch);

    final restored = establishmentFromRow(row);
    expect(restored.id, _cafe.id);
    expect(restored.name, _cafe.name);
    expect(restored.category, _cafe.category);
    expect(restored.neighborhood, _cafe.neighborhood);
    expect(restored.distanceInKm, _cafe.distanceInKm);
    expect(restored.rating, _cafe.rating);
    expect(restored.dietaryOptions, _cafe.dietaryOptions);
    expect(restored.logoSource, _cafe.logoSource);
  });

  test('aceita logo nulo e números inteiros vindos de colunas REAL', () {
    final restored = establishmentFromRow({
      'id': '2',
      'name': 'Padaria Leve Grão',
      'category': 'bakery',
      'neighborhood': 'Jardim',
      'distance_in_km': 2,
      'rating': 5,
      'dietary_options': 'glutenFree',
      'logo_source': null,
      'saved_at': 1000,
    });

    expect(restored.distanceInKm, 2.0);
    expect(restored.rating, 5.0);
    expect(restored.logoSource, isNull);
    expect(restored.dietaryOptions, {DietaryOption.glutenFree});
  });

  test('ignora opções desconhecidas e usa categoria padrão se necessário', () {
    final restored = establishmentFromRow({
      'id': '3',
      'name': 'Empório',
      'category': 'categoria_futura',
      'neighborhood': 'Centro',
      'distance_in_km': 1.1,
      'rating': 4.5,
      'dietary_options': 'glutenFree,opcao_antiga',
      'logo_source': null,
      'saved_at': 1000,
    });

    expect(restored.category, EstablishmentCategory.restaurant);
    expect(restored.dietaryOptions, {DietaryOption.glutenFree});
  });
}
