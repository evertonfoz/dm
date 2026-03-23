
# Prompt operacional: Gerar interface abstrata do repositório (parametrizado e didático)

> **Este prompt foi adaptado para fins didáticos. O código gerado deve conter comentários explicativos, exemplos de uso (em comentário) e orientações para facilitar o aprendizado dos alunos.**


Objetivo
--------
Gerar um arquivo Dart contendo **apenas a interface (classe abstrata)** de um repositório para uma entidade do domínio, de forma parametrizada (aceitando o nome da entidade e o sufixo da classe). O código gerado deve ser **didático**, com comentários explicativos para cada método, um comentário introdutório sobre o papel do repositório e um exemplo de uso ao final (em comentário).


Contexto e estilo
-----------------
- Baseie-se nas convenções do código e no estilo já presente nas entidades e repositórios.
- Use imports relativos por padrão, a menos que seja informado `IMPORT_PATH` explicitamente.
- **Inclua comentários explicativos** no topo do arquivo e acima de cada método, explicando o propósito e boas práticas.
- **Inclua um exemplo de uso** da interface ao final do arquivo, dentro de um bloco de comentário.


Parâmetros (substitua antes de executar)
----------------------------------------
- SUFFIX: sufixo do repositório (ex.: `Providers`). Será usado para formar o nome da classe abstrata: `<SUFFIX>Repository`.
- ENTITY: nome da entidade/model (ex.: `Provider`) — usado nos tipos de retorno.
- DEST_DIR (opcional): diretório destino para o arquivo. Padrão sugerido: `lib/features/<entity_em_minusculas>/domain/repositories/`.
- IMPORT_PATH (opcional): caminho de import para a entidade `ENTITY`. Se não informado, o gerador deve procurar automaticamente a entidade no projeto (ver seção "Investigação da entidade" abaixo) e usar um import relativo padrão como `../entities/<entity_em_minusculas>.dart`.


Investigação da entidade (obrigatória antes de gerar)
-----------------------------------------------------
Antes de gerar o arquivo, o agente deve:
1. Localizar a definição da entidade `ENTITY` no código-fonte do projeto.
2. Confirmar o caminho do arquivo que declara a classe (ex.: `lib/features/providers/domain/entities/provider.dart`).
3. Verificar que a classe exporta o símbolo correto (ex.: `class Provider`).
4. Determinar o nome em minúsculas/plural para formar caminhos (ex.: `provider` → `providers`).

**Se a entidade não for encontrada automaticamente, exiba uma mensagem de erro didática:**
> "Entidade <ENTITY> não encontrada. Verifique se a entidade foi criada corretamente ou forneça o IMPORT_PATH explícito. Dica: normalmente entidades ficam em `lib/features/<entidade_plural>/domain/entities/`."


Assinaturas exatas que devem constar na interface
--------------------------------------------------
- `Future<List<ENTITY>> loadFromCache();`  — Render inicial rápido a partir do cache local.
- `Future<int> syncFromServer();`           — Sincronização incremental (>= lastSync). Retorna quantos registros mudaram.
- `Future<List<ENTITY>> listAll();`       — Listagem completa (normalmente do cache após sync).
- `Future<List<ENTITY>> listFeatured();`  — Destaques (filtrados do cache por `featured`).
- `Future<ENTITY?> getById(int id);`      — Opcional: busca direta por ID no cache.

**Para cada método, adicione uma docstring curta em português e um comentário explicativo acima, detalhando o uso e boas práticas.**


Regras e restrições
-------------------
1. O arquivo deve conter somente a interface abstrata `<SUFFIX>Repository` e o(s) import(s) necessários.
2. Não inclua implementações, utilitários, ou chamadas a pacotes externos além do import da entidade.
3. Cada método deve ter uma docstring curta em português (uma linha) explicando o propósito, **e um comentário acima detalhando o uso e boas práticas**.
4. Preserve tipos exatos conforme `ENTITY` (por exemplo `Future<List<Provider>>`).
5. Use `import '<IMPORT_PATH_or_../entities/<entity_em_minusculas>.dart>';` no topo do arquivo — se `IMPORT_PATH` for dado, use-o exatamente; caso contrário, use o caminho detectado pela investigação.
6. **Inclua um comentário introdutório no topo do arquivo explicando o papel do repositório na arquitetura (exemplo abaixo).**
7. **Inclua ao final do arquivo, em bloco de comentário, um exemplo de uso da interface e dicas para implementação.**


Instruções de geração do arquivo
--------------------------------
1. Determine `entity_em_minusculas` a partir de `ENTITY` (ex.: `Provider` → `provider`). Recomende também a forma plural/coleção usada no projeto (ex.: `providers`) e use `DEST_DIR` como `lib/features/<entity_em_minusculas_plural>/domain/repositories/` por padrão.
2. **No topo do arquivo gerado, adicione um comentário explicando o papel do repositório e a importância de interfaces para testes e manutenção.**
3. **Acima de cada método, adicione um comentário explicativo sobre o uso e boas práticas.**
4. **Ao final do arquivo, adicione um bloco de comentário com exemplo de uso da interface e dicas para implementação.**

---


### Exemplo de comentário introdutório para o arquivo gerado:

```dart
/// Interface de repositório para a entidade <ENTITY>.
///
/// O repositório define as operações de acesso e sincronização de dados,
/// separando a lógica de persistência da lógica de negócio.
/// Utilizar interfaces facilita a troca de implementações (ex.: local, remota)
/// e torna o código mais testável e modular.
///
/// ⚠️ Dicas práticas para evitar erros comuns:
/// - Certifique-se de que a entidade <ENTITY> possui métodos de conversão robustos (ex: aceitar id como int ou string, datas como DateTime ou String).
/// - Ao implementar esta interface, adicione prints/logs (usando kDebugMode) nos métodos principais para facilitar o diagnóstico de problemas de cache, conversão e sync.
/// - Em métodos assíncronos usados na UI, sempre verifique se o widget está "mounted" antes de chamar setState, evitando exceções de widget desmontado.
/// - Consulte os arquivos de debug do projeto (ex: providers_cache_debug_prompt.md, supabase_init_debug_prompt.md, supabase_rls_remediation.md) para exemplos de logs, prints e soluções de problemas reais.
```


### Exemplo de bloco de uso ao final do arquivo:

```dart
/*
// Exemplo de uso:
final repo = MinhaImplementacaoDe<ENTITY>Repository();
final lista = await repo.listAll();

// Dica: implemente esta interface usando um DAO local e um datasource remoto.
// Para testes, crie um mock que retorna dados fixos.

// Checklist de erros comuns e como evitar:
// - Erro de conversão de tipos (ex: id como string): ajuste o fromMap/toMap da entidade/DTO para aceitar múltiplos formatos.
// - Falha ao atualizar UI após sync: verifique se o widget está mounted antes de chamar setState.
// - Dados não aparecem após sync: adicione prints/logs para inspecionar o conteúdo do cache e o fluxo de conversão.
// - Problemas com Supabase (RLS, inicialização): consulte supabase_rls_remediation.md e supabase_init_debug_prompt.md.

// Referências úteis:
// - providers_cache_debug_prompt.md
// - supabase_init_debug_prompt.md
// - supabase_rls_remediation.md
*/
```
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

# Observações adicionas

1. Caso o prompt proponha criar algum arquivo e esse arquivo já existir no projeto. Renomeie-o para .backup. E em seguida o remova.
2. Crie o novo arquivo
3. Garanta que a definição da classe do arquivo esteja escrita uma única vez no código