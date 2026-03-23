# AGENTS — Automação para warnings de import não usado

Objetivo: descrever passos confiáveis e automáticos para detectar e corrigir no projeto o warning:

```
Unused import: 'package:flutter_riverpod/flutter_riverpod.dart'.
Try removing the import directive.
```

Este aviso (unused_import) é reportado pelo analisador Dart/Flutter. A forma recomendada e segura de corrigi-lo em todo o projeto é usar as ferramentas do próprio SDK (`dart fix`) ou as ações/formatters do editor. Abaixo há instruções passo-a-passo, um script pronto e sugestões de integração (pre-commit, CI e VS Code).

## Resumo rápido (contrato)
- Entrada: um projeto Flutter/Dart com warnings de `unused_import`.
- Saída: imports não usados removidos automaticamente pelo analisador, sem alterações manuais nos arquivos.
- Erro: se `dart fix` não puder aplicar uma correção (caso raro), o arquivo permanece inalterado e a saída mostrará o motivo.
- Sucesso: o projeto não deve mais reportar `unused_import` após aplicar o script.

## 1) Método recomendado: `dart fix --apply`

1. Vá para a raiz do projeto (onde está `pubspec.yaml`).
2. Execute (recomendado para Flutter projects):

```bash
# atualiza dependências
flutter pub get
# aplica automaticamente correções sugeridas pelo analisador (inclui remoção de imports não usados)
dart fix --apply
```

3. Opcional: antes de aplicar, verifique o que seria alterado com:

```bash
dart fix --dry-run
```

Observação: `dart fix --apply` aplica uma série de correções automáticas (incluindo `unused_import`). É a maneira mais confiável porque usa as mesmas regras do analisador Dart.

## 2) Script automatizado

Criei um script simples em `scripts/fix-unused-imports.sh` que executa as etapas acima. Torne-o executável com:

```bash
chmod +x scripts/fix-unused-imports.sh
./scripts/fix-unused-imports.sh   # aplica as correções
./scripts/fix-unused-imports.sh --dry-run  # mostra o que seria alterado
```

O script roda `flutter pub get` e `dart fix --apply`, e retorna um código de saída não-zero se ocorrer um erro.

## 3) Integração com Git (pre-commit)

Você pode usar um hook simples para executar o script antes de cada commit. Exemplo de conteúdo para `.git/hooks/pre-commit` (colocar na raiz do repositório):

```bash
#!/bin/sh
# Rodar correções automáticas
./scripts/fix-unused-imports.sh
# Re-adicionar mudanças feitas pelo script
git add -A

# Permitir commit continuar
exit 0
```

Depois torne o hook executável:

```bash
chmod +x .git/hooks/pre-commit
```

Nota: este hook aplica mudanças automaticamente e as adiciona ao commit. Se preferir revisar primeiro, use `--dry-run` no hook ou remova `git add -A`.

## 4) CI / GitHub Actions (checagem recomendada)

Adicione um passo na pipeline para garantir que o repositório não contenha imports não usados. Exemplo (YAML simplificado):

```yaml
# job: analyze
- name: Dart analyze
  run: |
    flutter pub get
    dart analyze --fatal-infos
```

Se preferir aplicar automaticamente (não recomendado em PRs sem revisão), execute `dart fix --apply` no CI e commit automático somente em branches controlados.

## 5) VS Code (ação ao salvar)

Configure o VS Code para aplicar correções e organizar imports ao salvar. No `settings.json` do workspace ou do usuário:

```json
{
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  }
}
```

Isto usa as capacidades do Dart/Flutter extension para aplicar correções (incluindo remoção de imports não usados) automaticamente.

## 6) Android Studio / IntelliJ

- Use Code > Optimize Imports.
- Ou configure uma ação ao salvar/commit (Save Actions plugin) para executar 'Reformat Code' e 'Optimize Imports'.

## 7) Edge cases / observações
- Em alguns casos um import parece 'unused' mas é necessário para anotações, geradores ou reflexões (rare). Se `dart fix` remover algo que você precisa, reverta o commit e marque o arquivo com `// ignore: unused_import` ou reorganize o código para que o import seja referenciado.
- `dart fix` aplica várias correções; sempre faça um `git diff`/`git status` antes de push para revisar alterações automáticas.
- Em monorepos ou múltiplos pacotes, execute o script na raiz de cada pacote.

## 8) Como reportar problemas
Se o script falhar, cole a saída do comando `./scripts/fix-unused-imports.sh --dry-run` e um trecho do arquivo que foi alterado (ou removido) para investigarmos.

---

Arquivo de suporte: `scripts/fix-unused-imports.sh` (ver também o script criado no repositório).

Boa prática: combine uma verificação de `dart analyze` no CI com ações locais (VS Code + pre-commit) — isso mantém o repositório limpo automaticamente.
