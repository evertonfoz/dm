# Scripts da pasta `scripts/`

Este arquivo descreve os scripts incluídos na pasta `scripts/` deste repositório, como usá-los, opções disponíveis e recomendações de integração com Git/CI/editors.

Atualmente a pasta contém os seguintes scripts:

- `fix-unused-imports.sh` — automatiza a execução de `flutter pub get` (ou `dart pub get`) e `dart fix --apply` para aplicar correções sugeridas pelo analisador Dart, incluindo a remoção de imports não usados (`unused_import`).

## `fix-unused-imports.sh`

Propósito
- Aplicar automaticamente correções sugeridas pelo analisador Dart/Flutter. O foco principal é remover imports não usados, mas o comando `dart fix --apply` também aplica outras correções seguras (como ordenação de construtores, prefer_const_constructors etc.).

Localização
- `scripts/fix-unused-imports.sh`

Permissões
- Torne o script executável antes do uso (uma vez):

```bash
chmod +x scripts/fix-unused-imports.sh
```

Uso básico

- Modo dry-run (mostra o que seria alterado sem aplicar):

```bash
./scripts/fix-unused-imports.sh --dry-run
```

- Aplicar as correções (modifica arquivos):

```bash
./scripts/fix-unused-imports.sh
```

O que o script faz

1. Navega para a raiz do repositório (diretório pai de `scripts/`).
2. Tenta rodar `flutter pub get`; se o binário `flutter` não estiver disponível, roda `dart pub get`.
3. Executa `dart fix --apply` (ou `dart fix --dry-run` quando solicitado).

Notas e cuidados

- `dart fix --apply` usa as mesmas regras do analisador e é, em geral, seguro. Ainda assim, recomendamos revisar as mudanças antes de commitar (use `git diff`).
- Em projetos monorepo ou com múltiplos pacotes, execute o script na raiz de cada pacote que contenha `pubspec.yaml`.
- O script pressupõe que o `flutter` ou `dart` esteja corretamente instalado e no PATH.

Integração com Git (pré-commit)

Para executar o script automaticamente antes de cada commit, adicione um hook simples em `.git/hooks/pre-commit` (na raiz do repositório):

```bash
#!/bin/sh
# Rodar correções automáticas (colocar --dry-run se preferir revisar antes)
./scripts/fix-unused-imports.sh
# Adicionar quaisquer mudanças geradas pelo script ao commit
git add -A

# Permitir commit continuar
exit 0
```

Torne o hook executável:

```bash
chmod +x .git/hooks/pre-commit
```

Observação: esse hook aplica mudanças automaticamente. Se preferir revisar, use `--dry-run` no hook ou remova `git add -A`.

Integração com CI (ex.: GitHub Actions)

Exemplo simples de job que verifica o projeto em PRs:

```yaml
name: analyze
on: [pull_request]
jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
      - name: Flutter pub get
        run: flutter pub get
      - name: Dart analyze
        run: dart analyze --fatal-infos
```

Se quiser aplicar correções automaticamente no CI (não recomendado em PRs sem revisão), execute `dart fix --apply` e faça commit em um branch de manutenção controlado.

Troubleshooting

- Se o script falhar em `flutter pub get`, verifique sua internet, a versão do Flutter/Dart, e se há restrições de proxy.
- Se `dart fix --apply` remover algo que você precisa (por exemplo, imports usados por geradores), reverta a mudança com `git checkout -- <arquivo>` e, se necessário, marque o arquivo com um ignore (`// ignore: unused_import`) ou ajuste o código para tornar o import referenciado.

Boas práticas

- Sempre revise o `git diff` após rodar o script.
- Combine o uso local (VS Code + pre-commit) com checagens no CI para manter o repositório limpo.

Contribuições

Se quiser adicionar novos scripts à pasta `scripts/`, por favor atualize este `README.md` com:

- nome/do script
- propósito
- exemplos de uso
- quaisquer dependências externas

Licença

Uso livre no contexto deste repositório.
