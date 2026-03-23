````markdown
AGENTS.md

Aviso recebido: "Deprecated. Use `dart run` instead."

Contexto
-----------
Algumas ferramentas e scripts ainda invocam comandos antigos do Dart/Flutter que agora estão deprecados. Um exemplo comum é o uso de `pub run` ou chamadas diretas de binários que foram substituídas por `dart run`.

Objetivo
--------
Evitar warnings e problemas futuros substituindo chamadas de comandos deprecados por `dart run` e mantendo scripts e pipelines (CI) atualizados.

O que fazer (resumo rápido)
- Substitua chamadas antigas como `pub run <package>:<command>` por `dart run <package>:<command>`.
- Atualize scripts de shell, Makefiles, GitHub Actions e configuração de CI para usar `dart run`.
- Garanta que a versão do SDK Dart usada na CI é compatível (compatível com `dart run`).

Exemplos
--------
- Antes (deprecado):
  flutter pub run flutter_launcher_icons:main

- Depois (recomendado):
  dart run flutter_launcher_icons:main

- Em scripts que precisam do Flutter context (por exemplo executar com a versão do Flutter):
  flutter pub get && dart run flutter_launcher_icons:main

Boas práticas para scripts e CI
--------------------------------
- Use comandos idempotentes quando possível (ex.: `dart pub get`/`flutter pub get`) antes de `dart run` para garantir dependências resolvidas.
- Prefira invocar `dart` explicitamente para rodar packages executáveis: `dart run <package>`.
- Em pipelines de CI com Flutter, mantenha a etapa de setup do Flutter (instalar SDK ou usar action/setup-flutter) e, em seguida, use `dart run` para chamar os executáveis.
- Verifique a versão do SDK com `dart --version` no início do job e falhe rápido com uma mensagem clara se a versão for incompatível.

Exemplo de atualização em GitHub Actions (snippet):

```yaml
steps:
  - uses: actions/checkout@v3
  - uses: subosito/flutter-action@v2
    with:
      flutter-version: 'stable'
  - name: Install dependencies
    run: flutter pub get
  - name: Run icon generator
    run: dart run flutter_launcher_icons:main
```

Quando investigar um warning deprecatado
--------------------------------------
1. Leia a mensagem de deprecação — geralmente ela sugere o substituto (ex: `Use 'dart run' instead`).
2. Localize todos os usos no repositório (grep por `pub run` ou pela chamada mencionada).
3. Atualize os scripts e verifique localmente.
4. Atualize documentação e README que contenham comandos antigos.

Checklist rápido
- [ ] Atualizar scripts locais (`scripts/`, `bin/`, `Makefile`)
- [ ] Atualizar CI (GitHub Actions, GitLab CI, Bitrise, Codemagic, etc.)
- [ ] Trocar `flutter pub run` por `dart run` quando aplicável
- [ ] Rodar pipeline localmente para validar

Notas finais
-----------
`dart run` executa executáveis definidos em `pubspec.yaml` e é o fluxo recomendado atualmente. Manter scripts atualizados evita warnings, melhora compatibilidade futura e mantém a base de código mais limpa.

Se quiser, posso:
- localizar e substituir automaticamente ocorrências de comandos deprecados no repositório (fazer commits com as mudanças);
- ou criar um pequeno script que escaneie e liste arquivos que usam comandos deprecados para você revisar.

Nota para agentes/LLMs
----------------------

- Ao gerar ou modificar snippets de teste que chamem APIs marcadas com `@visibleForTesting` (por exemplo `SharedPreferences.setMockInitialValues`), preferir colocar o código real em `test/`.
- Se um snippet for mantido fora de `test/` (ex.: documentação, `prompts/`), inclua localmente a diretiva de análise para silenciar o warning apenas nessa linha:

```dart
// ignore: invalid_use_of_visible_for_testing_member
SharedPreferences.setMockInitialValues({});
```

Isso permite manter exemplos executáveis e evita ruído do analisador quando o código é propositalmente um mock para teste.

Convenções de código: constantes e persistência (IMPORTANTE)
-----------------------------------------------------------
Ao modificar ou gerar código neste repositório, siga estas convenções para evitar lints e duplicações de camada:

- Nomes de constantes privadas: use lowerCamelCase com um underscore inicial para constantes privadas de arquivo/biblioteca. Ex.: `_compileSupabaseKey` em vez de `_compile_SUPABASE_KEY`.
  - Racional: o lint `constant_identifier_names` recomenda lowerCamelCase em Dart; o underscore inicial permanece como o marcador de privacidade.
  - Observação: `String.fromEnvironment` exige uma constante em tempo de compilação, mas não impõe o estilo de nome — renomear para lowerCamelCase é seguro e preferível.

- Persistência / DAO existentes: quando o repositório já expõe um DAO local (ex.: `lib/features/<feature>/infrastructure/local/...`), NÃO crie um novo wrapper/repositório apenas por padrão.
  - Preferir reutilizar o DAO existente diretamente ou injetá-lo na `Page`/`Service` para testes.
  - Só criar um `..._repository.dart` (ou similar) se a base do projeto já seguir esse padrão e for necessário para integrar com a arquitetura existente.

- Boas práticas ao gerar/editar código automaticamente:
  - Evite duplicar camadas: se uma implementação local já existe, a ação recomendada é reutilizá-la e adaptar a chamada ao padrão do projeto (injeção por construtor, service locator, etc.).
  - Encapsule IO em métodos privados e trate erros com try/catch, exibindo `SnackBar` quando apropriado.
  - Adote `super.key` para construtores simples quando possível (`const Widget({super.key});`).

  - If statements: sempre use chaves
    - Ao escrever `if` / `else` prefira sempre usar chaves mesmo para uma única instrução.
      Ex.:
      ```dart
      // preferível
      if (cond) {
        doSomething();
      }

      // não preferível
      if (cond) doSomething();
      ```
    - Racional: evita ambiguidades, facilita futuras modificações e elimina o lint `curly_braces_in_flow_control_structures` do analisador.
    - Ferramenta: ao automatizar refactors, aplique esta mudança de forma massiva e segura onde o padrão estiver presente.

Seguindo estas regras reduzimos avisos do analyzer, evitamos duplicação de responsabilidades e mantemos a base de código mais consistente.

Banco de dados - pasta `sqls/` (IMPORTANTE para agentes)
-----------------------------------------------------
O repositório contém uma pasta `sqls/` na raiz que armazena scripts SQL de definição de tabelas e índices usados para sincronização e validação de esquema. Agentes automatizados e revisores devem:

- Sempre verificar `sqls/` (e subpastas) ao avaliar a estrutura do banco de dados.
- Usar os scripts dentro de `sqls/` como fonte de verdade para criar/validar tabelas em ambientes de staging e migrações de testes.
- Para novos modelos de dados, adicionar um script `create_table_<entidade>.sql` na pasta apropriada e atualizar este arquivo de documentação.

Exemplo de localização e uso:

```
sqls/providers/create_table_providers.sql
```

Ao executar avaliações de schema ou sincronizações incrementais, verifique `updated_at` e índices provistos nos scripts para garantir que filtros de sincronização (`updated_at > :last_sync`) funcionem corretamente.


## Constructor shorthand: converting `Key? key` to `super.key`

Context
-------
Modern Dart supports passing constructor parameters directly to the superclass using super-parameters, e.g. `const MyWidget({super.key});`. The analyzer reports `Parameter 'key' could be a super parameter` when a constructor declares `Key? key` and forwards it to the superclass via `: super(key: key)`.

Why convert
-----------
- Cleaner code and fewer boilerplate parameters.
- Satisfies lints and modern Dart style guides.

Quick automated change
----------------------
For constructors like:

```dart
class Foo extends StatelessWidget {
  const Foo({Key? key}) : super(key: key);
}
```

Replace with:

```dart
class Foo extends StatelessWidget {
  const Foo({super.key});
}
```

Migration checklist
------------------
1. Search the repo for `super(key: key)` occurrences and review the surrounding constructor.
2. Replace `const X({Key? key}) : super(key: key);` with `const X({super.key});`.
3. Run `flutter analyze` to catch any remaining occurrences or related lints.
4. Run tests / manual checks for widgets that rely on custom `key` handling (rare).

Notes
-----
- This transformation is source-compatible and safe for typical widgets. If a constructor also has other initializers or parameters, ensure you preserve them and only replace the key parameter.
- I can prepare a codemod (small Dart script) to apply this change across the repo and open a branch/PR.

## Colors and Flutter deprecations: replacing `.withOpacity()`

Context
-------
The Flutter SDK may deprecate `Color.withOpacity()` in favor of APIs that avoid precision loss (for example `.withValues()` in newer SDKs) or by using explicit alpha channels. You may see analyzer warnings like:

```
info • 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid
          precision loss
```

Quick fix (recommended)
-----------------------
When the opacity is a numeric literal (e.g. `0.08`, `0.2`), replace `color.withOpacity(x)` with `color.withAlpha((x * 255).round())`.

Example:

```dart
// before
color: myColor.withOpacity(0.08),

// after
color: myColor.withAlpha((0.08 * 255).round()),
```

Notes and best practices
------------------------
- Prefer using `Theme.of(context).colorScheme` (and the `onX` colors) instead of manipulating opacity when possible — more robust across light/dark themes.
- If your target Flutter SDK documents and provides `.withValues()` as the recommended API, prefer it after bumping the SDK and verifying behavior.

Migration checklist
------------------
1. Search the repo for `.withOpacity(` and inspect each occurrence.
2. Replace literal-based calls with `withAlpha((<num>*255).round())` or refactor to theme-based colors.
3. Run `flutter analyze` and `flutter test` (if present).
4. Manually review the affected screens for visual regressions.

I can run an automated pass (codemod) to replace literal `withOpacity(...)` occurrences and open a branch/PR if you want.


## Material 3: prefer `onSurface` over deprecated `onBackground`

Context
-------
Recent Material 3 updates deprecate `colorScheme.onBackground` in many usages in favor of `colorScheme.onSurface` (or another `onX` color that better reflects the surface role). The analyzer may report:

```
info • 'onBackground' is deprecated and shouldn't be used. Use onSurface instead.
```

Quick fix
---------
- When a widget uses `colorScheme.onBackground` for foreground content (text, icons) placed over app surfaces, prefer `colorScheme.onSurface`.
- If you purposely targeted a background-specific contrast role, review `onSurfaceVariant` / `onPrimaryContainer` / `onSecondaryContainer` to pick the color that matches the surface semantics.

Examples
--------
// before
color: Theme.of(context).colorScheme.onBackground,

// after
color: Theme.of(context).colorScheme.onSurface,

Migration checklist
------------------
1. Search the repo for `onBackground` usages and inspect the visual role (foreground vs background).
2. Replace straightforward foreground usages with `onSurface`.
3. For usages that intentionally targeted a very specific surface color, consider `onSurfaceVariant` or container-specific colors instead of a blind replacement.
4. Run `flutter analyze` and then visually test affected screens to avoid contrast regressions.

I can run an automated codemod to replace obvious `onBackground` -> `onSurface` occurrences and open a branch/PR, but I recommend doing this in small batches and reviewing visual changes per screen.

````
AGENTS.md

Aviso recebido: "Deprecated. Use `dart run` instead."

Contexto
-----------
Algumas ferramentas e scripts ainda invocam comandos antigos do Dart/Flutter que agora estão deprecados. Um exemplo comum é o uso de `pub run` ou chamadas diretas de binários que foram substituídas por `dart run`.

Objetivo
--------
Evitar warnings e problemas futuros substituindo chamadas de comandos deprecados por `dart run` e mantendo scripts e pipelines (CI) atualizados.

O que fazer (resumo rápido)
- Substitua chamadas antigas como `pub run <package>:<command>` por `dart run <package>:<command>`.
- Atualize scripts de shell, Makefiles, GitHub Actions e configuração de CI para usar `dart run`.
- Garanta que a versão do SDK Dart usada na CI é compatível (compatível com `dart run`).

Exemplos
--------
- Antes (deprecado):
  flutter pub run flutter_launcher_icons:main

- Depois (recomendado):
  dart run flutter_launcher_icons:main

- Em scripts que precisam do Flutter context (por exemplo executar com a versão do Flutter):
  flutter pub get && dart run flutter_launcher_icons:main

Boas práticas para scripts e CI
--------------------------------
- Use comandos idempotentes quando possível (ex.: `dart pub get`/`flutter pub get`) antes de `dart run` para garantir dependências resolvidas.
- Prefira invocar `dart` explicitamente para rodar packages executáveis: `dart run <package>`.
- Em pipelines de CI com Flutter, mantenha a etapa de setup do Flutter (instalar SDK ou usar action/setup-flutter) e, em seguida, use `dart run` para chamar os executáveis.
- Verifique a versão do SDK com `dart --version` no início do job e falhe rápido com uma mensagem clara se a versão for incompatível.

Exemplo de atualização em GitHub Actions (snippet):

```yaml
steps:
  - uses: actions/checkout@v3
  - uses: subosito/flutter-action@v2
    with:
      flutter-version: 'stable'
  - name: Install dependencies
    run: flutter pub get
  - name: Run icon generator
    run: dart run flutter_launcher_icons:main
```

Quando investigar um warning deprecatado
--------------------------------------
1. Leia a mensagem de deprecação — geralmente ela sugere o substituto (ex: `Use 'dart run' instead`).
2. Localize todos os usos no repositório (grep por `pub run` ou pela chamada mencionada).
3. Atualize os scripts e verifique localmente.
4. Atualize documentação e README que contenham comandos antigos.

Checklist rápido
- [ ] Atualizar scripts locais (`scripts/`, `bin/`, `Makefile`)
- [ ] Atualizar CI (GitHub Actions, GitLab CI, Bitrise, Codemagic, etc.)
- [ ] Trocar `flutter pub run` por `dart run` quando aplicável
- [ ] Rodar pipeline localmente para validar

Notas finais
-----------
`dart run` executa executáveis definidos em `pubspec.yaml` e é o fluxo recomendado atualmente. Manter scripts atualizados evita warnings, melhora compatibilidade futura e mantém a base de código mais limpa.

Se quiser, posso:
- localizar e substituir automaticamente ocorrências de comandos deprecados no repositório (fazer commits com as mudanças);
- ou criar um pequeno script que escaneie e liste arquivos que usam comandos deprecados para você revisar.

Nota para agentes/LLMs
----------------------

- Ao gerar ou modificar snippets de teste que chamem APIs marcadas com `@visibleForTesting` (por exemplo `SharedPreferences.setMockInitialValues`), preferir colocar o código real em `test/`.
- Se um snippet for mantido fora de `test/` (ex.: documentação, `prompts/`), inclua localmente a diretiva de análise para silenciar o warning apenas nessa linha:

```dart
// ignore: invalid_use_of_visible_for_testing_member
SharedPreferences.setMockInitialValues({});
```

Isso permite manter exemplos executáveis e evita ruído do analisador quando o código é propositalmente um mock para teste.

Banco de dados - pasta `sqls/` (IMPORTANTE para agentes)
-----------------------------------------------------
O repositório contém uma pasta `sqls/` na raiz que armazena scripts SQL de definição de tabelas e índices usados para sincronização e validação de esquema. Agentes automatizados e revisores devem:

- Sempre verificar `sqls/` (e subpastas) ao avaliar a estrutura do banco de dados.
- Usar os scripts dentro de `sqls/` como fonte de verdade para criar/validar tabelas em ambientes de staging e migrações de testes.
- Para novos modelos de dados, adicionar um script `create_table_<entidade>.sql` na pasta apropriada e atualizar este arquivo de documentação.

Exemplo de localização e uso:

```
sqls/providers/create_table_providers.sql
```

Ao executar avaliações de schema ou sincronizações incrementais, verifique `updated_at` e índices provistos nos scripts para garantir que filtros de sincronização (`updated_at > :last_sync`) funcionem corretamente.

