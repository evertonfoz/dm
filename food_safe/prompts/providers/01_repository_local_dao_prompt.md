
# Prompt operacional: Criar interface abstrata do DAO local

Objetivo
--------
Gere um arquivo de interface abstrata (classe abstrata) para o DAO local da entidade informada. O arquivo deve ser auto-contido e parametrizado por sufixo/entidade — ou seja, crie apenas a interface (não a implementação). Não faça referências a caminhos internos que os estudantes não terão acesso.

Parâmetros (substitua antes de executar)
- SUFFIX: sufixo do DAO (ex.: Provider)
- ENTITY: nome da entidade/model (ex.: Provider)
- DTO_NAME: nome do DTO (ex.: ProviderDto)
- DEST_DIR (opcional): diretório destino para o arquivo DAO. Se não informado, use `lib/features/<entity_em_minusculas>/infrastructure/local/`.
- IMPORT_PATH (opcional): caminho de import para o DTO/entidade (ex.: `../dtos/provider_dto.dart` ou `package:my_app/features/providers/infrastructure/dtos/provider_dto.dart`). Se não informado, use o import relativo padrão `../dtos/<entity_em_minusculas>_dto.dart`.

Assinaturas esperadas (documentadas)
-----------------------------------
- `Future<void> upsertAll(List<DTO_NAME> dtos);`  — Upsert em lote por id (insere novos e atualiza existentes).
- `Future<List<DTO_NAME>> listAll();`             — Lista todos os registros locais (DTOs).
- `Future<DTO_NAME?> getById(int id);`            — Busca por id (DTO).
- `Future<void> clear();`                        — Limpa o cache (útil para reset/diagnóstico).

Instruções para gerar o arquivo de interface
--------------------------------------------
1. Crie o arquivo: `<DEST_DIR>/<entity_em_minusculas>_local_dao.dart` (ex.: `providers_local_dao.dart`).
2. No arquivo, declare um import para o DTO. Se `IMPORT_PATH` for fornecido, use-o exatamente como informado; caso contrário use o import relativo padrão: `import '../dtos/<entity_em_minusculas>_dto.dart`.
3. Declare uma classe abstrata chamada `<Suffix>LocalDao` (ex.: `ProvidersLocalDao`) contendo as quatro assinaturas acima com comentários em português explicando cada método (docstrings curtas).
4. Mantenha apenas a interface: não inclua implementação, utilitários ou dependências externas.

Exemplo de corpo (em pseudocódigo Dart):

```dart
// Exemplo de import; substitua por IMPORT_PATH quando fornecido
import '<IMPORT_PATH_or_../dtos/<entity_em_minusculas>_dto.dart>';

abstract class <Suffix>LocalDao {
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
- Arquivo criado: `<DEST_DIR>/<entity_em_minusculas>_local_dao.dart` contendo a classe abstrata `<Suffix>LocalDao` com as assinaturas e docstrings.

Ao término
---------
- Informe o caminho do arquivo criado e confirme que o conteúdo contém apenas a interface e os imports relativos.
