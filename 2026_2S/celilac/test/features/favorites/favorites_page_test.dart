import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/establishments/domain/entities/establishment.dart';
import 'package:celilac/features/establishments/domain/entities/establishment_category.dart';
import 'package:celilac/features/establishments/presentation/pages/establishment_details_page.dart';
import 'package:celilac/features/favorites/presentation/pages/favorites_page.dart';
import 'package:celilac/features/profile/domain/entities/dietary_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_favorites_repository.dart';
import '../../support/memory_profile_repository.dart';
import '../../support/pump_app.dart';
import '../../support/stub_establishment_repository.dart';

const _bakery = Establishment(
  id: '2',
  name: 'Padaria Leve Grão',
  category: EstablishmentCategory.bakery,
  neighborhood: 'Jardim das Flores',
  distanceInKm: 1.2,
  rating: 4.6,
  dietaryOptions: {DietaryOption.glutenFree},
);

const _ana = DietaryProfile(
  name: 'Ana',
  restrictions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
);

const _bothCafe = Establishment(
  id: '3',
  name: 'Café Completo',
  category: EstablishmentCategory.cafe,
  neighborhood: 'Centro',
  distanceInKm: 0.4,
  rating: 4.9,
  dietaryOptions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
);

void main() {
  testWidgets('sem favoritos, explica como salvar e leva aos estabelecimentos', (
    tester,
  ) async {
    var explored = false;
    await pumpWithProfile(
      tester,
      FavoritesPage(onExploreTap: () => explored = true),
    );

    expect(
      find.textContaining('Você ainda não salvou nenhum estabelecimento.'),
      findsOne,
    );
    await tester.tap(find.text('Ver estabelecimentos'));
    expect(explored, isTrue);
  });

  testWidgets('lista os favoritos salvos e indica quem atende ao perfil', (
    tester,
  ) async {
    await pumpWithProfile(
      tester,
      const FavoritesPage(),
      repository: MemoryProfileRepository(stored: _ana),
      favoritesRepository: MemoryFavoritesRepository(
        stored: [_bothCafe, _bakery],
      ),
    );

    expect(find.text('2 lugares salvos'), findsOne);
    expect(find.text('Café Completo'), findsOne);
    expect(find.text('Padaria Leve Grão'), findsOne);
    expect(find.text('Atende ao seu perfil'), findsOne);
  });

  testWidgets('remover o único favorito volta para o estado vazio', (
    tester,
  ) async {
    final favoritesRepo = MemoryFavoritesRepository(stored: [testCafe]);
    await pumpWithProfile(
      tester,
      const FavoritesPage(),
      favoritesRepository: favoritesRepo,
    );

    expect(find.text('1 lugar salvo'), findsOne);

    await tester.tap(find.byTooltip('Remover Café Teste dos favoritos'));
    await tester.pumpAndSettle();

    expect(favoritesRepo.stored, isEmpty);
    expect(
      find.textContaining('Você ainda não salvou nenhum estabelecimento.'),
      findsOne,
    );
  });

  testWidgets('tocar em um favorito abre a tela de detalhes', (tester) async {
    final repo = StubEstablishmentRepository(
      detailsResults: [() async => testCafeDetails],
    );
    await pumpWithProfile(
      tester,
      FavoritesPage(repository: repo),
      favoritesRepository: MemoryFavoritesRepository(stored: [testCafe]),
    );

    await tester.tap(find.text('Café Teste'));
    await tester.pumpAndSettle();

    expect(find.byType(EstablishmentDetailsPage), findsOne);
    expect(find.text('Cuidados com contaminação cruzada'), findsOne);
  });

  testWidgets('não transborda com fonte a 200% em tela pequena', (
    tester,
  ) async {
    await pumpWithProfile(
      tester,
      const FavoritesPage(),
      repository: MemoryProfileRepository(stored: _ana),
      favoritesRepository: MemoryFavoritesRepository(
        stored: [testCafe, _bakery],
      ),
      size: const Size(320, 640),
      textScale: 2,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  for (final (state, stored) in [
    ('vazia', const <Establishment>[]),
    ('com itens', const [testCafe, _bakery]),
  ]) {
    testWidgets('segue as regras de acessibilidade ($state)', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWithProfile(
        tester,
        FavoritesPage(onExploreTap: () {}),
        repository: MemoryProfileRepository(stored: _ana),
        favoritesRepository: MemoryFavoritesRepository(stored: stored),
      );
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }
}
