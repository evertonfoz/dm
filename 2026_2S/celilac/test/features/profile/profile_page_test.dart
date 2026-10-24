import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/profile/domain/entities/dietary_profile.dart';
import 'package:celilac/features/profile/presentation/pages/profile_form_page.dart';
import 'package:celilac/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_profile_repository.dart';
import '../../support/pump_app.dart';

const _ana = DietaryProfile(
  name: 'Ana',
  restrictions: {DietaryOption.lactoseFree, DietaryOption.glutenFree},
  needsCrossContactCare: true,
);

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('perfil vazio convida a completar', (tester) async {
    await pumpWithProfile(
      tester,
      const ProfilePage(),
      repository: MemoryProfileRepository(),
    );

    expect(
      find.text('Conte o que você precisa evitar para personalizar o CeliLac.'),
      findsOne,
    );
    expect(find.text('Completar perfil'), findsOne);
    expect(find.text('Editar perfil'), findsNothing);
  });

  testWidgets('perfil preenchido mostra o resumo', (tester) async {
    await pumpWithProfile(
      tester,
      const ProfilePage(),
      repository: MemoryProfileRepository(stored: _ana),
    );

    expect(find.text('Ana'), findsOne);
    expect(find.text('Sem glúten'), findsOne);
    expect(find.text('Sem lactose'), findsOne);
    expect(find.text('Com cuidado contra contaminação cruzada'), findsOne);
    expect(find.text('Editar perfil'), findsOne);
  });

  testWidgets('sem nome e sem cuidado extra, o resumo se adapta', (
    tester,
  ) async {
    await pumpWithProfile(
      tester,
      const ProfilePage(),
      repository: MemoryProfileRepository(
        stored: const DietaryProfile(restrictions: {DietaryOption.glutenFree}),
      ),
    );

    expect(find.text('Seu perfil'), findsOne);
    expect(find.text('Sem lactose'), findsNothing);
    expect(find.text('Com cuidado contra contaminação cruzada'), findsNothing);
  });

  testWidgets('completar o perfil troca o convite pelo resumo', (tester) async {
    final repository = MemoryProfileRepository();
    await pumpWithProfile(tester, const ProfilePage(), repository: repository);

    await _tapVisible(tester, find.text('Completar perfil'));
    expect(find.byType(ProfileFormPage), findsOne);

    await _tapVisible(tester, find.widgetWithText(CheckboxListTile, 'Glúten'));
    await _tapVisible(tester, find.text('Salvar perfil'));

    expect(find.byType(ProfileFormPage), findsNothing);
    expect(find.text('Sem glúten'), findsOne);
    expect(find.text('Editar perfil'), findsOne);
    // A aba se atualizou pelo ProfileScope, sem ler o repositório de novo.
    expect(repository.loadCalls, 1);
  });

  testWidgets('editar atualiza o resumo', (tester) async {
    await pumpWithProfile(
      tester,
      const ProfilePage(),
      repository: MemoryProfileRepository(stored: _ana),
    );

    await _tapVisible(tester, find.text('Editar perfil'));
    await tester.enterText(find.byType(TextFormField), 'Bia');
    await _tapVisible(tester, find.text('Salvar perfil'));

    expect(find.text('Bia'), findsOne);
    expect(find.text('Ana'), findsNothing);
  });

  testWidgets('não transborda com fonte a 200% em tela pequena', (
    tester,
  ) async {
    await pumpWithProfile(
      tester,
      const ProfilePage(),
      repository: MemoryProfileRepository(stored: _ana),
      size: const Size(320, 640),
      textScale: 2,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  for (final (state, profile) in [
    ('vazio', DietaryProfile.empty),
    ('preenchido', _ana),
  ]) {
    testWidgets('segue as regras de acessibilidade (perfil $state)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpWithProfile(
        tester,
        const ProfilePage(),
        repository: MemoryProfileRepository(stored: profile),
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
