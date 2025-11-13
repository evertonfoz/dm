# Prompt operacional: Gerar interface abstrata do repositório (parametrizado)

Objetivo
--------
Gere um arquivo Dart contendo apenas a interface (classe abstrata) de um repositório para uma entidade do domínio. O prompt deve ser parametrizado para aceitar o nome da entidade e o sufixo da classe (`SUFFIX` / `ENTITY`) — ou seja, não presuma `Providers`/`Provider` em hardcode.

Contexto e estilo
-----------------
- Baseie-se nas convenções do código e no estilo já presente nas entidades e repositórios.
- Use imports relativos por padrão, a menos que seja informado `IMPORT_PATH` explicitamente.

Parâmetros (substitua antes de executar)
---------------------------------------
- SUFFIX: sufixo do repositório (ex.: `Providers`). Será usado para formar o nome da classe abstrata: `<SUFFIX>Repository`.
- ENTITY: nome da entidade/model (ex.: `Provider`) — usado nos tipos de retorno.
- DEST_DIR (opcional): diretório destino para o arquivo. Padrão sugerido: `lib/features/<entity_em_minusculas>/domain/repositories/`.
- IMPORT_PATH (opcional): caminho de import para a entidade `ENTITY`. Se não informado, o gerador deve procurar automaticamente a entidade no projeto (ver seção "Investigação da entidade" abaixo) e usar um import relativo padrão como `../entities/<entity_em_minusculas>.dart`.

Investigação da entidade (obrigatória antes de gerar)
----------------------------------------------------
O gerador/agent que executar este prompt deve, antes de escrever o arquivo, localizar a definição da entidade `ENTITY` no código-fonte do projeto e confirmar:

1. O caminho do arquivo que declara a classe `ENTITY` (ex.: `lib/features/providers/domain/entities/provider.dart`).
2. Que a classe `ENTITY` exporta o símbolo com o mesmo nome (p.ex. `class Provider`).
3. Qual é o nome em minúsculas para formar caminhos (ex.: `provider` → `providers` para pastas/arquivos).

Se a entidade não for encontrada automaticamente, o gerador deve falhar com uma mensagem clara: "Entidade <ENTITY> não encontrada; forneça IMPORT_PATH explícito".

Assinaturas exatas que devem constar na interface
-------------------------------------------------
- `Future<List<ENTITY>> loadFromCache();`  — Render inicial rápido a partir do cache local.
- `Future<int> syncFromServer();`           — Sincronização incremental (>= lastSync). Retorna quantos registros mudaram.
- `Future<List<ENTITY>> listAll();`       — Listagem completa (normalmente do cache após sync).
- `Future<List<ENTITY>> listFeatured();`  — Destaques (filtrados do cache por `featured`).
- `Future<ENTITY?> getById(int id);`      — Opcional: busca direta por ID no cache.

Regras e restrições
-------------------
1. O arquivo deve conter somente a interface abstrata `<SUFFIX>Repository` e o(s) import(s) necessários.
2. Não inclua implementações, utilitários, ou chamadas a pacotes externos além do import da entidade.
3. Cada método deve ter uma docstring curta em português (uma linha) explicando o propósito.
4. Preserve tipos exatos conforme `ENTITY` (por exemplo `Future<List<Provider>>`).
5. Use `import '<IMPORT_PATH_or_../entities/<entity_em_minusculas>.dart>';` no topo do arquivo — se `IMPORT_PATH` for dado, use-o exatamente; caso contrário, use o caminho detectado pela investigação.

Instruções de geração do arquivo
--------------------------------
1. Determine `entity_em_minusculas` a partir de `ENTITY` (ex.: `Provider` → `provider`). Recomende também a forma plural/coleção usada no projeto (ex.: `providers`) e use `DEST_DIR` como `lib/features/<entity_em_minusculas_plural>/domain/repositories/` por padrão.
2. Crie o arquivo em `DEST_DIR` com o nome `<entity_em_minusculas>_repository.dart` (por exemplo `providers_repository.dart`).
3. No topo do arquivo, coloque o import para a entidade `ENTITY` conforme `IMPORT_PATH` ou o import relativo descoberto.
4. Declare a classe abstrata `<SUFFIX>Repository` contendo as assinaturas acima, cada uma precedida por um comentário `///` em português.
5. Verifique se o arquivo não adiciona outras dependências ou códigos além do import e da interface.

Exemplo de saída esperada (Dart)
-------------------------------
```dart
import '<IMPORT_PATH_or_../entities/<entity_em_minusculas>.dart';

abstract class <SUFFIX>Repository {
  /// Render inicial rápido a partir do cache local.
  Future<List<<ENTITY>>> loadFromCache();

  /// Sincronização incremental (>= lastSync). Retorna quantos registros mudaram.
  Future<int> syncFromServer();

  /// Listagem completa (normalmente do cache após sync).
  Future<List<<ENTITY>>> listAll();

  /// Destaques (filtrados do cache por `featured`).
  Future<List<<ENTITY>>> listFeatured();

  /// Opcional: busca direta por ID no cache.
  Future<<ENTITY>?> getById(int id);
}
```

Checklist de validação (após geração)
-------------------------------------
- [ ] O arquivo foi criado em `DEST_DIR/<entity_em_minusculas>_repository.dart`.
- [ ] Contém um único import para `ENTITY` e a declaração `abstract class <SUFFIX>Repository`.
- [ ] Todas as assinaturas e docstrings estão presentes e em português.
- [ ] Não há implementações adicionais ou imports desnecessários.

Notas finais e recomendações
---------------------------
- Antes de usar o prompt para gerar implementações, assegure-se de que a entidade `ENTITY` possui `toMap`/`fromMap` se a implementação local depender de serialização (isso é comum nos DAOs do projeto).
- Para gerar implementações locais (SharedPreferences/DAO) ou remotas (API), reutilize os prompts existentes (`01_repository_local_dao_prompt.md`, `02_repository_local_dao_shared_prefs_prompt.md`) adaptando `ENTITY`/`SUFFIX`.
- Se desejar, posso agora usar este prompt para gerar o arquivo Dart (interface) no repositório e rodar uma análise rápida — diga se devo prosseguir.
