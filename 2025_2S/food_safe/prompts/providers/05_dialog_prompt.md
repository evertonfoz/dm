# Prompt 05 — Gerar implementação da Dialog de inserção/edição

Objetivo
--------
Gere um arquivo Dart que contém a implementação reutilizável da dialog de inserção/edição para a entidade informada. A dialog deve ser apresentada como um `AlertDialog` (ou `Dialog`) contendo campos de entrada conforme descrito pelo aluno e retornar uma instância/DTO representando os valores preenchidos quando o usuário confirmar.

Parâmetros (obrigatórios)
-------------------------
- `entity` (string): nome da entidade gerenciada pela dialog (por exemplo: `Provider`).
- `output_path` (string): caminho relativo onde o arquivo Dart será criado (por exemplo: `lib/features/providers/presentation`). O gerador deve criar o arquivo nesse caminho com o nome `entity_form_dialog.dart`.
- `entity_import_path` (string): caminho de import para a definição/DTO da entidade (por exemplo: `package:meu_app/features/providers/infrastructure/dtos/provider_dto.dart`). Use este valor para compor imports no código gerado.
- `fields` (estrutura): lista estruturada com a definição dos campos que devem aparecer na dialog. Cada item da lista será um objeto com as propriedades (nome, label, type, required, multiline). O gerador deve validar e usar essas propriedades para construir os `TextEditingController`s, `TextField`s adequados e a conversão de tipos ao confirmar.

Exemplo de `fields` (siga este formato ao fornecer o parâmetro):

Exemplo (JSON):

```json
[
  { "name": "name", "label": "Nome", "type": "string", "required": true, "multiline": false },
  { "name": "rating", "label": "Nota (0-5)", "type": "double", "required": true, "multiline": false },
  { "name": "distance_km", "label": "Distância (km)", "type": "double", "required": false, "multiline": false },
  { "name": "image_url", "label": "URL da Imagem (opcional)", "type": "string", "required": false, "multiline": false },
  { "name": "notes", "label": "Observações", "type": "string", "required": false, "multiline": true }
]
```

Exemplo (literal Dart):

```dart
final List<Map<String, dynamic>> fields = [
  {'name': 'name', 'label': 'Nome', 'type': 'string', 'required': true, 'multiline': false},
  {'name': 'rating', 'label': 'Nota (0-5)', 'type': 'double', 'required': true, 'multiline': false},
  {'name': 'distance_km', 'label': 'Distância (km)', 'type': 'double', 'required': false, 'multiline': false},
  {'name': 'image_url', 'label': 'URL da Imagem (opcional)', 'type': 'string', 'required': false, 'multiline': false},
  {'name': 'notes', 'label': 'Observações', 'type': 'string', 'required': false, 'multiline': true},
];
```

Breve orientação sobre interpretação (resumo):
- `name`: chave do campo usada para popular/ler o DTO (`initial?.<name>`).
- `label`: texto mostrado no `InputDecoration(labelText: ...)`.
- `type`: `string`, `double`, `int`, `bool`, `date`, `url` (fallback: `string`).
- `required`: se true, bloqueia confirmação quando vazio.
- `multiline`: se true, use `maxLines`/`minLines` para permitir várias linhas.

O gerador deve aceitar esse formato e criar os controllers/fields e a conversão apropriada ao confirmar.

Regras importantes
------------------
1. Não insira exemplos de uso dentro do prompt. O gerador deve confiar apenas nos parâmetros fornecidos.
2. O arquivo gerado deve ser auto-contido e exportável: declarar imports necessários (incluindo o `entity_import_path`), declarar um método/Widget público que abra a dialog e retorne o DTO da entidade preenchida.
3. Nome do arquivo a ser criado: `entity_form_dialog.dart` salvo dentro do `output_path` informado.
4. Assinatura esperada do método público que abre a dialog (padrão):
   - `Future<ENTITY_DTO?> showEntityFormDialog(BuildContext context, {ENTITY_DTO? initial})`  
     - Substitua `ENTITY_DTO` pelo tipo apropriado inferido a partir de `entity_import_path` ou substitua por `dynamic` se não for possível inferir.
     - `initial` é opcional e, quando fornecido, deve preencher os controllers com os valores correspondentes para edição.
5. Os campos recebidos em `fields` definem os inputs do formulário. Para cada campo, o gerador deve:
   - Criar um `TextEditingController` inicializado com o valor de `initial` quando fornecido.
   - Exibir um `TextField` com `decoration: InputDecoration(labelText: label)` e ajustar `keyboardType` conforme `type` (por exemplo: numérico quando `type` indicar número).
   - Se `required` for true, impedir a confirmação enquanto o campo estiver vazio (validação mínima).
   - Ao confirmar, converter os valores dos controllers para os tipos declarados e construir uma instância/DTO correspondente que será retornada via `Navigator.of(context).pop(dto)`.
6. A dialog deve ter pelo menos dois botões: `Cancelar` (fecha sem retornar) e `Adicionar`/`Salvar` (texto condicional: se `initial` for nulo usar `Adicionar`, caso contrário `Salvar`).
7. O código gerado deve estar em português nos textos visíveis (`Cancelar`, `Adicionar`, `Salvar`, etc.).
8. Não incluir lógica de persistência, SharedPreferences ou DAOs — apenas construir e retornar o DTO preenchido.
9. Se o `entity_import_path` não for válido para inferir o tipo DTO, use um tipo `dynamic` e documente no topo do arquivo que o aluno deve ajustar o import/tipo conforme sua base de código.

Saída esperada
--------------
- Criar o arquivo: `<output_path>/entity_form_dialog.dart` contendo:
  - Imports necessários, incluindo `package:flutter/material.dart` e `entity_import_path` (quando fornecido).
  - Uma função pública `Future<...?> showEntityFormDialog(BuildContext context, { ... })` ou um `StatefulWidget` público equivalente que abra a dialog e retorne o DTO preenchido.
  - Implementação completa dos controllers, validação mínima e conversão de tipos.
  - Comentários curtos em português explicando pontos importantes (por exemplo: onde ajustar tipos se `entity_import_path` não fornecer um DTO facilmente inferível).

Ao término
---------
- Informe o caminho do arquivo criado e confirme que o arquivo contém a função pública/Widget que abre a dialog e retorna o DTO preenchido, sem incluir qualquer persistência.

Observações finais
------------------
- O aluno será responsável por fornecer a estrutura `fields` ao chamar o gerador. Não inclua exemplos de `fields` dentro do arquivo de prompt. O gerador deverá aceitar qualquer lista válida que respeite a estrutura especificada.
