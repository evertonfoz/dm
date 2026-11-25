import 'dart:convert';

/// Endereço e chave pública do projeto Supabase, lidos na compilação.
///
/// Os valores vêm de `--dart-define-from-file=supabase.json` (ou de
/// `--dart-define`), nunca do código-fonte: assim cada aluno usa o próprio
/// projeto e nenhuma chave vai para o Git.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.publishableKey});

  /// Lê os valores passados por `--dart-define`. Vazios se ninguém passou.
  factory SupabaseConfig.fromEnvironment() {
    return const SupabaseConfig(
      url: String.fromEnvironment('SUPABASE_URL'),
      publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    );
  }

  final String url;
  final String publishableKey;

  /// A URL sem a barra final: `https://x.supabase.co/` vira
  /// `https://x.supabase.co`, e o client não monta `//rest/v1`.
  String get normalizedUrl =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  /// O que impede a conexão. Lista vazia quando está tudo certo.
  List<String> get problems => [
    if (url.isEmpty)
      'SUPABASE_URL não foi definida.'
    else if (!url.startsWith('https://'))
      'SUPABASE_URL deve começar com https://.',
    if (publishableKey.isEmpty)
      'SUPABASE_PUBLISHABLE_KEY não foi definida.'
    else if (_isSecretKey(publishableKey))
      'SUPABASE_PUBLISHABLE_KEY recebeu a chave SECRETA. Use a chave pública '
          '(publishable ou anon) e gere uma nova chave secreta no painel.',
  ];

  /// Reconhece os dois formatos de chave secreta: o novo (`sb_secret_...`) e
  /// o antigo, um JWT cujo conteúdo diz `"role": "service_role"`.
  static bool _isSecretKey(String key) {
    if (key.startsWith('sb_secret_')) {
      return true;
    }
    final parts = key.split('.');
    if (parts.length != 3) {
      return false;
    }
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      return (jsonDecode(payload) as Map<String, dynamic>)['role'] ==
          'service_role';
    } on FormatException {
      return false;
    }
  }
}
