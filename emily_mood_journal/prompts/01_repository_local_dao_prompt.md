
# Prompt operacional: Criar interface abstrata do DTO local

Objetivo
--------
Gere um arquivo de interface abstrata (classe abstrata) para o DTO local da entidade informada. O arquivo deve ser auto-contido e parametrizado por sufixo/entidade — ou seja, crie apenas a interface (não a implementação). Não faça referências a caminhos internos que os estudantes não terão acesso.

Parâmetros (substitua antes de executar)
- SUFFIX: MoodEntry
- ENTITY: MoodEntryEntity
- DTO_NAME: MoodEntryDto
- DEST_DIR lib/features/mood_entry/infrastructure/local
- IMPORT_PATH (opcional): Identificar no projeto.

Assinaturas esperadas (documentadas)
-----------------------------------
- `Future<void> upsertAll(List<DTO_NAME> dtos);`  — Upsert em lote por id (insere novos e atualiza existentes).
- `Future<List<DTO_NAME>> listAll();`             — Lista todos os registros locais (DTOs).
- `Future<DTO_NAME?> getById(int id);`            — Busca por id (DTO).
- `Future<void> clear();`                        — Limpa o cache (útil para reset/diagnóstico).

Instruções para gerar o arquivo de interface
--------------------------------------------
1. Crie o arquivo: `<DEST_DIR>/<entity_em_minusculas>_local_dto.dart` (ex.: `providers_local_dto.dart`).
2. No arquivo, declare um import para o DTO. Se `IMPORT_PATH` for fornecido, use-o exatamente como informado; caso contrário use o import relativo padrão: `import '../dtos/<entity_em_minusculas>_dto.dart`.
3. Declare uma classe abstrata chamada `<Suffix>LocalDto` (ex.: `ProvidersLocalDto`) contendo as quatro assinaturas acima com comentários em português explicando cada método (docstrings curtas).
4. Mantenha apenas a interface: não inclua implementação, utilitários ou dependências externas.

Exemplo de corpo (em pseudocódigo Dart):

```dart
// Exemplo de import; substitua por IMPORT_PATH quando fornecido
import '<IMPORT_PATH_or_../dtos/<entity_em_minusculas>_dto.dart>';

abstract class <Suffix>LocalDto {
   /// Upsert em lote por id (insere novos e atualiza existentes).
   Future<void> upsertAll(List<DTO_NAME> dtos);

   /// Lista todos os registros locais (DTOs).
   Future<List<DTO_NAME>> listAll();

   /// Busca por id (DTO).
   Future<DTO_NAME?> getById(int id);

   /// Limpa o cache (útil para reset/diagnóstico).
   Future<void> clear();
}
```

Saída esperada
--------------
- Arquivo criado: `<DEST_DIR>/<entity_em_minusculas>_local_dto.dart` contendo a classe abstrata `<Suffix>LocalDto` com as assinaturas e docstrings.

Ao término
---------
- Informe o caminho do arquivo criado e confirme que o conteúdo contém apenas a interface e os imports relativos.
