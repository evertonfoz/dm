import 'package:celilac/app/common/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formata distâncias menores que 1 km em metros', () {
    expect(formatDistance(0.35), '350\u00A0m');
  });

  test('formata distâncias a partir de 1 km com vírgula decimal', () {
    expect(formatDistance(1.2), '1,2\u00A0km');
    expect(formatDistance(1), '1,0\u00A0km');
  });
}
