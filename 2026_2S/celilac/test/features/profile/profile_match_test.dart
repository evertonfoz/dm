import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/establishments/domain/entities/establishment.dart';
import 'package:celilac/features/establishments/domain/entities/establishment_category.dart';
import 'package:celilac/features/profile/domain/entities/dietary_profile.dart';
import 'package:celilac/features/profile/domain/profile_match.dart';
import 'package:flutter_test/flutter_test.dart';

Establishment _place(String id, Set<DietaryOption> options) {
  return Establishment(
    id: id,
    name: 'Lugar $id',
    category: EstablishmentCategory.cafe,
    neighborhood: 'Centro',
    distanceInKm: double.parse(id),
    rating: 4.5,
    dietaryOptions: options,
  );
}

// Já em ordem de distância, como vem do repositório.
final _glutenOnly = _place('1', {DietaryOption.glutenFree});
final _lactoseOnly = _place('2', {DietaryOption.lactoseFree});
final _both = _place('3', {
  DietaryOption.glutenFree,
  DietaryOption.lactoseFree,
});
final _none = _place('4', {});
final _nearby = [_glutenOnly, _lactoseOnly, _both, _none];

const _gluten = DietaryProfile(restrictions: {DietaryOption.glutenFree});
const _glutenAndLactose = DietaryProfile(
  restrictions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
);

void main() {
  group('meetsProfile', () {
    test('atende quando oferece tudo o que o perfil evita', () {
      expect(meetsProfile(_glutenOnly, _gluten), isTrue);
      expect(meetsProfile(_both, _gluten), isTrue);
      expect(meetsProfile(_both, _glutenAndLactose), isTrue);
    });

    test('não atende quando falta uma das opções', () {
      expect(meetsProfile(_glutenOnly, _glutenAndLactose), isFalse);
      expect(meetsProfile(_lactoseOnly, _gluten), isFalse);
      expect(meetsProfile(_none, _gluten), isFalse);
    });

    test('perfil vazio: ninguém atende', () {
      for (final place in _nearby) {
        expect(meetsProfile(place, DietaryProfile.empty), isFalse);
      }
    });
  });

  group('sortByProfile', () {
    test('perfil vazio mantém a ordem', () {
      expect(sortByProfile(_nearby, DietaryProfile.empty), _nearby);
    });

    test('quem atende vem primeiro, cada grupo na ordem de distância', () {
      expect(sortByProfile(_nearby, _gluten), [
        _glutenOnly,
        _both,
        _lactoseOnly,
        _none,
      ]);
      expect(sortByProfile(_nearby, _glutenAndLactose), [
        _both,
        _glutenOnly,
        _lactoseOnly,
        _none,
      ]);
    });

    test('não altera a lista recebida', () {
      final original = List.of(_nearby);
      final sorted = sortByProfile(_nearby, _glutenAndLactose);

      expect(_nearby, original);
      expect(identical(sorted, _nearby), isFalse);
    });

    test('lista vazia devolve lista vazia', () {
      expect(sortByProfile(const [], _gluten), isEmpty);
    });
  });
}
