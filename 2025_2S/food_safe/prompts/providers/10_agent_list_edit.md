```markdown
## Prompt: Implementar edição de provider (ícone lápis)

Objetivo
---
Gerar código Flutter/Dart que adicione a funcionalidade de edição a itens da listagem de providers.

Resumo do comportamento esperado
---
- Cada item da lista (renderizado no widget de listagem) deverá exibir um ícone de lápis (edit) quando pertinente.
- Ao tocar no ícone de lápis, abrir um formulário em diálogo (`AlertDialog` ou helper existente `showProviderFormDialog`) preenchido com os dados atuais do provider.
- O formulário deve permitir editar campos (nome, contato, endereço, taxId, imagem etc.) seguindo os campos do DTO (`{DTO_CLASS}`).
- Ao confirmar, chamar o DAO apropriado (ex.: `ProvidersLocalDaoSharedPrefs.upsert`/`upsertAll`) para persistir a alteração dentro de `try/catch`.
- Exibir `SnackBar` de sucesso ou erro conforme o resultado.
- Não implementar remoção nem swipe neste prompt; apenas edição.

Integração e convenções
---
- Reutilize helpers existentes se detectados: `showProviderFormDialog`, `ProvidersFabArea`, `ProviderDto`.
- Local de criação/edição: `lib/features/{FEATURE_FOLDER}/presentation/widgets/` (ou um arquivo de dialog em `presentation/dialogs/`).
- Nomes e labels em português.
- Código deve seguir o padrão do repositório: tratamento de erros com `try/catch`, feedback via `SnackBar`, e não criar wrappers de persistência se já existir DAO.
 - Reutilize helpers existentes se detectados: `showProviderFormDialog`, `ProvidersFabArea`, `ProviderDto`.
 - Local de criação/edição: `lib/features/{FEATURE_FOLDER}/presentation/widgets/` (ou um arquivo de dialog em `presentation/dialogs/`).
 - Nomes e labels em português.
 - Código deve seguir o padrão do repositório: tratamento de erros com `try/catch`, feedback via `SnackBar`, e não criar wrappers de persistência se já existir DAO.
 - Importante: o diálogo de edição não deve ser fechado ao tocar fora; use `showDialog(..., barrierDismissible: false)` ou o equivalente do helper para garantir que apenas os botões fechem o diálogo.

Exemplo de API esperada do DAO
---
- `Future<void> upsert(ProviderDto dto)` ou `Future<void> upsertAll(List<ProviderDto> dtos)`

Critérios de aceitação
---
1. O ícone de edição aparece em cada item (quando aplicável).
2. Tocar no ícone abre o formulário pré-preenchido.
3. Ao salvar, os dados são persistidos e o usuário vê um `SnackBar` de confirmação.
4. O código não altera o widget de listagem para adicionar remoção por swipe (isso é responsabilidade de outro prompt).

```
