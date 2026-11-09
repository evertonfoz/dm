import 'package:celilac/features/establishments/domain/entities/establishment_details.dart';
import 'package:celilac/features/establishments/domain/repositories/establishment_repository.dart';
import 'package:celilac/features/establishments/presentation/pages/establishment_details_page.dart';
import 'package:celilac/features/establishments/presentation/widgets/details_loading.dart';
import 'package:celilac/features/establishments/presentation/widgets/photo_carousel.dart';
import 'package:celilac/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_favorites_repository.dart';
import '../../support/pump_app.dart';
import '../../support/stub_establishment_repository.dart';

Future<void> _pumpDetails(
  WidgetTester tester,
  EstablishmentRepository repo, {
  FavoritesRepository? favoritesRepository,
  Size size = const Size(360, 800),
  double textScale = 1,
}) {
  return pumpWithProfile(
    tester,
    EstablishmentDetailsPage(establishment: testCafe, repository: repo),
    favoritesRepository: favoritesRepository,
    size: size,
    textScale: textScale,
  );
}

void main() {
  testWidgets('mostra o resumo na hora e os detalhes depois de carregar', (
    tester,
  ) async {
    final repo = StubEstablishmentRepository(
      detailsResults: [() async => testCafeDetails],
    );
    await _pumpDetails(tester, repo);

    expect(find.text('Café Teste'), findsOne);
    expect(find.byType(DetailsLoading), findsOne);

    await tester.pumpAndSettle();

    expect(find.byType(DetailsLoading), findsNothing);
    expect(find.textContaining('Aberto agora'), findsOne);
    expect(find.text('Utensílios exclusivos para itens sem glúten'), findsOne);
    expect(find.text('Ligar'), findsOne);
  });

  testWidgets('avisa quando o estabelecimento não é encontrado', (
    tester,
  ) async {
    final repo = StubEstablishmentRepository(
      detailsResults: [() async => null],
    );
    await _pumpDetails(tester, repo);
    await tester.pumpAndSettle();

    expect(
      find.text('As informações deste lugar não estão mais disponíveis.'),
      findsOne,
    );
    expect(find.text('Voltar'), findsOne);
  });

  testWidgets('mostra erro e permite tentar novamente', (tester) async {
    final repo = StubEstablishmentRepository(
      detailsResults: [
        () async => throw Exception('sem conexão'),
        () async => testCafeDetails,
      ],
    );
    await _pumpDetails(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(repo.detailsCalls, 2);
    expect(find.text('Um café de teste.'), findsOne);
  });

  testWidgets('esconde o botão de ligar quando não há telefone', (
    tester,
  ) async {
    final withoutPhone = EstablishmentDetails(
      establishmentId: testCafeDetails.establishmentId,
      description: testCafeDetails.description,
      address: testCafeDetails.address,
      openingHours: testCafeDetails.openingHours,
      safetyPractices: testCafeDetails.safetyPractices,
    );
    final repo = StubEstablishmentRepository(
      detailsResults: [() async => withoutPhone],
    );
    await _pumpDetails(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('Como chegar'), findsOne);
    expect(find.text('Ligar'), findsNothing);
  });

  testWidgets('mostra as fotos com descrição para o leitor de tela', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = StubEstablishmentRepository(
      detailsResults: [() async => testCafeDetails],
    );
    await _pumpDetails(tester, repo);
    await tester.pumpAndSettle();

    expect(find.byType(PhotoCarousel), findsOne);
    expect(find.bySemanticsLabel('Salão de teste'), findsOne);
    handle.dispose();
  });

  testWidgets('esconde o carrossel quando não há fotos', (tester) async {
    final withoutPhotos = EstablishmentDetails(
      establishmentId: testCafeDetails.establishmentId,
      description: testCafeDetails.description,
      address: testCafeDetails.address,
      openingHours: testCafeDetails.openingHours,
      safetyPractices: testCafeDetails.safetyPractices,
    );
    final repo = StubEstablishmentRepository(
      detailsResults: [() async => withoutPhotos],
    );
    await _pumpDetails(tester, repo);
    await tester.pumpAndSettle();

    expect(find.byType(PhotoCarousel), findsNothing);
    expect(find.text('Um café de teste.'), findsOne);
  });

  testWidgets('salva e remove dos favoritos pela barra superior', (
    tester,
  ) async {
    final favoritesRepo = MemoryFavoritesRepository();
    final repo = StubEstablishmentRepository(
      detailsResults: [() async => testCafeDetails],
    );
    await _pumpDetails(tester, repo, favoritesRepository: favoritesRepo);
    await tester.pumpAndSettle();

    final saveButton = find.byTooltip('Salvar Café Teste nos favoritos');
    expect(saveButton, findsOne);

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(favoritesRepo.stored, [testCafe]);
    final removeButton = find.byTooltip('Remover Café Teste dos favoritos');
    expect(removeButton, findsOne);

    await tester.tap(removeButton);
    await tester.pumpAndSettle();

    expect(favoritesRepo.stored, isEmpty);
  });

  testWidgets('mostra aviso se falhar ao atualizar favorito no detalhe', (
    tester,
  ) async {
    final favoritesRepo = MemoryFavoritesRepository(failOnChange: true);
    final repo = StubEstablishmentRepository(
      detailsResults: [() async => testCafeDetails],
    );
    await _pumpDetails(tester, repo, favoritesRepository: favoritesRepo);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Salvar Café Teste nos favoritos'));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível atualizar os favoritos.'),
      findsOne,
    );
  });

  testWidgets('não transborda com fonte a 200% em tela pequena', (
    tester,
  ) async {
    final repo = StubEstablishmentRepository(
      detailsResults: [() async => testCafeDetails],
    );
    await _pumpDetails(tester, repo, size: const Size(320, 640), textScale: 2);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('segue as regras de acessibilidade', (tester) async {
    final handle = tester.ensureSemantics();
    final repo = StubEstablishmentRepository(
      detailsResults: [() async => testCafeDetails],
    );
    await _pumpDetails(tester, repo);
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
