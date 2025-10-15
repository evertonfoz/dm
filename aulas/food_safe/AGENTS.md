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
