// Snippet: prefs_service_test_snippet.dart
// Cole em test/ para usar como base

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:celilac_life/services/shared_preferences_services.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesService.resetForTests();
    await SharedPreferencesService.getInstance();
  });

  test('set/get/remove userName and userEmail', () async {
    await SharedPreferencesService.setUserName('Alice');
    expect(await SharedPreferencesService.getUserName(), 'Alice');

    await SharedPreferencesService.setUserEmail('alice@example.com');
    expect(await SharedPreferencesService.getUserEmail(), 'alice@example.com');

    await SharedPreferencesService.removeUserName();
    expect(await SharedPreferencesService.getUserName(), isNull);

    await SharedPreferencesService.removeUserEmail();
    expect(await SharedPreferencesService.getUserEmail(), isNull);
  });
}
