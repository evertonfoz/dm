# Prompt operacional: Implementação SharedPreferences do DTO local

Objetivo
--------
Gere um arquivo com a implementação do DTO local que persista DTOs usando SharedPreferences. O arquivo deve implementar estritamente as assinaturas da interface local (`upsertAll`, `listAll`, `getById`, `clear`) e usar JSON como formato de armazenamento.

Parâmetros (substitua antes de executar)
- SUFFIX: MoodEntry
- ENTITY: MoodEntryEntity
- DTO_NAME: MoodEntryDto
- DEST_DIR lib/features/mood_entry/infrastructure/local
- IMPORT_PATH (opcional): Identificar no projeto.
   CACHE_KEY (opcional): chave de SharedPreferences para armazenamento (ex.: `providers_cache_v1`). Se não informado, use `'<entity_em_minusculas>_cache_v1'`.

Requisitos exatos (assinaturas que sua classe deve implementar)
--------------------------------------------------------------
- `Future<void> upsertAll(List<DTO_NAME> dtos)`
- `Future<List<DTO_NAME>> listAll()`
- `Future<DTO_NAME?> getById(int id)`
- `Future<void> clear()`

Instruções de implementação (passos concretos)
---------------------------------------------
1. Crie o arquivo: `<DEST_DIR>/<entity_em_minusculas>_local_dto_shared_prefs.dart`.

2. Importe o DTO e as dependências necessárias:
   - Use `IMPORT_PATH` se fornecido; caso contrário: `import '../dtos/<entity_em_minusculas>_dto.dart';`.
   - `import 'dart:convert';`
   - `import 'package:shared_preferences/shared_preferences.dart';`
  - Import da interface local (ex.: `import 'providers_local_dto.dart';` ou caminho equivalente no seu projeto).

3. Declare a classe `<Suffix>LocalDtoSharedPrefs` que implemente a interface local correspondente (por exemplo `ProvidersLocalDto` / `<Suffix>LocalDto`).

4. Implementação técnica (seguir este comportamento):
   - Declare uma constante `_cacheKey` com o valor de `CACHE_KEY` quando informado, ou `'<entity_em_minusculas>_cache_v1'` por padrão.
   - Obtenha `SharedPreferences` com uma getter privado async similar a: `Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();`.

   - `upsertAll(List<DTO_NAME> dtos)`:
     - Leia o JSON atual da chave (`prefs.getString(_cacheKey)`), decodifique para uma lista de mapas (se presente).
     - Converta a lista atual em um Map<int, Map<String, dynamic>> indexado por `id` para facilitar o upsert.
     - Para cada DTO recebido, sobrescreva/adicione a entrada no map usando `dto.id` e `dto.toMap()` (assume que o DTO tem `id` e `toMap()`).
     - Salve de volta a lista (map.values.toList()) com `prefs.setString(_cacheKey, jsonEncode(mergedList))`.
     - Trate erros de decodificação silenciosamente e use fallback (lista vazia) — documente por comentário.

   - `listAll()`:
     - Leia o JSON, se ausente retornare `[]`.
     - Decodifique e converta cada mapa em `DTO_NAME.fromMap(Map<String, dynamic>)`.
     - Em caso de erro de decodificação, retorne lista vazia e documente a decisão.

   - `getById(int id)`:
     - Leia o JSON, iterar os itens e se encontrar `m['id'] == id` retorne `DTO_NAME.fromMap(m)`.
     - Caso contrário retorne `null`.

   - `clear()`:
     - Remova a chave do SharedPreferences com `prefs.remove(_cacheKey)`.

5. Tratamento de erros e notas importantes:
   - Capture exceções de `jsonDecode` e falhas de conversão; em caso de dados corrompidos, limpe a chave e retorne lista vazia ou `null` conforme o método.
   - Documente em comentários qualquer suposição (por ex.: "DTO possui id e métodos toMap/fromMap").
   - NÃO adicione métodos públicos extras — mantenha a API compatível com a interface abstrata.

Exemplo de esqueleto (Dart):

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Substitua pelo IMPORT_PATH quando fornecido
import '<IMPORT_PATH_or_../dtos/<entity_em_minusculas>_dto.dart>';
import 'providers_local_dto.dart';

class <Suffix>LocalDtoSharedPrefs implements <Suffix>LocalDto {
  static const _cacheKey = '<CACHE_KEY_or_<entity_em_minusculas>_cache_v1>';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  @override
  Future<void> upsertAll(List<DTO_NAME> dtos) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_cacheKey);
    final Map<int, Map<String, dynamic>> current = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        for (final e in list) {
          final m = Map<String, dynamic>.from(e as Map);
          current[m['id'] as int] = m;
        }
      } catch (_) {}
    }

    for (final dto in dtos) {
      current[dto.id] = dto.toMap();
    }

    final merged = current.values.toList();
    await prefs.setString(_cacheKey, jsonEncode(merged));
  }

  @override
  Future<List<DTO_NAME>> listAll() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => DTO_NAME.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<DTO_NAME?> getById(int id) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      for (final e in list) {
        final m = Map<String, dynamic>.from(e as Map);
        if (m['id'] == id) return DTO_NAME.fromMap(m);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_cacheKey);
  }
}
```

Saída esperada
--------------
- Arquivo criado: `<DEST_DIR>/<entity_em_minusculas>_local_dto_shared_prefs.dart` contendo a classe `<Suffix>LocalDtoSharedPrefs` com a implementação do comportamento acima e a constante `_cacheKey` usada para SharedPreferences.

Ao término
---------
- Informe os arquivos criados/alterados e o valor da chave usada no SharedPreferences (CACHE_KEY). Inclua uma nota de 1-2 linhas explicando a estratégia de persistência adotada e quaisquer simplificações feitas.
