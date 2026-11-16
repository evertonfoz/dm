import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/establishments/domain/entities/establishment_category.dart';
import 'package:celilac/features/explore/domain/explore_filters.dart';
import 'package:celilac/features/explore/domain/explore_query.dart';
import 'package:celilac/features/explore/domain/explore_sort.dart';
import 'package:celilac/features/profile/domain/entities/dietary_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/explore_catalog.dart';

List<String> _ids(
  ExploreFilters filters, {
  DietaryProfile profile = DietaryProfile.empty,
  Set<String> favoriteIds = const {},
}) {
  return [
    for (final e in applyExploreFilters(
      catalog,
      filters,
      profile: profile,
      favoriteIds: favoriteIds,
    ))
      e.id,
  ];
}

void main() {
  test('sem filtros, devolve tudo ordenado por distância', () {
    expect(_ids(ExploreFilters.initial), ['1', '2', '3', '4']);
  });

  test('não altera o catálogo original', () {
    final before = [...catalog];
    _ids(const ExploreFilters(sort: ExploreSort.name));
    expect(catalog, before);
  });

  group('busca', () {
    test('acha por nome sem depender de acento ou maiúscula', () {
      expect(_ids(const ExploreFilters(query: 'bistro')), ['3']);
      expect(_ids(const ExploreFilters(query: 'CAFÉ')), ['1']);
    });

    test('acha por bairro e por tipo', () {
      expect(_ids(const ExploreFilters(query: 'vila nova')), ['4']);
      expect(_ids(const ExploreFilters(query: 'padaria')), ['2']);
    });

    test('todas as palavras precisam aparecer', () {
      expect(_ids(const ExploreFilters(query: 'cafe centro')), ['1']);
      expect(_ids(const ExploreFilters(query: 'cafe vila')), isEmpty);
    });
  });

  group('categorias', () {
    test('uma ou mais categorias: vale qualquer uma delas', () {
      const filters = ExploreFilters(
        categories: {EstablishmentCategory.cafe, EstablishmentCategory.market},
      );
      expect(_ids(filters), ['1', '4']);
    });
  });

  group('opções alimentares', () {
    test('o lugar precisa oferecer todas as escolhidas', () {
      expect(
        _ids(const ExploreFilters(dietaryOptions: {DietaryOption.glutenFree})),
        ['1', '2', '3'],
      );
      expect(_ids(const ExploreFilters(dietaryOptions: both)), ['1', '3']);
    });
  });

  group('perfil e favoritos', () {
    const ana = DietaryProfile(name: 'Ana', restrictions: both);

    test('"atende ao meu perfil" usa as restrições do perfil', () {
      expect(
        _ids(const ExploreFilters(onlyMatchingProfile: true), profile: ana),
        ['1', '3'],
      );
    });

    test('sem perfil completo, o filtro de perfil não encontra nada', () {
      expect(_ids(const ExploreFilters(onlyMatchingProfile: true)), isEmpty);
    });

    test('"só favoritos" usa os ids salvos', () {
      expect(
        _ids(
          const ExploreFilters(onlyFavorites: true),
          favoriteIds: {'2', '4'},
        ),
        ['2', '4'],
      );
    });
  });

  test('os filtros se combinam (E entre grupos)', () {
    const filters = ExploreFilters(
      query: 'a',
      dietaryOptions: {DietaryOption.glutenFree},
      categories: {EstablishmentCategory.bakery, EstablishmentCategory.cafe},
    );
    expect(_ids(filters), ['1', '2']);
  });

  group('ordenação', () {
    test('por nota, da maior para a menor', () {
      expect(_ids(const ExploreFilters(sort: ExploreSort.rating)), [
        '1',
        '3',
        '2',
        '4',
      ]);
    });

    test('por nome, ignorando acento (Bistrô antes de Café)', () {
      expect(_ids(const ExploreFilters(sort: ExploreSort.name)), [
        '3',
        '1',
        '4',
        '2',
      ]);
    });
  });

  group('ExploreFilters', () {
    test('activeCount não conta a ordenação nem busca vazia', () {
      expect(const ExploreFilters(sort: ExploreSort.name).activeCount, 0);
      expect(const ExploreFilters(query: '  ').activeCount, 0);
      expect(
        const ExploreFilters(
          query: 'a',
          categories: {EstablishmentCategory.cafe},
          onlyFavorites: true,
        ).activeCount,
        3,
      );
    });

    test('cleared mantém a ordenação', () {
      final cleared = const ExploreFilters(
        query: 'a',
        sort: ExploreSort.rating,
      ).cleared();
      expect(cleared.query, '');
      expect(cleared.sort, ExploreSort.rating);
    });

    test('igualdade compara o conteúdo dos conjuntos', () {
      expect(
        const ExploreFilters(categories: {EstablishmentCategory.cafe}),
        const ExploreFilters(categories: {EstablishmentCategory.cafe}),
      );
      expect(
        const ExploreFilters(query: 'a') == const ExploreFilters(query: 'b'),
        isFalse,
      );
    });
  });
}
