# Prompt 06 — Integrar Home com a página de listagem

Objetivo
--------
Gere uma alteração no arquivo indicado pelo parâmetro `home_file_path` para que a página `HomePage` passe a usar a página de listagem criada pelo aluno (por exemplo: `ProvidersPage` ou `EntityListPage`). O gerador deve usar exclusivamente os caminhos e nomes fornecidos via parâmetros — não inserir caminhos hardcoded ou assumir localizações por convenção. O gerador deve atualizar apenas o arquivo informado em `home_file_path`: inserir o import fornecido em `listing_import_path`, declarar a `GlobalKey` com o tipo apropriado, instanciar a página de listagem no corpo do `Scaffold` (usando a key) e garantir que as chamadas existentes que reexibem o tutorial (`showTutorialAgain`) apontem para o método correto no state do widget de listagem.

Parâmetros (obrigatórios)
-------------------------
- `home_file_path` (string): caminho relativo do arquivo `HomePage` a ser alterado. Exemplo padrão: `lib/features/home/home_page.dart`.
- `listing_import_path` (string): caminho de import da página de listagem (ex.: `package:meu_app/features/providers/presentation/entity_list_page.dart` ou `../providers/presentation/providers_page.dart`).
- `listing_widget_name` (string): nome do widget de listagem a ser usado como body do `HomePage` (ex.: `ProvidersPage` ou `EntityListPage`).
- `listing_state_class` (string): nome da classe State do widget de listagem, usado como tipo da `GlobalKey` (ex.: `ProvidersPageState`).
- `tutorial_method_name` (string, opcional): nome do método público no State da página de listagem que reexibe o tutorial. Padrão: `showTutorialAgain`.

Regras importantes
------------------
1. O gerador deve modificar APENAS o arquivo apontado por `home_file_path`. Não criar novos arquivos.
2. Inserir (ou atualizar) o import usando exatamente o valor de `listing_import_path`.
3. Declarar uma `final GlobalKey<LISTING_STATE_CLASS> _listingKey = GlobalKey<LISTING_STATE_CLASS>();` na `_HomePageState`, substituindo o nome e tipo pelo `listing_state_class` e `_listingKey` (ou reutilizar o nome `_providersKey` se já existir). Se o arquivo já declarar uma key com o mesmo propósito, atualize seu tipo para `listing_state_class` sem duplicar chaves.
4. Substituir o `body:` atual para instanciar a página de listagem usando a key, por exemplo:

   body: LISTING_WIDGET_NAME(key: _listingKey),

   respeitando a sintaxe Dart e mantendo quaisquer outros argumentos existentes no construtor do `HomePage` (se houver).
5. Atualizar os pontos onde o código reexibe o tutorial (por exemplo, linhas que chamam `_providersKey.currentState?.showTutorialAgain()`): substitua pelo uso da `listing_key` e chame o método fornecido em `tutorial_method_name`. Exemplo:

   _listingKey.currentState?.showTutorialAgain();

   ou, usando o parâmetro: `_listingKey.currentState?.<tutorial_method_name>();`.
6. Manter intactas todas as outras funcionalidades da `HomePage` (drawer, _loadUser, appBar actions, etc.). Apenas altere/importe o necessário para integrar a página de listagem.
7. Se `listing_state_class` não estiver disponível no projeto (por exemplo: quando o widget de listagem não expõe um State com esse nome), o gerador deve usar `GlobalKey<dynamic>` e documentar no topo do arquivo a razão com um comentário em português (ex.: "// Ajuste o tipo da GlobalKey para o State correto da página de listagem, se disponível").
8. Garantir que imports duplicados não sejam gerados; se `listing_import_path` já estiver importado, não adicione uma segunda importação.
9. Use português nos comentários/instruções que o gerador inserir (se necessário), e mantenha o estilo de código consistente com o projeto (sem reformatar desnecessariamente).

Exemplo de parâmetros (o aluno fornece os valores — não adicionar caminhos por convenção)
---------------------
- `home_file_path`: caminho relativo do arquivo `HomePage` a ser modificado (fornecido pelo aluno)
- `listing_import_path`: caminho de import da página de listagem (fornecido pelo aluno)
- `listing_widget_name`: nome do widget de listagem a ser usado como body do `HomePage` (fornecido pelo aluno)
- `listing_state_class`: nome da classe State do widget de listagem (fornecido pelo aluno)
- `tutorial_method_name`: nome do método público no State da página de listagem que reexibe o tutorial (opcional; se omitido use `showTutorialAgain`)

Saída esperada
--------------
- Atualizar o arquivo apontado por `home_file_path` no repositório com as mudanças descritas.
- Não alterar outros arquivos.
- Ao final, o `HomePage` deve renderizar a página de listagem informada e o drawer deve continuar a poder acionar o tutorial da página de listagem via a key e o método configurado.

Notas
-----
- Se o gerador encontrar inconsistências (por ex.: o nome do state não existe), ele deve aplicar o fallback `GlobalKey<dynamic>` e deixar um comentário claro na alteração indicando o que deve ser ajustado manualmente.
- Não inclua código de exemplo fora do arquivo `home_page.dart`; todas as mudanças devem ser aplicadas diretamente neste arquivo.
