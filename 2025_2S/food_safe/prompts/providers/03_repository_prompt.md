# Prompt operacional: Criar interface abstrata do repositório (Repository)

Objetivo
--------
Gere um arquivo de interface abstrata (classe abstrata) para um repositório de entidade. O arquivo deve declarar apenas a interface (sem implementação) contendo as assinaturas e docstrings em português para os métodos necessários.

Parâmetros (substitua antes de executar)
- SUFFIX: sufixo do repositório (ex.: Provider) — será usado para nomear a classe abstrata `<Suffix>Repository`.
- ENTITY: nome da entidade/model (ex.: Provider) — usado nos tipos de retorno.
- DEST_DIR (opcional): diretório destino para o arquivo. Se não informado, a assistente deve escolher um local apropriado e reportar o caminho.
- IMPORT_PATH (opcional): caminho de import para o model/entidade a colocar no arquivo (ex.: `../entities/providers.dart` ou `package:my_app/features/providers/domain/entities/provider.dart`). Se não informado, usar o import relativo padrão `../entities/<entity_em_minusculas>.dart`.

Assinaturas exatas que devem constar na interface
-------------------------------------------------
- `Future<List<ENTITY>> loadFromCache();` — Render inicial rápido a partir do cache local.
- `Future<int> syncFromServer();` — Sincronização incremental (>= lastSync). Retorna quantos registros mudaram.
- `Future<List<ENTITY>> listAll();` — Listagem completa (normalmente do cache após sync).
- `Future<List<ENTITY>> listFeatured();` — Destaques (filtrados do cache por `featured`).
- `Future<ENTITY?> getById(int id);` — Opcional: busca direta por ID no cache.

Instruções para gerar o arquivo de interface
-------------------------------------------
1. Crie um arquivo com nome sugestivo, por exemplo `<DEST_DIR>/<entity_em_minusculas>_repository.dart` (ou escolha um local adequado se `DEST_DIR` não for informado).
2. Declare um import para a entidade/model. Se `IMPORT_PATH` for fornecido, use-o exatamente como informado; caso contrário, use o import relativo padrão: `import '../entities/<entity_em_minusculas>.dart`.
3. Declare uma classe abstrata chamada `<Suffix>Repository` contendo apenas as assinaturas acima, cada uma acompanhada de uma docstring (comentário) em português que descreva o comportamento resumido.
4. Não inclua implementação, utilitários ou dependências externas no arquivo — somente a interface.

Exemplo de esqueleto (Dart):

```dart
// Exemplo de import — substitua pela `IMPORT_PATH` quando fornecida
import '<IMPORT_PATH_or_../entities/<entity_em_minusculas>.dart>';

abstract class <Suffix>Repository {
  /// Render inicial rápido a partir do cache local.
  Future<List<<Entity>>> loadFromCache();

  /// Sincronização incremental (>= lastSync). Retorna quantos registros mudaram.
  Future<int> syncFromServer();

  /// Listagem completa (normalmente do cache após sync).
  Future<List<<Entity>>> listAll();

  /// Destaques (filtrados do cache por `featured`).
  Future<List<<Entity>>> listFeatured();

  /// Opcional: busca direta por ID no cache.
  Future<<Entity>?> getById(int id);
}
```

Saída esperada
--------------
- Arquivo criado: `<DEST_DIR>/<entity_em_minusculas>_repository.dart` contendo a classe abstrata `<Suffix>Repository` com as assinaturas e docstrings.

Ao término
---------
- Informe o caminho do arquivo criado e confirme que o conteúdo contém apenas a interface e os imports relativos.
