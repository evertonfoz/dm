import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/profile/domain/entities/dietary_profile.dart';
import 'package:flutter_test/flutter_test.dart';

const _ana = DietaryProfile(
  name: 'Ana',
  restrictions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
  needsCrossContactCare: true,
);

void main() {
  group('isComplete', () {
    test('perfil vazio não está completo', () {
      expect(DietaryProfile.empty.isComplete, isFalse);
    });

    test('nome sem restrições não está completo', () {
      expect(const DietaryProfile(name: 'Ana').isComplete, isFalse);
    });

    test('uma restrição basta', () {
      const profile = DietaryProfile(restrictions: {DietaryOption.lactoseFree});
      expect(profile.isComplete, isTrue);
    });
  });

  group('igualdade por valor', () {
    test('mesmos valores, objetos diferentes: iguais', () {
      // Sets criados em tempo de execução, em ordens diferentes.
      final a = DietaryProfile(
        name: 'Ana',
        restrictions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
      );
      final b = DietaryProfile(
        name: 'Ana',
        restrictions: {DietaryOption.lactoseFree, DietaryOption.glutenFree},
      );

      expect(identical(a, b), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('qualquer campo diferente: diferentes', () {
      expect(_ana == _ana.copyWith(name: 'Bia'), isFalse);
      expect(
        _ana == _ana.copyWith(restrictions: {DietaryOption.glutenFree}),
        isFalse,
      );
      expect(_ana == _ana.copyWith(needsCrossContactCare: false), isFalse);
    });

    test('um conjunto contido no outro não é igual', () {
      final fewer = _ana.copyWith(restrictions: {DietaryOption.glutenFree});
      expect(fewer == _ana, isFalse);
      expect(_ana == fewer, isFalse);
    });
  });

  group('copyWith', () {
    test('sem argumentos devolve um perfil igual', () {
      expect(_ana.copyWith(), _ana);
    });

    test('muda só o que foi pedido', () {
      final changed = _ana.copyWith(needsCrossContactCare: false);

      expect(changed.name, 'Ana');
      expect(changed.restrictions, _ana.restrictions);
      expect(changed.needsCrossContactCare, isFalse);
    });

    test('clearName apaga o nome', () {
      expect(_ana.copyWith(clearName: true).name, isNull);
    });

    test('name: null mantém o nome', () {
      expect(_ana.copyWith(name: null).name, 'Ana');
    });
  });
}
