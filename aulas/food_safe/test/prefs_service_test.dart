import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:celilac_life/services/shared_preferences_services.dart';

void main() {
  setUp(() async {
    // Reset mock shared preferences before each test
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Ensure service instance initialized against mock prefs
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

  test('revokeMarketingConsent does not remove personal data', () async {
    // Set personal data and marketing consent
    await SharedPreferencesService.setUserName('Bob');
    await SharedPreferencesService.setUserEmail('bob@example.com');
    await SharedPreferencesService.setMarketingConsent(true);

    // Revoke marketing consent
    await SharedPreferencesService.revokeMarketingConsent();

    // marketing consent should be false/default
    expect(await SharedPreferencesService.getMarketingConsent(), false);

    // personal data should remain
    expect(await SharedPreferencesService.getUserName(), 'Bob');
    expect(await SharedPreferencesService.getUserEmail(), 'bob@example.com');
  });
}
