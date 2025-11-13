```markdown
## Prompt: Implementar seleção de item com diálogo de ações (Editar / Remover / Fechar)

Objetivo
---
Adicionar um fluxo de seleção de item que, ao selecionar um provider (por exemplo long-press ou tap em área específica), exibe um diálogo com ações: Editar, Remover, Fechar.

Resumo do comportamento
---
- O diálogo de seleção contém três ações: Editar (abre o formulário de edição), Remover (abre confirmação de remoção) e Fechar (fecha o diálogo).
- A ação Editar deve delegar ao prompt/handler de edição (usar `showProviderFormDialog` quando disponível).
- A ação Remover deve delegar ao prompt/handler de remoção (abrir `AlertDialog` de confirmação e remover via DAO).
- O código deste prompt deve apenas adicionar o diálogo e as rotas de delegação — a lógica fina de edição/removal permanece nos prompts especializados.

Integração e convenções
---
- Criar o diálogo em `lib/features/{FEATURE_FOLDER}/presentation/dialogs/provider_actions_dialog.dart` ou como helper reutilizável.
- Não implemente diretamente a persistência aqui — invoque os helpers já existentes ou as funções de callback fornecidas pelo widget de listagem.
- Labels e textos em português.
 - Criar o diálogo em `lib/features/{FEATURE_FOLDER}/presentation/dialogs/provider_actions_dialog.dart` ou como helper reutilizável.
 - Não implemente diretamente a persistência aqui — invoque os helpers já existentes ou as funções de callback fornecidas pelo widget de listagem.
 - Labels e textos em português.
 - Importante: o diálogo de ações deve ser não-dismissable ao tocar fora. Use `showDialog(..., barrierDismissible: false)` para garantir que apenas os botões internos possam fechá-lo.

Critérios de aceitação
---
1. Selecionar um item (tap longo ou ação definida) exibe um diálogo com as três opções.
2. Cada opção delega corretamente: Editar -> abre formulário; Remover -> abre confirmação; Fechar -> fecha.
3. Este prompt não implementa a lógica de remoção por swipe nem altera os itens para mostrar ícones de edição; fica restrito ao diálogo de ações.

```
