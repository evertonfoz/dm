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

/// "  Bistrô " -> "bistro". Usada na busca para ignorar acento e maiúscula.
String normalizeSearchText(String text) {
  // toLowerCase primeiro: o mapa só precisa das letras minúsculas.
  final lower = text.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final character in lower.split('')) {
    buffer.write(_accents[character] ?? character);
  }
  return buffer.toString();
}
