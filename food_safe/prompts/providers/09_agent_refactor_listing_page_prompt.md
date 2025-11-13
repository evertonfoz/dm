# Prompt: Refatorar listagem de fornecedores (providers)

Parâmetros (defina estes valores no início do prompt antes de executar)
---------------------------------------------------------------
- ENTITY_SINGULAR: Fornecedor        # nome singular legível (ex.: 'Fornecedor')
- ENTITY_PLURAL: fornecedores        # nome plural legível em minúsculas (ex.: 'fornecedores')
- DTO_CLASS: ProviderDto            # nome da classe/DTO usada no projeto
- FEATURE_FOLDER: providers         # pasta/feature onde o código vive
- PAGE_FILE_HINT: providers_page.dart # arquivo alvo de refactor (ex.: providers_page.dart)
- DAO_CLASS_HINT: ProvidersLocalDaoSharedPrefs # sugestão de nome do DAO local existente

Resumo / Objetivo
---
Você é um agente que vai criar um plano de refatoração e executar (gerar patchs) para reorganizar o código responsável pela listagem de provedores, preservando completamente o comportamento atual exposto na UI e na persistência. O objetivo é melhorar a legibilidade, modularidade e testabilidade do código, extraindo widgets, isolando acesso ao DAO, documentando as mudanças e adicionando testes mínimos (unit/widget) quando aplicável.

Regras gerais e restrições
---
- Não alterar comportamento observável da UI (fluxo, textos em pt-BR, mensagens, animações, interações: pull-to-refresh, swipe-to-delete, FAB, diálogos, etc.).
- Fazer mudanças regressivas e pequenas por arquivo — preferir extrair e compor em novos arquivos ao invés de reescrever grandes blocos.
- Preservar nomes/padrões do repositório (pastas/features, idioma, DTO_CLASS, DAO naming). Importar e reutilizar DAO existente (`DAO_CLASS_HINT`) ao invés de criar novas implementações de persistência.
- Todo acesso a IO/persistência deve permanecer envolvido em try/catch e exibir `SnackBar` em caso de erro.
- Não introduzir dependências externas novas sem justificar; preferir reutilizar utilitários existentes do projeto.

Por que refatorar (benefícios esperados)
---
- Separar responsabilidades: UI (widgets) vs lógica de dados (service/repository) vs apresentação.
- Melhorar cobertura de testes com pequenos testes unitários e widget tests.
- Facilitar reutilização de componentes (ex.: item da lista, FAB area, dialog forms).

Checklist de refatoração (passos recomendados)
---
1. Analisar `lib/features/{FEATURE_FOLDER}/presentation/{PAGE_FILE_HINT}` para identificar responsabilidades misturadas (ex.: carregamento/DAO, estado, UI detalhada).
2. Extrair componentes visuais em arquivos separados dentro de `presentation/`:
   - `provider_list_view.dart` — widget que monta a lista e refresh indicator;
   - `provider_list_item.dart` — widget para renderizar cada item (imagem, nome, rating, distance_km, ações);
   - `providers_fab_area.dart` (se já existir, reaproveitar) — área de FAB e opt-out tutorial;
   - `provider_tutorial_overlay.dart` — componente para o tutorial/onboarding (separe do page);
3. Integração com persistência (regra importante)
- Use EXCLUSIVAMENTE o DAO local já existente em `lib/features/{FEATURE_FOLDER}/infrastructure/local/` (por exemplo `ProvidersLocalDaoSharedPrefs`).
- Não criar novos wrappers/repositórios que dupliquem a camada de persistência. Se o projeto já possuir um padrão de repositório lógico e for explicitamente necessário integrá-lo, adapte o trabalho a esse padrão; caso contrário, mantenha chamadas diretas ao DAO ou adapte a page para receber o DAO (injeção por construtor) para facilitar testes.
- Todos os acessos a IO/persistência devem ser encapsulados em métodos privados na página ou em uma pequena camada de service já existente no projeto (mas sem criar novos arquivos de repository se eles não forem parte das convenções do repo).
4. Converter trechos longos de `setState`/manipulação em métodos privados curtos com nomes explícitos (ex.: `_loadProviders`, `_removeProviderAtIndex`, `_onProviderTapped`, `_showProviderForm`). Mantê-los com tratamento de erro e feedback.
5. Garantir separação entre criação de dialogs/helpers e a página: mover `showProviderFormDialog`/`showProviderDetailsDialog` para `dialogs/` (reutilizar se já existirem).
6. Adicionar testes mínimos:
   - Unit test para `providers_repository` que verifica que chama o DAO esperado (mock/stub) — por exemplo, `listAll` retorna lista mockada.
   - Widget test para `provider_list_view` que assegura que o widget mostra um loader inicial e depois a lista quando `listAll` retorna dados; e que o `Dismissible` chama remoção.
7. Executar `flutter analyze` e corrigir problemas de lint/format simples.
8. Documentar as mudanças com um breve comentário no topo dos arquivos novos/modificados e gerar uma mensagem de commit clara (ex: "refactor(providers): extract list item, repository and add tests").

Arquivos sugeridos a criar/editar
---
- Editar: `lib/features/{FEATURE_FOLDER}/presentation/{PAGE_FILE_HINT}` — reduzir para composição (delegar para os widgets extraídos e o repository).
- Criar: `lib/features/{FEATURE_FOLDER}/presentation/provider_list_view.dart`
- Criar: `lib/features/{FEATURE_FOLDER}/presentation/provider_list_item.dart`
- Criar (se necessário): `lib/features/{FEATURE_FOLDER}/presentation/provider_tutorial_overlay.dart`
- Usar/Referenciar: `lib/features/{FEATURE_FOLDER}/infrastructure/local/providers_local_dao_shared_prefs.dart` (ou o DAO equivalente já existente)
- Criar: `test/features/{FEATURE_FOLDER}/providers_repository_test.dart`
- Criar: `test/features/{FEATURE_FOLDER}/provider_list_view_test.dart`

Orientações de implementação (detalhes importantes)
---
- UI/UX:
  - Preserve textos em português e mensagens de `SnackBar` existentes (ex.: 'Fornecedor removido com sucesso', 'Erro ao carregar fornecedores').
  - Mantenha `RefreshIndicator` e comportamento de pull-to-refresh.
  - Preserve `Dismissible` com confirmação via `AlertDialog`.
  - Preserve tratamento de imagem com `Image.network` + `errorBuilder`/`loadingBuilder`.
  - Mantenha exibição formatada de `rating` (uma casa decimal) e `distance_km` quando presente.
- Estado e lifecycle:
  - Continue usando `StatefulWidget` onde necessário; extraia widgets stateless sempre que possível.
  - Preserve chamadas `initState`/`dispose` (por exemplo, `AnimationController` usado para FAB) — se extraído, forneça forma de receber o controller por parâmetro ou encapsular a animação no `ProvidersFabArea` existente.
- Integração com DAO:
  - Não reescrever a persistência; use o DAO padrão detectado (ex.: `ProvidersLocalDaoSharedPrefs`).
  - Encapsule chamadas ao DAO no `providers_repository` para facilitar testes (mock do repository nos widget tests).
- Testes:
  - Nos testes, mock o repository/DAO para controlar retornos de `listAll` e validar chamadas a `upsertAll`.
  - Para widget tests, use `pumpWidget` com `MaterialApp` e prover o repository via injeção simples (constructor param) ou por `Provider`/injection se o projeto usar uma solução específica.

Critérios de aceitação (definição clara de pronto)
---
1. O comportamento da UI é idêntico ao observado antes da refatoração (mesmos textos, interações e feedbacks visuais), verificado manualmente com um run local rápido.
2. Código reorganizado em componentes claros (page + list_view + list_item + repository) com responsabilidades separadas.
3. Pelo menos 1 unit test para o repository e 1 widget test cobrindo o fluxo de carregamento e remoção da lista foram adicionados e passam.
4. `flutter analyze` e `flutter test` (os testes adicionados) rodem sem erros para as alterações introduzidas.
5. Mensagem de commit explicativa e comentários nos arquivos novos explicando o propósito das extrações.

Exemplo de mensagem de commit sugerida
---
refactor(providers): extrair provider_list_item, provider_list_view e providers_repository; adicionar testes

Notas finais / recomendações
---
- Faça refactors incrementais e abra PRs pequenos — cada extração pode ser um commit separado (ex.: extrair item da lista; extrair repository; adicionar testes).
- Se o projeto já tiver padrões de injeção ou uma camada de domain, prefira adaptar a integração do `providers_repository` a esse padrão (ex.: use service locator, provider, ou injeção via construtor conforme a base existente).
- Se quiser, eu posso gerar os patches (arquivos novos/alterados e testes) a partir deste prompt para aplicar diretamente no repositório — me diga se devo prosseguir e eu crio as mudanças.
# Agent prompt: Refatorar página de listagem (extrair widgets e organizar estrutura)

Parâmetros (defina estes valores no início do prompt antes de executar)
---------------------------------------------------------------
- ENTITY_SINGULAR: Fornecedor  # nome singular legível (ex.: 'Fornecedor')
- ENTITY_PLURAL: fornecedores    # nome plural legível em minúsculas (ex.: 'fornecedores')
- DTO_CLASS: ProviderDto        # nome da classe/DTO usada no projeto (ex.: 'ProviderDto')
- FEATURE_FOLDER: providers     # pasta/feature onde o código vive (ex.: 'providers')
- PAGE_FILE: providers_page.dart  # nome do arquivo da página de listagem (ex.: 'providers_page.dart')

OBS: Substitua os tokens acima antes de enviar o prompt ao agente ou forneça esses valores na invocação.

Objetivo
--------
Escrever um prompt reutilizável que instrua um agente (LLM-based code agent) a refatorar, em qualquer projeto Flutter/Dart, a página de listagem que contém o FAB (FloatingActionButton) para adicionar novos itens. A refatoração deve:

- Extrair componentes visuais em widgets separados e reutilizáveis.
- Organizar a estrutura de arquivos em subpastas apropriadas dentro da feature.
- Manter a funcionalidade existente intacta.
- Melhorar a manutenibilidade e testabilidade do código.

Requisitos do prompt
--------------------
1. O agente deve primeiro inspecionar a estrutura do projeto para localizar os pontos relevantes:
   - Arquivo principal da página de listagem (procure por `{PAGE_FILE}`, `{FEATURE_FOLDER}_page.dart`, ou caminhos como `lib/features/{FEATURE_FOLDER}/presentation/{PAGE_FILE}`).
   - Estrutura atual de widgets dentro da página (AppBar, body, FAB, lista, cards/items, estados vazios, loading, etc.).
   - Diálogo/modal de adição já implementado (se existir, conforme prompt anterior).
   - Pasta da feature e estrutura de subpastas existente (ex.: `presentation/`, `widgets/`, `components/`).

2. Componentes que devem ser extraídos (lista não exaustiva, adaptar ao projeto):
   - **AppBar customizado**: Se a AppBar tiver customizações (título dinâmico, actions, estilos), extrair para `{entity}_app_bar.dart` ou `{feature}_app_bar.dart`.
   - **Item da lista**: O widget que representa cada item/card da lista (ex.: `ListTile`, `Card`, widget customizado) → extrair para `{entity}_list_item.dart`.
   - **Estado vazio**: Widget exibido quando a lista está vazia (ilustração, texto, botão) → extrair para `empty_{entity}_state.dart` ou `empty_state_widget.dart`.
   - **Estado de loading**: Widget/indicador de carregamento → pode usar `CircularProgressIndicator` diretamente ou extrair se houver customização.
   - **FloatingActionButton**: Se o FAB tiver lógica/customização complexa, extrair callback e configuração para método privado ou widget wrapper.
   - **Lista de itens**: O `ListView.builder` ou `ListView.separated` pode ser extraído para um widget `{entity}_list_view.dart` que recebe a lista e callbacks.

3. Estrutura de pastas sugerida (o agente deve criar conforme necessidade):
   ```
   lib/features/{FEATURE_FOLDER}/
   ├── presentation/
   │   ├── {PAGE_FILE}                    # arquivo principal da página (simplificado)
   │   ├── widgets/                        # pasta para widgets específicos da feature
   │   │   ├── {entity}_app_bar.dart
   │   │   ├── {entity}_list_item.dart
   │   │   ├── {entity}_list_view.dart
   │   │   ├── empty_{entity}_state.dart
   │   │   └── (outros widgets extraídos)
   │   └── dialogs/                        # pasta para diálogos (se existir)
   │       └── {entity}_form_dialog.dart
   ```
   
   **Nota**: Se a estrutura do projeto já tiver convenção diferente (ex.: `components/`, `ui/`), o agente deve seguir a convenção existente.

4. Boas práticas que o agente deve aplicar automaticamente:
   - Cada widget extraído deve ser stateless quando possível, recebendo dados e callbacks via construtor.
   - Usar `const` constructors sempre que os widgets forem imutáveis.
   - Manter nomes de arquivo em snake_case e classes em PascalCase (convenção Dart/Flutter).
   - Documentar cada widget extraído com comentário breve explicando seu propósito.
   - Garantir que imports sejam relativos e organizados (package imports primeiro, depois relativos).
   - Não alterar lógica de negócio ou comportamento, apenas reorganizar estrutura visual.
   - Preservar tratamento de estados (loading, empty, error, success).
   - Manter acessibilidade e semantics quando presentes.

5. Etapas concretas que o agente deve seguir (lista de verificação):
   - [ ] Localizar o arquivo da página de listagem (`{PAGE_FILE}`) na pasta `lib/features/{FEATURE_FOLDER}/presentation/`.
   - [ ] Analisar a estrutura atual da página e identificar todos os widgets candidatos para extração (AppBar, itens de lista, estados vazios, FAB, etc.).
   - [ ] Criar subpasta `widgets/` dentro de `presentation/` se não existir (ou usar convenção existente do projeto).
   - [ ] Extrair o widget de item da lista para arquivo `{entity}_list_item.dart`:
     - Receber o DTO (`{DTO_CLASS}`) via construtor.
     - Receber callbacks opcionais (onTap, onEdit, onDelete) se aplicável.
     - Manter estilos, layout e comportamento idênticos ao original.
   - [ ] Extrair o widget de estado vazio para arquivo `empty_{entity}_state.dart`:
     - Pode receber mensagem customizada via construtor ou usar padrão.
     - Incluir ilustração/ícone e texto explicativo.
     - Opcionalmente receber callback para ação (ex.: botão "Adicionar primeiro {ENTITY_SINGULAR}").
   - [ ] Extrair a lista de itens para `{entity}_list_view.dart`:
     - Receber `List<{DTO_CLASS}>` via construtor.
     - Receber callbacks necessários (onItemTap, onItemEdit, onItemDelete).
     - Usar o widget de item extraído anteriormente.
     - Manter separadores, padding, scroll behavior.
   - [ ] Se AppBar tiver customizações, extrair para `{entity}_app_bar.dart` implementando `PreferredSizeWidget`.
   - [ ] Atualizar o arquivo principal da página (`{PAGE_FILE}`) para:
     - Importar os novos widgets extraídos.
     - Simplificar o método `build()` usando os widgets extraídos.
     - Manter toda lógica de estado, carregamento, persistência e callbacks.
     - Garantir que a página ainda funcione exatamente como antes.
   - [ ] Verificar se há diálogo de adição/edição e, se estiver inline na página, mover para `dialogs/{entity}_form_dialog.dart`.
   - [ ] Executar `dart format .` na pasta da feature para garantir formatação consistente.
   - [ ] Executar `flutter analyze` e corrigir quaisquer warnings/erros introduzidos.
   - [ ] Testar manualmente a página para garantir que tudo funciona (abrir, listar, adicionar, interagir com itens).

6. Perguntas que o agente pode fazer (se necessário):
   - Qual convenção de pastas usar para widgets? (preferir `widgets/` ou seguir existente no projeto).
   - Extrair também diálogos para subpasta `dialogs/`?
   - Há componentes compartilhados que devem ir para `lib/shared/` ou `lib/widgets/` globais?
   - Manter ou remover comentários antigos no código original?

7. Itens obrigatórios de saída (artefatos que o agent deve produzir):
   - Arquivos de widgets extraídos criados na estrutura de pastas apropriada.
   - Arquivo principal da página (`{PAGE_FILE}`) refatorado e simplificado.
   - Imports atualizados e organizados.
   - Código formatado e sem warnings de análise.
   - Mensagem de commit / resumo das mudanças explicando a refatoração.
   - Breve documentação dos widgets criados (pode ser comentário no início de cada arquivo).

8. Critérios de aceitação (quando considerar a tarefa concluída):
   - A página de listagem funciona exatamente como antes da refatoração.
   - O código está organizado em widgets pequenos, reutilizáveis e testáveis.
   - Cada widget tem responsabilidade única e clara.
   - A estrutura de pastas está organizada e fácil de navegar.
   - Não há warnings do analisador relacionados às mudanças.
   - O código está formatado seguindo convenções Dart/Flutter.
   - É possível reutilizar os widgets extraídos em outras partes do app (quando aplicável).

Exemplo de prompt para o agent (use este texto como template para executar a tarefa):

"Você é um agente de código com permissão para editar o repositório. Sua tarefa é refatorar a página de listagem de {ENTITY_PLURAL} extraindo componentes visuais para widgets separados e organizando a estrutura de arquivos.

Primeiro, inspecione o projeto e localize:
- O arquivo principal da página de listagem (`{PAGE_FILE}` na pasta `lib/features/{FEATURE_FOLDER}/presentation/`).
- A estrutura atual de widgets dentro da página (AppBar, ListView, itens, FAB, estados vazios/loading).
- A estrutura de pastas da feature e convenções de organização do projeto.

Execute a refatoração seguindo estas diretrizes:

1. **Criar estrutura de pastas**: Dentro de `lib/features/{FEATURE_FOLDER}/presentation/`, criar subpasta `widgets/` (se não existir).

2. **Extrair widget de item da lista**:
   - Criar arquivo `widgets/{entity}_list_item.dart`.
   - Widget deve receber `{DTO_CLASS}` e callbacks opcionais (onTap, onEdit, onDelete).
   - Usar `const` constructor quando possível.
   - Manter layout e estilos idênticos ao original.

3. **Extrair widget de estado vazio**:
   - Criar arquivo `widgets/empty_{entity}_state.dart`.
   - Incluir ícone/ilustração e mensagem "Nenhum {ENTITY_SINGULAR} cadastrado" (ou similar).
   - Opcionalmente receber callback para ação.

4. **Extrair lista de itens**:
   - Criar arquivo `widgets/{entity}_list_view.dart`.
   - Receber `List<{DTO_CLASS}>` e callbacks necessários.
   - Usar o widget de item extraído anteriormente.
   - Manter comportamento de scroll, separadores, etc.

5. **Refatorar página principal**:
   - Importar widgets extraídos.
   - Simplificar método `build()` usando os novos widgets.
   - Manter toda lógica de estado, carregamento e callbacks.
   - Organizar imports (packages primeiro, depois relativos).

6. **Validar e formatar**:
   - Executar `dart format .` na pasta da feature.
   - Executar `flutter analyze` e corrigir warnings.
   - Testar manualmente a funcionalidade completa.

Garanta que:
- Nenhuma funcionalidade seja perdida ou alterada.
- Widgets sejam imutáveis e recebam dados via construtor.
- Código siga convenções Dart/Flutter (snake_case para arquivos, PascalCase para classes).
- Cada arquivo extraído tenha comentário breve explicando seu propósito.
- A página principal fique significativamente mais simples e legível.

Ao concluir, forneça:
- Lista de arquivos criados/modificados.
- Resumo das mudanças para mensagem de commit.
- Breve guia de como os novos widgets podem ser reutilizados."

Notas finais
-----------
Este prompt é genérico e projetado para ser aplicável a projetos Flutter/Dart que seguem a arquitetura feature-based. O agente deve adaptar nomes, caminhos e estrutura de pastas ao projeto concreto, respeitando convenções existentes.

A refatoração deve ser puramente estrutural, mantendo 100% da funcionalidade e comportamento originais. O objetivo é melhorar organização, legibilidade e manutenibilidade sem introduzir bugs ou mudanças de comportamento.
