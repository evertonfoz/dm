import 'package:celilac/features/explore/domain/search_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ignora maiúsculas, acentos e espaços nas pontas', () {
    expect(normalizeSearchText('  Bistrô Bem-Estar '), 'bistro bem-estar');
    expect(normalizeSearchText('CAFÉ'), 'cafe');
    expect(normalizeSearchText('Pão de Açúcar'), 'pao de acucar');
  });

  test('texto vazio continua vazio', () {
    expect(normalizeSearchText('   '), '');
  });
}
