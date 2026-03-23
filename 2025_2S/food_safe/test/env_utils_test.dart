import 'package:flutter_test/flutter_test.dart';
import 'package:celilac_life/utils/env_utils.dart';

void main() {
  test('maskSecret masks correctly', () {
    expect(maskSecret(null), '<missing>');
    expect(maskSecret(''), '<missing>');
    expect(maskSecret('abc'), '******');
    expect(maskSecret('abcdefgh'), 'abc***fgh');
  });

  test('parseEnvContent parses simple env', () {
    final content = '''
# comment
KEY1=value1
KEY2="quoted value"
BADLINE
KEY3='another'
''';
    final map = parseEnvContent(content);
    expect(map['KEY1'], 'value1');
    expect(map['KEY2'], 'quoted value');
    expect(map['KEY3'], 'another');
  });
}
