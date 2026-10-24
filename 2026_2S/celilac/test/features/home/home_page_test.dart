import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/establishments/domain/entities/establishment.dart';
import 'package:celilac/features/establishments/domain/entities/establishment_category.dart';
import 'package:celilac/features/establishments/domain/repositories/establishment_repository.dart';
import 'package:celilac/features/home/presentation/pages/home_page.dart';
import 'package:celilac/features/home/presentation/widgets/nearby_loading.dart';
import 'package:celilac/features/profile/domain/entities/dietary_profile.dart';
import 'package:celilac/features/profile/presentation/pages/profile_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_profile_repository.dart';
import '../../support/pump_app.dart';
import '../../support/stub_establishment_repository.dart';

Future<void> _pumpHome(
  WidgetTester tester,
  EstablishmentRepository repo, {
  DietaryProfile profile = DietaryProfile.empty,
}) {
  return pumpWithProfile(
    tester,
    Scaffold(body: HomePage(repository: repo)),
    repository: MemoryProfileRepository(stored: profile),
  );
}

// Mais longe que o testCafe (350 m) e só sem lactose.
const _lactoseShop = Establishment(
  id: '2',
  name: 'Empório Teste',
  category: EstablishmentCategory.market,
  neighborhood: 'Zona 7',
  distanceInKm: 1.2,
  rating: 4.5,
  dietaryOptions: {DietaryOption.lactoseFree},
);

const _ana = DietaryProfile(
  name: 'Ana',
  restrictions: {DietaryOption.lactoseFree},
);

final _matchBadge = find.text('Atende ao seu perfil');

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra carregamento e depois os estabelecimentos', (
    tester,
  ) async {
    final repo = StubEstablishmentRepository(
      nearbyResults: [
        () async => [testCafe],
      ],
    );
    await _pumpHome(tester, repo);

    expect(find.byType(NearbyLoading), findsOne);

    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Café Teste'));
    await tester.pumpAndSettle();

    expect(find.text('Café Teste'), findsOne);
    expect(find.text('Café · Centro · 350 m'), findsOne);
    expect(find.text('Sem glúten'), findsOne);
  });

  testWidgets('mostra mensagem quando não há estabelecimentos', (tester) async {
    final repo = StubEstablishmentRepository(nearbyResults: [() async => []]);
    await _pumpHome(tester, repo);
    await tester.pumpAndSettle();

    final message = find.text('Ainda não encontramos opções perto de você.');
    await tester.ensureVisible(message);
    await tester.pumpAndSettle();
    expect(message, findsOne);
  });

  testWidgets('mostra erro e permite tentar novamente', (tester) async {
    final repo = StubEstablishmentRepository(
      nearbyResults: [
        () async => throw Exception('sem conexão'),
        () async => [testCafe],
      ],
    );
    await _pumpHome(tester, repo);
    await tester.pumpAndSettle();

    final retry = find.text('Tentar novamente');
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(repo.nearbyCalls, 2);
    expect(find.text('Café Teste'), findsOne);
  });

  testWidgets('não busca de novo quando a tela é reconstruída', (tester) async {
    final repo = StubEstablishmentRepository(
      nearbyResults: [
        () async => [testCafe],
      ],
    );
    await _pumpHome(tester, repo);
    await tester.pumpAndSettle();

    // Bombear a mesma árvore de novo força um novo build() da HomePage.
    await _pumpHome(tester, repo);
    await tester.pumpAndSettle();

    expect(repo.nearbyCalls, 1);
  });

  testWidgets('"Completar perfil" abre o formulário', (tester) async {
    final repo = StubEstablishmentRepository(
      nearbyResults: [
        () async => [testCafe],
      ],
    );
    await _pumpHome(tester, repo);
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('Completar perfil'));

    expect(find.byType(ProfileFormPage), findsOne);
  });

  testWidgets('perfil completo: nome na saudação e sem o cartão', (
    tester,
  ) async {
    final repo = StubEstablishmentRepository(
      nearbyResults: [
        () async => [testCafe],
      ],
    );
    await _pumpHome(tester, repo, profile: _ana);
    await tester.pumpAndSettle();

    expect(find.textContaining(', Ana!'), findsOne);
    expect(find.text('Completar perfil'), findsNothing);
    expect(find.text('Primeiro, os que atendem ao seu perfil.'), findsOne);
  });

  testWidgets('sem perfil: ordem por distância e nenhum selo', (tester) async {
    final repo = StubEstablishmentRepository(
      nearbyResults: [
        () async => [testCafe, _lactoseShop],
      ],
    );
    await _pumpHome(tester, repo);
    await tester.pumpAndSettle();
    // A lista é construída sob demanda: rolar até o último cartão existir.
    await tester.scrollUntilVisible(find.text('Empório Teste'), 200);

    expect(_top(tester, 'Café Teste'), lessThan(_top(tester, 'Empório Teste')));
    expect(_matchBadge, findsNothing);
    expect(find.text('Primeiro, os que atendem ao seu perfil.'), findsNothing);
  });

  testWidgets('com perfil: quem atende vem primeiro, com o selo', (
    tester,
  ) async {
    final repo = StubEstablishmentRepository(
      nearbyResults: [
        () async => [testCafe, _lactoseShop],
      ],
    );
    await _pumpHome(tester, repo, profile: _ana);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Café Teste'), 200);

    expect(_top(tester, 'Empório Teste'), lessThan(_top(tester, 'Café Teste')));
    expect(_matchBadge, findsOne);
  });

  testWidgets('salvar o perfil reordena a lista sem buscar de novo', (
    tester,
  ) async {
    final repo = StubEstablishmentRepository(
      nearbyResults: [
        () async => [testCafe, _lactoseShop],
      ],
    );
    await _pumpHome(tester, repo);
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('Completar perfil'));
    await _tapVisible(tester, find.widgetWithText(CheckboxListTile, 'Lactose'));
    await _tapVisible(tester, find.text('Salvar perfil'));

    expect(find.byType(ProfileFormPage), findsNothing);
    expect(find.text('Completar perfil'), findsNothing);
    await tester.scrollUntilVisible(find.text('Café Teste'), 200);
    expect(_top(tester, 'Empório Teste'), lessThan(_top(tester, 'Café Teste')));
    expect(_matchBadge, findsOne);
    expect(repo.nearbyCalls, 1);
  });

  testWidgets('abre o detalhe ao tocar no cartão e volta para a Home', (
    tester,
  ) async {
    final repo = StubEstablishmentRepository(
      nearbyResults: [
        () async => [testCafe],
      ],
      detailsResults: [() async => testCafeDetails],
    );
    await _pumpHome(tester, repo);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Café Teste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Café Teste'));
    await tester.pumpAndSettle();

    expect(find.text('Cuidados com contaminação cruzada'), findsOne);
    expect(repo.detailsCalls, 1);

    // O app está em português: tester.pageBack() procura a dica "Back".
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('Cuidados com contaminação cruzada'), findsNothing);
    expect(find.text('Completar perfil'), findsOne);
    expect(repo.nearbyCalls, 1);
  });

  testWidgets('não transborda com fonte a 200% em tela pequena', (
    tester,
  ) async {
    final repo = StubEstablishmentRepository(
      nearbyResults: [
        () async => [testCafe, _lactoseShop],
      ],
    );
    await pumpWithProfile(
      tester,
      Scaffold(body: HomePage(repository: repo)),
      repository: MemoryProfileRepository(stored: _ana),
      size: const Size(320, 640),
      textScale: 2,
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Café Teste'), 200);

    expect(tester.takeException(), isNull);
  });

  for (final (state, profile) in [
    ('sem perfil', DietaryProfile.empty),
    ('com perfil', _ana),
  ]) {
    testWidgets('segue as regras de acessibilidade ($state)', (tester) async {
      final handle = tester.ensureSemantics();
      final repo = StubEstablishmentRepository(
        nearbyResults: [
          () async => [testCafe, _lactoseShop],
        ],
      );
      await _pumpHome(tester, repo, profile: profile);
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }
}
