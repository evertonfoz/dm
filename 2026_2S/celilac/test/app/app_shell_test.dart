import 'package:celilac/app/shell/app_shell.dart';
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
}
