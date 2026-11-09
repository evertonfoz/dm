import 'package:celilac/app/shell/app_shell.dart';
import 'package:celilac/features/favorites/presentation/pages/favorites_page.dart';
import 'package:celilac/features/home/presentation/pages/home_page.dart';
import 'package:celilac/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('a aba Perfil mostra o perfil, e não "em breve"', (tester) async {
    await pumpWithProfile(tester, const AppShell());

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Perfil'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOne);
    expect(find.text('Completar perfil'), findsWidgets);
    expect(find.text('Estamos preparando esta área para você.'), findsNothing);

    // Deixa terminar o atraso simulado do FakeEstablishmentRepository.
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets(
    'favoritar na Home mostra na aba Favoritos e abre o detalhe sem colisão de Hero',
    (tester) async {
      await pumpWithProfile(tester, const AppShell());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final saveOnHome = find.byTooltip('Salvar Café Aconchego nos favoritos');
      await tester.scrollUntilVisible(
        saveOnHome,
        200,
        scrollable: find
            .descendant(
              of: find.byType(HomePage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(saveOnHome);
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Favoritos'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FavoritesPage), findsOne);
      expect(find.text('1 lugar salvo'), findsOne);

      await tester.tap(
        find.descendant(
          of: find.byType(FavoritesPage),
          matching: find.text('Café Aconchego'),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Cuidados com contaminação cruzada'), findsOne);
      expect(tester.takeException(), isNull);
    },
  );
}
