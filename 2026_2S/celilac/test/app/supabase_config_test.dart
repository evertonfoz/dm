import 'dart:convert';

import 'package:celilac/app/config/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Um JWT de mentira com o [role] informado (as chaves antigas são JWTs).
String _legacyKey(String role) {
  String part(Map<String, Object> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'role': role})}.assinatura';
}

void main() {
  test('URL e chave pública válidas não têm problemas', () {
    const config = SupabaseConfig(
      url: 'https://abcdefgh.supabase.co',
      publishableKey: 'sb_publishable_abc123',
    );

    expect(config.problems, isEmpty);
  });

  test('sem --dart-define, aponta as duas ausências', () {
    const config = SupabaseConfig(url: '', publishableKey: '');

    expect(config.problems, [
      'SUPABASE_URL não foi definida.',
      'SUPABASE_PUBLISHABLE_KEY não foi definida.',
    ]);
  });

  test('exige https', () {
    const config = SupabaseConfig(
      url: 'abcdefgh.supabase.co',
      publishableKey: 'sb_publishable_abc123',
    );

    expect(config.problems.single, contains('https://'));
  });

  test('recusa a chave secreta nova (sb_secret_)', () {
    const config = SupabaseConfig(
      url: 'https://abcdefgh.supabase.co',
      publishableKey: 'sb_secret_abc123',
    );

    expect(config.problems.single, contains('SECRETA'));
  });

  test('recusa a chave secreta antiga (JWT service_role)', () {
    final config = SupabaseConfig(
      url: 'https://abcdefgh.supabase.co',
      publishableKey: _legacyKey('service_role'),
    );

    expect(config.problems.single, contains('SECRETA'));
  });

  test('aceita a chave pública antiga (JWT anon)', () {
    final config = SupabaseConfig(
      url: 'https://abcdefgh.supabase.co',
      publishableKey: _legacyKey('anon'),
    );

    expect(config.problems, isEmpty);
  });

  test('remove a barra final da URL', () {
    const config = SupabaseConfig(
      url: 'https://abcdefgh.supabase.co/',
      publishableKey: 'sb_publishable_abc123',
    );

    expect(config.normalizedUrl, 'https://abcdefgh.supabase.co');
  });
}
