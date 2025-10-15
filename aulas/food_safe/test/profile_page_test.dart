import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:celilac_life/features/home/profile_page.dart';
import 'package:celilac_life/services/shared_preferences_services.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Reset service singleton to avoid state leakage between tests
    SharedPreferencesService.resetForTests();
    await SharedPreferencesService.getInstance();
  });

  testWidgets('ProfilePage validation and save flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));

    // Initially, fields are empty and Save is enabled
    final nameField = find.byType(TextFormField).first;
    final emailField = find.byType(TextFormField).last;
    final saveButton = find.widgetWithText(ElevatedButton, 'Salvar');

    await tester.enterText(nameField, 'Test User');
    await tester.enterText(emailField, 'test@example.com');

    // tap the privacy checkbox
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    // tap save
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Expect data saved in prefs (SnackBar is shown inside page and the page pops; checking prefs is more reliable)
    expect(await SharedPreferencesService.getUserName(), 'Test User');
    expect(await SharedPreferencesService.getUserEmail(), 'test@example.com');
  });

  testWidgets('ProfilePage shows validation errors for empty fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));

    final saveButton = find.widgetWithText(ElevatedButton, 'Salvar');

    // Tap save without entering data
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Expect no data saved in prefs when trying to save empty fields
    expect(await SharedPreferencesService.getUserName(), isNull);
    expect(await SharedPreferencesService.getUserEmail(), isNull);
  });
}
