# Prompt 04 — Gerar página de lista (layout apenas)

Descrição
---
Este prompt deve produzir apenas o código-fonte Dart de uma página Flutter (StatefulWidget) que replica o layout da figura de referência: mensagem central quando a lista estiver vazia, dica/tutorial em sobreposição, botão flutuante (FAB) no canto inferior direito respeitando SafeArea, e um botão de opt-out ao lado do FAB. O objetivo é exclusivamente o layout — nada de persistência, DAOs ou chamadas a SharedPreferences.

Parâmetros
---
- `entity` (string): Daily Goal.
- `output_path` lib/features/daily_goals/presentation. O gerador deve criar o arquivo neste caminho; o nome do arquivo deve ser `entity_list_page.dart` salvo dentro do `output_path` informado.
- `entity_import_path` (string): Investigue no projeto

Regras importantes
---
1. O gerador recebe exatamente os parâmetros acima e NENHUM exemplo adicional. Não fornecer valores de exemplo.
2. O texto central mostrado quando a lista estiver vazia deve incluir a palavra da entidade em MAIÚSCULAS; por exemplo: `Nenhum ${entity.toUpperCase()} cadastrado ainda.` — o gerador deve aplicar `toUpperCase()` no parâmetro recebido.
3. Gerar o conteúdo do arquivo Dart (o código fonte) e CRIAR o arquivo no repositório no caminho `output_path`. Salve o arquivo com o nome `entity_list_page.dart` dentro do `output_path`. Não inclua exemplos de chamada.
4. O Widget deve ser um `StatefulWidget` completo, com nome `EntityListPage` e o construtor recebendo `final String entity;` (além de qualquer import necessário usando `entity_import_path`).
5. O layout deve conter:
   - Mensagem central quando a lista estiver vazia (texto em `bodyLarge`).
   - Dica flutuante acima do FAB quando `showTip` for true (animação opcional leve).
   - Overlay de tutorial (Card central) quando `showTutorial` for true.
   - FAB no canto inferior direito com padding que soma `MediaQuery.of(context).padding.bottom` (ou utilizar `SafeArea`) para evitar o indicador de gesto do iPhone.
   - `TextButton` ao lado do FAB com o texto `Não exibir dica novamente` (apenas UI; comportamento pode ser simulado com um booleano local).
6. Não incluir código de acesso a banco ou SharedPreferences; use apenas variáveis locais em memória quando necessário.
7. Os textos visíveis devem estar em português. Quando for necessário exibir o nome da entidade em caixa alta, aplique `entity.toUpperCase()` no código.
8. O gerador deve retornar apenas o código Dart formatado e pronto para colar no arquivo apontado por `output_path` (sem explicações, exemplos ou instruções extras).

Saída esperada
---
Retornar exclusivamente o conteúdo do arquivo Dart (código fonte) e criar o arquivo no repositório no caminho `output_path` com o nome `entity_list_page.dart`.

Observação final
---
Focar estritamente no layout e acessibilidade visual (SafeArea) e não inserir dados de exemplo embutidos. Garantir que qualquer referência ao nome da entidade use `entity.toUpperCase()` quando o texto exigir caixa alta.