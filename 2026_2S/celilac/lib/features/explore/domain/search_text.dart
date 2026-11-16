const _accents = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
};

/// Deixa o texto comparável: minúsculas, sem acentos e sem espaços nas pontas.
/// "Bistrô" e "bistro" viram a mesma coisa.
String normalizeSearchText(String text) {
  final lower = text.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final character in lower.split('')) {
    buffer.write(_accents[character] ?? character);
  }
  return buffer.toString();
}
