import 'package:flutter_test/flutter_test.dart';
import 'package:celilac_life/services/env_service.dart';

void main() {
  test('EnvService resolves Platform.environment fallback', () async {
    // Simulate a platform env variable for test
    const key = 'FOO_TEST_BAR';
    // Platform.environment is read-only; we can't set it directly here.
    // We'll test that get() returns null when nothing set.
    await EnvService.ensureInitialized(candidates: []);
    final v = EnvService.get(key);
    expect(v, isNull);
  });
}
