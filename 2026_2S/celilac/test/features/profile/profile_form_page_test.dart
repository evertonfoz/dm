import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/profile/domain/entities/dietary_profile.dart';
import 'package:celilac/features/profile/presentation/pages/profile_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_profile_repository.dart';
import '../../support/pump_app.dart';

const _ana = DietaryProfile(
  name: 'Ana',
  restrictions: {DietaryOption.glutenFree},
  needsCrossContactCare: true,
);

final _gluten = find.widgetWithText(CheckboxListTile, 'Glúten');
final _lactose = find.widgetWithText(CheckboxListTile, 'Lactose');
final _nameField = find.byType(TextFormField);
final _saveButton = find.widgetWithText(FilledButton, 'Salvar perfil');

Future<void> _openForm(
  WidgetTester tester, {
  required MemoryProfileRepository repository,
}) async {
  await pumpWithProfile(
    tester,
    const PushButtonHost(page: ProfileFormPage()),
    repository: repository,
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

bool _isEnabled(WidgetTester tester, Finder button) =>
    tester.widget<FilledButton>(button).onPressed != null;

SwitchListTile _crossContact(WidgetTester tester) =>
    tester.widget<SwitchListTile>(find.byType(SwitchListTile));

// O app está em português: tester.pageBack() procura a dica "Back".
Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Voltar'));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('abre preenchido com o perfil atual', (tester) async {
    await _openForm(tester, repository: MemoryProfileRepository(stored: _ana));

    expect(find.widgetWithText(TextFormField, 'Ana'), findsOne);
    expect(tester.widget<CheckboxListTile>(_gluten).value, isTrue);
    expect(tester.widget<CheckboxListTile>(_lactose).value, isFalse);
    expect(_crossContact(tester).value, isTrue);
  });

  testWidgets('"Salvar" só fica ativo quando algo muda', (tester) async {
    await _openForm(tester, repository: MemoryProfileRepository(stored: _ana));
    expect(_isEnabled(tester, _saveButton), isFalse);

    await _tapVisible(tester, _lactose);
    expect(_isEnabled(tester, _saveButton), isTrue);

    // Desfazer a mudança volta ao perfil original.
    await _tapVisible(tester, _lactose);
    expect(_isEnabled(tester, _saveButton), isFalse);
  });

  testWidgets('exige pelo menos uma restrição', (tester) async {
    final repository = MemoryProfileRepository();
    await _openForm(tester, repository: repository);

    await tester.enterText(_nameField, 'Ana');
    await tester.pump();
    await _tapVisible(tester, _saveButton);

    expect(find.text('Escolha pelo menos uma opção.'), findsOne);
    expect(repository.saveCalls, 0);

    // Depois da primeira tentativa, o erro some assim que é corrigido.
    await _tapVisible(tester, _gluten);
    expect(find.text('Escolha pelo menos uma opção.'), findsNothing);
  });

  testWidgets('recusa nome com uma letra só', (tester) async {
    final repository = MemoryProfileRepository();
    await _openForm(tester, repository: repository);

    await tester.enterText(_nameField, ' A ');
    await _tapVisible(tester, _gluten);
    await _tapVisible(tester, _saveButton);

    expect(find.text('Use pelo menos 2 letras.'), findsOne);
    expect(repository.saveCalls, 0);
  });

  testWidgets('contaminação cruzada depende de glúten', (tester) async {
    await _openForm(tester, repository: MemoryProfileRepository());

    expect(_crossContact(tester).onChanged, isNull);
    expect(find.text('Disponível quando você marca Glúten.'), findsOne);

    await _tapVisible(tester, _gluten);
    expect(_crossContact(tester).onChanged, isNotNull);

    await _tapVisible(tester, find.byType(SwitchListTile));
    expect(_crossContact(tester).value, isTrue);

    // Desmarcar glúten desliga e bloqueia o cuidado com contaminação.
    await _tapVisible(tester, _gluten);
    expect(_crossContact(tester).value, isFalse);
    expect(_crossContact(tester).onChanged, isNull);
  });

  testWidgets('salva, fecha e confirma', (tester) async {
    final repository = MemoryProfileRepository();
    await _openForm(tester, repository: repository);

    await tester.enterText(_nameField, '  Bia  ');
    await _tapVisible(tester, _lactose);
    await _tapVisible(tester, _saveButton);

    expect(find.byType(ProfileFormPage), findsNothing);
    expect(find.text('Perfil salvo'), findsOne);
    expect(
      repository.stored,
      const DietaryProfile(
        name: 'Bia',
        restrictions: {DietaryOption.lactoseFree},
      ),
    );
  });

  testWidgets('falha ao salvar mantém a tela e o rascunho', (tester) async {
    final repository = MemoryProfileRepository(failOnSave: true);
    await _openForm(tester, repository: repository);

    await _tapVisible(tester, _gluten);
    await _tapVisible(tester, _saveButton);

    expect(find.byType(ProfileFormPage), findsOne);
    expect(find.text('Não foi possível salvar. Tente novamente.'), findsOne);
    expect(tester.widget<CheckboxListTile>(_gluten).value, isTrue);
    expect(_isEnabled(tester, _saveButton), isTrue);
  });

  testWidgets('voltar sem alterações fecha direto', (tester) async {
    await _openForm(tester, repository: MemoryProfileRepository());

    await _back(tester);

    expect(find.byType(ProfileFormPage), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('voltar com alterações pergunta antes de descartar', (
    tester,
  ) async {
    final repository = MemoryProfileRepository();
    await _openForm(tester, repository: repository);
    await _tapVisible(tester, _gluten);

    await _back(tester);
    expect(find.text('Descartar alterações?'), findsOne);

    await tester.tap(find.text('Continuar editando'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileFormPage), findsOne);
    expect(tester.widget<CheckboxListTile>(_gluten).value, isTrue);

    await _back(tester);
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileFormPage), findsNothing);
    expect(repository.saveCalls, 0);
  });

  testWidgets('não transborda com fonte a 200% em tela pequena', (
    tester,
  ) async {
    await pumpWithProfile(
      tester,
      const ProfileFormPage(),
      repository: MemoryProfileRepository(stored: _ana),
      size: const Size(320, 640),
      textScale: 2,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // Vazio: o interruptor aparece desabilitado; preenchido: habilitado.
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
        const ProfileFormPage(),
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
