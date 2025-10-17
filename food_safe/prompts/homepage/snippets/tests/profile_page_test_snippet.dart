// Snippet: profile_page_test_snippet.dart
// Cole em test/ para usar como base

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:celilac_life/features/home/profile_page.dart';
import 'package:celilac_life/services/shared_preferences_services.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesService.resetForTests();
    await SharedPreferencesService.getInstance();
  });

  testWidgets('ProfilePage save flow', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));

    final nameField = find.byType(TextFormField).first;
    final emailField = find.byType(TextFormField).last;
    final saveButton = find.widgetWithText(ElevatedButton, 'Salvar');

    await tester.enterText(nameField, 'Test User');
    await tester.enterText(emailField, 'test@example.com');
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(await SharedPreferencesService.getUserName(), 'Test User');
    expect(await SharedPreferencesService.getUserEmail(), 'test@example.com');
  });
}
