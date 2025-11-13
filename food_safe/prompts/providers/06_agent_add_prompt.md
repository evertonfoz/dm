# Agent prompt: Implementar fluxo "Adicionar {ENTITY_SINGULAR}" (dialog → persistência local)

Parâmetros (defina estes valores no início do prompt antes de executar)
---------------------------------------------------------------
- ENTITY_SINGULAR: Fornecedor  # nome singular legível (ex.: 'Fornecedor')
- ENTITY_PLURAL: fornecedores    # nome plural legível em minúsculas (ex.: 'fornecedores')
- DTO_CLASS: ProviderDto        # nome da classe/DTO usada no projeto (ex.: 'ProviderDto')
- FEATURE_FOLDER: providers     # pasta/feature onde o código vive (ex.: 'providers')
 - DAO_HINT: providers_local_dao  # sugestão/nome parcial de arquivo DAO (ex.: 'providers_local_dao')

OBS: Substitua os tokens acima antes de enviar o prompt ao agente ou forneça esses valores na invocação.

Objetivo
--------
Escrever um prompt reutilizável que instrua um agente (LLM-based code agent) a implementar, em qualquer projeto Flutter/Dart, o fluxo completo onde:

- O usuário abre um formulário (diálogo/modal) via um botão (por exemplo, FloatingActionButton).
- Ao confirmar (botão "Adicionar"/"Salvar") o diálogo constrói um DTO/entidade e retorna esse objeto ao chamador via `Navigator.pop(dto)`.
- O chamador (página/lista) recebe o DTO e persiste a lista completa usando a implementação local disponível (por exemplo, um DAO que grava em SharedPreferences ou outro backend local).

Requisitos do prompt
--------------------
1. O agente deve primeiro inspecionar a estrutura do projeto para localizar os pontos relevantes:
   - UI que contém o FAB ou botão que abre o diálogo (procure por `FloatingActionButton`, `onPressed: () => _show...`, `showDialog`, strings como "Novo {ENTITY_SINGULAR}" ou similares).
   - Atenção: as ocorrências acima podem usar o nome da feature/pasta; procure por `"{ENTITY_SINGULAR}"`, `"{ENTITY_PLURAL}"`, `DTO_CLASS` e também por `FEATURE_FOLDER`.
   - Implementação atual do diálogo (se existir) ou gerar um `AlertDialog`/`Dialog`/`BottomSheet` apropriado em português.
   - Implementação(s) de persistência local (procure por arquivos DAO, classes com nomes que contenham `LocalDao`, `SharedPrefs`, `sqflite`, `{DAO_HINT}`, ou `persistence`).

2. Implementação desejada do fluxo (contrato breve):
   - Inputs: valores do formulário (nome, nota/atributos numéricos, URL opcional, etc.).
   - Output: um DTO/entidade preenchido com `id` e `updated_at` (ou equivalente) retornado ao chamador (use a classe `{DTO_CLASS}` se existir no projeto).
   - Persistência: O chamador deve montar a lista atualizada (cópia de lista existente + novo/atualizado item) e chamar a API do DAO local (por exemplo `upsertAll(List<{DTO_CLASS}>)` ou método equivalente) para salvar a lista inteira.
   - Feedback UX: ao salvar com sucesso, recarregar a lista e exibir um `SnackBar` de confirmação; em caso de erro, exibir `SnackBar` de erro.

3. Boas práticas que o agente deve aplicar automaticamente:
   - Não alterar código não relacionado; favor fazer mudanças mínimas e bem justificadas.
   - Envolver operações de IO (persistência) em `try/catch` e logar/mostrar erro ao usuário.
   - Preservar estilos e convenções do projeto (idioma, nomes, formatação).
   - Adicionar pequenos testes unitários/widget quando possível (por exemplo, teste que chama o diálogo e verifica que a DAO foi chamada). Se não houver infra de testes no projeto, documentar o que seria testado.
   - Se o projeto usa injeção de dependência, preferir injetar o DAO em vez de instanciá-lo diretamente; caso contrário, instanciar onde já está sendo utilizado no código existente.

4. Etapas concretas que o agente deve seguir (lista de verificação):
   - [ ] Localizar a página/arquivo que lista/mostra {ENTITY_PLURAL} e o FAB (ex.: `{FEATURE_FOLDER}_page.dart` ou `lib/features/{FEATURE_FOLDER}/presentation/{FEATURE_FOLDER}_page.dart`).
   - [ ] Localizar/abrir o diálogo existente ou criar um novo arquivo `entity_form_dialog.dart` no mesmo módulo se não existir. O diálogo deve usar os rótulos em português com o nome `{ENTITY_SINGULAR}`.
   - [ ] Assegurar que o diálogo retorna um DTO via `Navigator.of(context).pop(dto)` apenas quando a validação mínima passar (por exemplo, `name` não vazio). Use a classe `{DTO_CLASS}` para tipagem quando aplicável.
   - [ ] No chamador, após `final result = await showDialog<{DTO_CLASS}>(...)`, se `result != null` montar `newList` (cópia de lista existente) e persistir via DAO local (usar o método existente, tipicamente `upsertAll` ou `saveAll`).
   - [ ] Envolver a chamada de persistência em `try/catch` e mostrar `SnackBar` apropriado. Recarregar fonte de verdade após salvar (por exemplo, `await _load{ENTITY_PLURAL.capitalize()}()` ou chamar `listAll()` novamente). Se não houver função com este nome, chame a função de load já presente na página.
   - [ ] Atualizar/Adicionar pequenos comentários/docstring explicando a alteração.

5. Perguntas que o agente pode fazer (se necessário):
   - Que nome de DTO/classe usar? (o agente deve preferir a classe existente com o mesmo domínio, ex: `ProviderDto`).
   - Onde preferir salvar testes/fixes? (manter arquivos na mesma pasta de features/presentation/infrastructure).

6. Itens obrigatórios de saída (artefatos que o agent deve produzir):
   - Código modificado/criado implementando o diálogo (se ausente) e a lógica pós-dialog que persiste via DAO.
   - Mensagem de commit / resumo das mudanças (se o agente tem permissão para commitar).
   - Um pequeno snippet de como testar manualmente (passos rápidos) e, se possível, um teste automatizado mínimo.

7. Critérios de aceitação (quando considerar a tarefa concluída):
   - Ao clicar no FAB e preencher o formulário, o item aparece na lista imediatamente após fechar o diálogo.
   - O armazenamento local (SharedPreferences ou outra implementação encontrada) contém o item persistido.
   - Operações de persistência têm tratamento de erro e feedback ao usuário.

Exemplo de prompt para o agent (use este texto como template para executar a tarefa):

"Você é um agente de código com permissão para editar o repositório. Sua tarefa é implementar o fluxo 'Adicionar {ENTITY_SINGULAR}' da UI à persistência local. Primeiro, inspecione a árvore do projeto e encontre:

- a página/lista de {ENTITY_PLURAL} e o FAB que abre o diálogo;
- a implementação de persistência local disponível (DAO/SharedPreferences/SQLite);

Se já existir um diálogo que retorna um DTO via `Navigator.pop(dto)`, adapte o chamador para que, ao receber o `result`:

1) monte `newList` (cópia de lista atual + novo/atualizado item),
2) chame o método de persistência existente (por exemplo `upsertAll(newList)`) dentro de `try/catch`,
3) em caso de sucesso, recarregue a lista da fonte de verdade e mostre `SnackBar('{ENTITY_SINGULAR} adicionado com sucesso')`,
4) em caso de erro, mostre `SnackBar('Erro ao salvar {ENTITY_SINGULAR}')` e faça log do erro.

Se não existir diálogo, crie um `AlertDialog` (ou arquivo `entity_form_dialog.dart`) com campos comuns (nome, nota, distância, url imagem), validação mínima e retorno do DTO via `Navigator.pop(dto)`. Garanta que o código segue as convenções do projeto (idioma português, nomes das classes existentes) e adicione testes mínimos quando possível."

Notas finais
-----------
Este prompt é genérico e projetado para ser aplicável a projetos Flutter/Dart que seguem a arquitetura feature-based. O agente deve adaptar nomes e caminhos ao projeto concreto, preferindo classes/DAOs já existentes.
