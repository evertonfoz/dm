```markdown
## Prompt: Implementar remoção por swipe (Dismissible)

Objetivo
---
Adicionar a funcionalidade de remoção de providers via swipe-to-dismiss na listagem.

Resumo do comportamento
---
- Envolver cada item da lista em um `Dismissible` com direção `DismissDirection.endToStart`.
- Ao detectar o gesto, chamar `confirmDismiss` que abre um `AlertDialog` de confirmação ("Remover fornecedor? Sim / Não").
- Se o usuário confirmar, chamar o DAO para remover o item (`ProvidersLocalDaoSharedPrefs.remove(id)` ou equivalente) dentro de `try/catch`.
- Em caso de sucesso, exibir `SnackBar` confirmando remoção; em caso de erro, reverter UI (se necessário) e exibir `SnackBar` de erro.
- Manter a listagem principal (arquivo listing-only) sem lógica de remoção — este prompt entrega apenas o patch que adiciona a camada `Dismissible` e a integração com o DAO.

Integração e convenções
---
- Implementar em `lib/features/{FEATURE_FOLDER}/presentation/widgets/provider_list_view.dart` ou num arquivo de patch que altera o widget de listagem existente.
- Não criar novos repositórios; use o DAO local existente quando disponível.
- Garantir acessibilidade e animação suave (usando `background` e `secondaryBackground` do `Dismissible`).
 - Implementar em `lib/features/{FEATURE_FOLDER}/presentation/widgets/provider_list_view.dart` ou num arquivo de patch que altera o widget de listagem existente.
 - Não criar novos repositórios; use o DAO local existente quando disponível.
 - Garantir acessibilidade e animação suave (usando `background` e `secondaryBackground` do `Dismissible`).
 - Importante: o diálogo de confirmação deve ser não-dismissable ao tocar fora (use `showDialog(..., barrierDismissible: false)`) para evitar remoções acidentais — o usuário só deve poder confirmar/cancelar pelos botões.

Critérios de aceitação
---
1. Swipe para esquerda exibe confirmação e remove o provider ao confirmar.
2. Persistência é realizada via DAO e erros são tratados com `SnackBar`.
3. Não introduz comportamento de edição ou seleção — somente remoção.

```
