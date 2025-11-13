# Prompt: Refatorar fluxo 'Adicionar {ENTITY_SINGULAR}' (dialogs → persistência)

Parâmetros (defina estes valores no início do prompt antes de executar)
---------------------------------------------------------------
- ENTITY_SINGULAR: Fornecedor     # nome singular legível (ex.: 'Fornecedor')
- ENTITY_PLURAL: fornecedores     # nome plural legível em minúsculas (ex.: 'fornecedores')
- DTO_CLASS: ProviderDto         # nome da classe/DTO usada no projeto
- FEATURE_FOLDER: providers      # pasta/feature onde o código vive
- PAGE_FILE: providers_page.dart # arquivo da página que contém o FAB/fluxo
- DIALOG_FILE_HINT: provider_form_dialog.dart # nome esperado do arquivo de diálogo (se existir)
- DAO_CLASS_HINT: ProvidersLocalDaoSharedPrefs # sugestão de nome do DAO local existente

Resumo / Objetivo
---
Criar um prompt que instrua um agente a refatorar o fluxo "Adicionar {ENTITY_SINGULAR}" para separar responsabilidades, melhorar testabilidade e organização da feature. A refatoração deve extrair/centralizar o diálogo de formulário, encapsular a lógica de persistência em um repository/service, e garantir que o comportamento para o usuário permaneça idêntico.

Restrições importantes
---
- Não alterar comportamento observável da UI (textos em pt-BR, validações mínimas, retorno via `Navigator.pop(dto)`, feedback via `SnackBar`, recarregamento da lista, etc.).
- Não introduzir dependências externas sem aprovação.
- Mantendo compatibilidade com o DAO padrão da feature; preferir reutilizar `DAO_CLASS_HINT`.

Por que refatorar
---
- Isolar a UI (diálogo) da lógica de persistência.
- Facilitar testes unitários (repository) e widget tests (diálogo e página).
- Reutilizar diálogo/form em outros pontos da aplicação (editar, detalhes).

Checklist de refatoração (passos recomendados)
---
1. Localize `lib/features/{FEATURE_FOLDER}/presentation/{PAGE_FILE}` e identifique onde o FAB abre o diálogo (ex.: `_showProviderForm`, `showDialog`, helpers `showProviderFormDialog`).
2. Isolar o diálogo de formulário em `dialogs/{DIALOG_FILE_HINT}` se estiver inline.
   - O diálogo deve construir e retornar um `{DTO_CLASS}` via `Navigator.of(context).pop(dto)` após validação mínima.
   - Usar rótulos em português, validação de obrigatoriedade (ex.: name não vazio) e retornar `null` caso o usuário cancele.
3. Criar/atualizar `lib/features/{FEATURE_FOLDER}/infrastructure/providers_repository.dart`:
   - Thin wrapper que delega para o DAO existente (`ProvidersLocalDaoSharedPrefs`) com métodos:
     - `Future<List<{DTO_CLASS}>> listAll()`
     - `Future<void> upsertAll(List<{DTO_CLASS}>)`
     - `Future<void> clear()`
   - Adicionar documentação de uso e facilitar injeção/mocking nos testes.
4. No chamador (página/lista):
   - Substituir chamadas diretas ao DAO por chamadas ao `providers_repository`.
   - Ao receber `result` do diálogo (`final result = await showDialog<{DTO_CLASS}>(...)`), se `result != null` montar `newList` (cópia da lista atual) e persistir via `await repository.upsertAll(newList)` dentro de `try/catch`.
   - Recarregar a fonte de verdade (`await _loadProviders()` ou equivalente) e apresentar `SnackBar` de sucesso/erro.
5. Extrair pequenos helpers de UI para facilitar testes:
   - Uma função para construir o DTO a partir de valores do formulário (pode ser testada unitariamente).
6. Adicionar/atualizar testes:
   - Unit test para `providers_repository` que verifica delegação para o DAO (usar mock/stub).
   - Widget test para o diálogo: abrir o diálogo, preencher campos, confirmar e verificar que o resultado retornado é um DTO válido.
   - Widget test para a página: simular que `listAll` retorna dados, verificar que o FAB chama o diálogo (mockando o diálogo) e que, ao receber um novo DTO, chama `repository.upsertAll`.
7. Executar `dart format` e `flutter analyze` e corrigir issues simples.

Arquivos sugeridos a criar/editar
---
- Criar/Editar: `lib/features/{FEATURE_FOLDER}/dialogs/{DIALOG_FILE_HINT}` — diálogo de formulário (ou reutilizar existente).
- Criar/Editar: `lib/features/{FEATURE_FOLDER}/infrastructure/providers_repository.dart` — wrapper sobre DAO.
- Editar: `lib/features/{FEATURE_FOLDER}/presentation/{PAGE_FILE}` — usar repository e refatorar callbacks para delegar comportamento.
- Criar: `test/features/{FEATURE_FOLDER}/providers_repository_test.dart`
- Criar: `test/features/{FEATURE_FOLDER}/provider_form_dialog_test.dart`
- Criar: `test/features/{FEATURE_FOLDER}/providers_page_integration_test.dart` (opcional, para fluxo end-to-end com mocks).

Detalhes de implementação (pontos a observar)
---
- Validação e UX:
  - O diálogo deve validar campos obrigatórios antes de `Navigator.pop(dto)`.
  - Em caso de erro ao persistir, mostrar `SnackBar('Erro ao salvar {ENTITY_SINGULAR}')` e manter a UI consistente.
- ID e timestamps:
  - Se o DTO precisa de `id` e `updatedAt`, garantir que o diálogo preenche `id` quando estiver adicionando (gerar UUID) e que o repository/DAOs atualize `updatedAt` quando persistir.
- Tratamento de concorrência:
  - Envolver múltiplas operações de persistência em `await` para garantir ordem; usar `setState` apropriadamente para refletir mudanças.
- Reutilização:
  - Permitir que o diálogo seja reutilizado para editar (receber um DTO opcional) e para adicionar (DTO nulo).

Critérios de aceitação
---
1. Ao abrir o diálogo via FAB, preencher e confirmar, o item aparece na lista imediatamente após fechamento do diálogo.
2. Persistência realizada via repository/DAO e `upsertAll` chamada com a lista atualizada (verificável nos testes/padrão de DAO).
3. O diálogo está isolado em `dialogs/{DIALOG_FILE_HINT}` e possui validação mínima e retorno correto via `Navigator.pop(dto)`.
4. Pelo menos 1 unit test (repository) e 1 widget test (dialog) adicionados e passando.
5. `flutter analyze` não apresenta erros relacionados às mudanças.

Mensagem de commit sugerida
---
refactor(providers): extrair provider_form_dialog e providers_repository; adicionar testes para diálogo e repository

Exemplo de prompt para o agent (template)
---
"Você é um agente de código com permissão para editar o repositório. Sua tarefa é refatorar o fluxo 'Adicionar {ENTITY_SINGULAR}' separando o diálogo do page e extraindo um providers_repository que encapsula o DAO local. Preserve todo o comportamento atual e adicione testes mínimos."

Notas finais
---
Se preferir, eu posso aplicar essa refatoração automaticamente: criar os arquivos sugeridos, atualizar a página e adicionar os testes. Diga se deseja que eu gere os patches e rode `flutter analyze` e os testes locais (quando aplicável).
