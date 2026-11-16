import 'package:celilac/features/establishments/domain/entities/establishment.dart';
import 'package:celilac/features/explore/presentation/pages/explore_page.dart';
import 'package:celilac/features/profile/domain/entities/dietary_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/explore_catalog.dart';
import '../../support/memory_favorites_repository.dart';
import '../../support/memory_profile_repository.dart';
import '../../support/pump_app.dart';
import '../../support/stub_establishment_repository.dart';

Future<void> _pumpExplore(
  WidgetTester tester, {
  List<Future<List<Establishment>> Function()>? results,
  DietaryProfile profile = DietaryProfile.empty,
  MemoryFavoritesRepository? favorites,
  // Alta de propósito: a lista é lazy e só monta o que cabe na tela.
  Size size = const Size(360, 2400),
  double textScale = 1,
}) async {
  final repository = StubEstablishmentRepository(
    nearbyResults: results ?? [() async => catalog],
  );
  await pumpWithProfile(
    tester,
    ExplorePage(repository: repository),
    repository: MemoryProfileRepository(stored: profile),
    favoritesRepository: favorites,
    exploreRepository: repository,
    size: size,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}

Finder _inResults(String text) =>
    find.descendant(of: find.byType(Card), matching: find.text(text));

void main() {
  testWidgets('mostra o carregamento e depois todos os lugares', (
    tester,
  ) async {
    await _pumpExplore(tester);

    expect(find.text('4 lugares encontrados'), findsOne);
    expect(find.byType(Card), findsNWidgets(4));
  });

  testWidgets('erro de carregamento oferece nova tentativa', (tester) async {
    await _pumpExplore(
      tester,
      results: [() async => throw Exception('sem rede'), () async => catalog],
    );

    expect(
      find.text('Não foi possível carregar os estabelecimentos.'),
      findsOne,
    );
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.byType(Card), findsNWidgets(4));
  });

  testWidgets('a busca só filtra depois de a pessoa parar de digitar', (
    tester,
  ) async {
    await _pumpExplore(tester);

    await tester.enterText(find.byType(TextField), 'bistro');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(Card), findsNWidgets(4)); // ainda esperando

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Card), findsOne);
    expect(_inResults('Bistrô Bem-Estar'), findsOne);
    expect(find.text('1 lugar encontrado'), findsOne);
  });

  testWidgets('botão de limpar esvazia o campo e volta a lista', (
    tester,
  ) async {
    await _pumpExplore(tester);
    await tester.enterText(find.byType(TextField), 'bistro');
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byTooltip('Limpar busca'));
    await tester.pump();

    expect(find.byType(Card), findsNWidgets(4));
    expect(find.byTooltip('Limpar busca'), findsNothing);
  });

  testWidgets('chips de categoria e de opção alimentar se combinam', (
    tester,
  ) async {
    await _pumpExplore(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Sem glúten'));
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsNWidgets(3));

    await tester.tap(find.widgetWithText(FilterChip, 'Café'));
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsOne);
    expect(_inResults('Café Aconchego'), findsOne);
  });

  testWidgets('sem resultado, explica e "Limpar filtros" recupera a lista', (
    tester,
  ) async {
    await _pumpExplore(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Mercado'));
    await tester.tap(find.widgetWithText(FilterChip, 'Sem glúten'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum lugar combina com esses filtros.'), findsOne);
    expect(find.text('Nenhum lugar encontrado'), findsOne);

    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();

    expect(find.byType(Card), findsNWidgets(4));
    final chip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Mercado'),
    );
    expect(chip.selected, isFalse);
  });

  testWidgets('a ordenação reordena os cartões', (tester) async {
    await _pumpExplore(tester);

    double top(String name) => tester.getTopLeft(_inResults(name)).dy;
    expect(top('Café Aconchego') < top('Empório Natural'), isTrue);

    await tester.tap(find.text('Mais perto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nome (A–Z)').last);
    await tester.pumpAndSettle();

    expect(top('Bistrô Bem-Estar') < top('Café Aconchego'), isTrue);
  });

  testWidgets('"Atende ao meu perfil" só aparece para quem tem perfil', (
    tester,
  ) async {
    await _pumpExplore(tester);
    expect(find.text('Atende ao meu perfil'), findsNothing);
  });

  testWidgets('com perfil completo, o chip filtra pelas restrições', (
    tester,
  ) async {
    await _pumpExplore(
      tester,
      profile: const DietaryProfile(name: 'Ana', restrictions: both),
    );

    await tester.tap(find.widgetWithText(FilterChip, 'Atende ao meu perfil'));
    await tester.pumpAndSettle();

    expect(find.byType(Card), findsNWidgets(2));
  });

  testWidgets('"Só favoritos" usa os favoritos salvos e reage ao coração', (
    tester,
  ) async {
    await _pumpExplore(
      tester,
      favorites: MemoryFavoritesRepository(stored: [padariaLeve]),
    );

    await tester.tap(find.widgetWithText(FilterChip, 'Só favoritos'));
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsOne);
    expect(_inResults('Padaria Leve Grão'), findsOne);

    // Desfavoritar com o filtro ligado tira o cartão da lista.
    await tester.tap(find.byTooltip('Remover Padaria Leve Grão dos favoritos'));
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsNothing);
    expect(find.text('Nenhum lugar combina com esses filtros.'), findsOne);
  });

  testWidgets('favoritar um cartão troca o coração', (tester) async {
    await _pumpExplore(tester);

    await tester.tap(find.byTooltip('Salvar Café Aconchego nos favoritos'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Remover Café Aconchego dos favoritos'), findsOne);
  });

  testWidgets('cumpre as diretrizes de acessibilidade de toque e rótulo', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pumpExplore(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('sem overflow em 320×640 com fonte a 200%', (tester) async {
    await _pumpExplore(
      tester,
      profile: const DietaryProfile(name: 'Ana', restrictions: both),
      size: const Size(320, 640),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
  });
}
