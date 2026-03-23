/// Small helpers for environment handling used by main.dart and tests.
String maskSecret(String? v) {
  if (v == null || v.isEmpty) return '<missing>';
  if (v.length <= 6) return '******';
  return '${v.substring(0, 3)}***${v.substring(v.length - 3)}';
}

/// Parse a simple .env file content into a map. Supports comments and quoted values.
Map<String, String> parseEnvContent(String content) {
  final Map<String, String> out = {};
  for (final rawLine in content.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('#')) continue;
    final idx = line.indexOf('=');
    if (idx <= 0) continue;
    final k = line.substring(0, idx).trim();
    var v = line.substring(idx + 1).trim();
    if ((v.startsWith('"') && v.endsWith('"')) ||
        (v.startsWith("'") && v.endsWith("'"))) {
      v = v.substring(1, v.length - 1);
    }
    out[k] = v;
  }
  return out;
}
