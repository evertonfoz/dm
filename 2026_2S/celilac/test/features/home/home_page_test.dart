import 'package:celilac/app/theme/app_theme.dart';
import 'package:celilac/features/establishments/domain/repositories/establishment_repository.dart';
import 'package:celilac/features/home/presentation/pages/home_page.dart';
import 'package:celilac/features/home/presentation/widgets/nearby_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/stub_establishment_repository.dart';

Future<void> _pumpHome(WidgetTester tester, EstablishmentRepository repo) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: HomePage(repository: repo)),
    ),
  );
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

  testWidgets('avisa que o perfil ainda não está disponível', (tester) async {
    final repo = StubEstablishmentRepository(
      nearbyResults: [
        () async => [testCafe],
      ],
    );
    await _pumpHome(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Completar perfil'));
    await tester.pump();

    expect(
      find.text('O perfil alimentar estará disponível em breve.'),
      findsOne,
    );
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

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Cuidados com contaminação cruzada'), findsNothing);
    expect(find.text('Completar perfil'), findsOne);
    expect(repo.nearbyCalls, 1);
  });

  testWidgets('segue as regras de acessibilidade', (tester) async {
    final handle = tester.ensureSemantics();
    final repo = StubEstablishmentRepository(
      nearbyResults: [
        () async => [testCafe],
      ],
    );
    await _pumpHome(tester, repo);
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
