import 'package:celilac/app/common/external_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monta o link de telefone só com os dígitos', () {
    expect(phoneUri('(44) 0000-0101').toString(), 'tel:4400000101');
  });

  test('monta o link do mapa com o endereço codificado', () {
    final uri = mapsUri('Rua das Palmeiras, 120 - Centro');

    expect(uri.host, 'www.google.com');
    expect(uri.queryParameters['query'], 'Rua das Palmeiras, 120 - Centro');
    expect(uri.toString(), contains('Rua+das+Palmeiras%2C+120'));
  });
}
