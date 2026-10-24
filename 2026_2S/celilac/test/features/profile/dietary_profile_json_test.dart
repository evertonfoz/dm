import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/profile/data/dietary_profile_json.dart';
import 'package:celilac/features/profile/domain/entities/dietary_profile.dart';
import 'package:flutter_test/flutter_test.dart';

const _ana = DietaryProfile(
  name: 'Ana',
  restrictions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
  needsCrossContactCare: true,
);

void main() {
  test('toJson grava enums pelo nome e chaves em snake_case', () {
    expect(_ana.toJson(), {
      'name': 'Ana',
      'restrictions': ['glutenFree', 'lactoseFree'],
      'needs_cross_contact_care': true,
    });
  });

  test('ida e volta devolve um perfil igual', () {
    expect(dietaryProfileFromJson(_ana.toJson()), _ana);
    expect(
      dietaryProfileFromJson(DietaryProfile.empty.toJson()),
      DietaryProfile.empty,
    );
  });

  test('lê o formato gravado pela versão 1 do app', () {
    // Fixo de propósito: se este teste quebrar, perfis de usuários reais
    // deixariam de ser lidos depois de uma atualização.
    const version1 = {
      'schema_version': 1,
      'name': 'Ana',
      'restrictions': ['glutenFree'],
      'needs_cross_contact_care': true,
    };

    expect(
      dietaryProfileFromJson(version1),
      const DietaryProfile(
        name: 'Ana',
        restrictions: {DietaryOption.glutenFree},
        needsCrossContactCare: true,
      ),
    );
  });

  test('ignora restrições desconhecidas', () {
    final profile = dietaryProfileFromJson({
      'restrictions': ['glutenFree', 'eggFree', 42, null],
    });

    expect(profile.restrictions, {DietaryOption.glutenFree});
  });

  test('campos ausentes usam o padrão', () {
    expect(dietaryProfileFromJson({}), DietaryProfile.empty);
  });

  test('tipos errados usam o padrão', () {
    final profile = dietaryProfileFromJson({
      'name': 7,
      'restrictions': 'glutenFree',
      'needs_cross_contact_care': 'sim',
    });

    expect(profile, DietaryProfile.empty);
  });

  test('nome só com espaços vira nulo', () {
    expect(dietaryProfileFromJson({'name': '   '}).name, isNull);
  });
}
