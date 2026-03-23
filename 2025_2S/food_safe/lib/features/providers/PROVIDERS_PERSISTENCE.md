## Persistência de Fornecedores (Providers)

Este documento técnico descreve como a aplicação persiste (cria/edita/remove/lista) os registros de fornecedores na feature `providers`.

Objetivo
--------
- Oferecer um mapa rápido para desenvolvedores que assumem o código.
- Explicar o fluxo UI → diálogo → página → DAO → armazenamento físico (SharedPreferences).
- Apontar limitações e sugestões de melhoria.

Arquivos principais
------------------
- `lib/features/providers/presentation/providers_page.dart` — Página que exibe a lista, contém o FAB, handlers de abrir diálogos e orquestra chamadas ao DAO.
- `lib/features/providers/presentation/dialogs/provider_form_dialog.dart` — Diálogo que cria/edita um `ProviderDto` e o retorna via `Navigator.pop`.
- `lib/features/providers/presentation/dialogs/provider_details_dialog.dart` — Diálogo de detalhes (edita / remove via callbacks fornecidos pela page).
- `lib/features/providers/infrastructure/dtos/provider_dto.dart` — DTO usado para serialização e conversão para entidade de domínio.
- `lib/features/providers/infrastructure/local/providers_local_dao_shared_prefs.dart` — Implementação do DAO que persiste em `SharedPreferences` sob a chave `_cacheKey = 'providers_cache_v1'`.
- `lib/features/providers/infrastructure/local/providers_local_dao.dart` — Interface do DAO (contrato).

Visão geral do fluxo (passo-a-passo)
-----------------------------------
1. A interação do usuário começa pela UI: FAB (adicionar) ou ação de editar em uma linha (ícone de lápis). A `ProvidersPage` é quem liga os handlers.
2. A `ProvidersPage` chama `showProviderFormDialog(context, provider: ...)` para exibir o formulário.
3. O formulário (`provider_form_dialog.dart`) monta os `TextEditingController`s, valida os campos, cria um `ProviderDto` com:
   - `id`: `provider?.id ?? DateTime.now().millisecondsSinceEpoch` (gera id para novos registros)
   - `updated_at`: `DateTime.now().toIso8601String()`
   - demais campos provenientes do formulário
   Em seguida o diálogo retorna o DTO com `Navigator.of(context).pop(dto)`.
4. A `ProvidersPage` aguarda o resultado do diálogo (`await showProviderFormDialog(...)`). Se receber um `ProviderDto`:
   - cria uma cópia mutável da lista atual (`List<ProviderDto> newList = List.from(_providers)`),
   - substitui o item existente (`newList[index] = result`) quando for edição ou adiciona (`newList.add(result)`) quando for criação,
   - instancia o DAO local: `final dao = ProvidersLocalDaoSharedPrefs();`
   - persiste chamando `await dao.upsertAll(newList);`
   - recarrega os dados chamando `await _loadProviders();` (que internamente chama `dao.listAll()` e `setState` com a nova lista).

Remoção de registros
---------------------
- A remoção é feita em `_removeProvider(int index)` na `ProvidersPage`:
  - cria `newList = List.from(_providers)` e remove o item com `newList.removeAt(index)`;
  - chama `await dao.clear();` e logo depois `await dao.upsertAll(newList);` — isto garante que o cache local contenha apenas os itens atuais.

Observações sobre a implementação do DAO
--------------------------------------
- `upsertAll(List<ProviderDto> dtos)`
  - Lê o JSON atual de `_cacheKey` do `SharedPreferences`, transforma em um mapa indexado por `id`.
  - Para cada DTO recebido, faz `current[dto.id] = dto.toMap();` (insere/atualiza).
  - Serializa `current.values.toList()` e grava como JSON em `prefs.setString(_cacheKey, jsonEncode(merged));`.
  - Importante: `upsertAll` não remove registros que estavam no cache e não aparecem na lista de entrada — por isso a page chama `clear()` antes de regravar ao fazer remoção.

- `listAll()` — lê o JSON e retorna `List<ProviderDto>` via `ProviderDto.fromMap(...)`.
- `getById(int id)` — lê e devolve o DTO com o id correspondente ou null.
- `clear()` — remove a chave do `SharedPreferences`.

Pontos de atenção e limitações
-----------------------------
- Atomicidade / concorrência: não há locking entre leituras/escritas. Chamadas simultâneas a `upsertAll` podem provocar perda de atualizações em cenários de concorrência alta.
- Remoção: atualmente a remoção é feita com `clear()` + `upsertAll(newList)`. Isto funciona, mas é ineficiente e potencialmente arriscado se outras rotinas alterarem o cache ao mesmo tempo.
- Geração de `id`: é feita com `DateTime.now().millisecondsSinceEpoch`. Em ambientes com múltiplas criações simultâneas existe uma pequena chance de colisão (pouco provável, mas teoricamente possível).
- Ordem dos registros: o DAO armazena `current.values.toList()` (ordem de iteração do Map). Se a ordem é importante, force uma ordenação (por exemplo por `updated_at`) antes de gravar.

Sugestões de melhorias (práticas recomendadas)
-------------------------------------------
1. Implementar `Future<void> deleteById(int id)` no `ProvidersLocalDao` e em `ProvidersLocalDaoSharedPrefs`.
   - Evita a necessidade de `clear()` + `upsertAll`, reduz custo e risco de races.
   - Exemplo de comportamento: ler lista, remover item por id, gravar resultado (ou gravar um map atualizado sem `clear()`).

2. Adicionar pequenas sincronizações/locks locais (por exemplo, um `Mutex` simples) para evitar condições de corrida em operações de escrita concorrentes.

3. Se a complexidade de dados aumentar, migrar para armazenamento baseado em arquivos/SQLite/Sembast que suportam operações transacionais e consultas eficientes.

4. Cobertura de testes: adicionar testes unitários para o DAO (`upsertAll`, `listAll`, `getById`, `clear`, e o futuro `deleteById`).

5. Melhorar a geração de `id` quando necessário (UUIDs ou um esquema combinado) caso o projeto exija alta taxa de criação concorrente.

Como testar localmente (rápido)
------------------------------
1. Rodar o analisador Flutter para garantir lints/avisos:

```bash
flutter analyze
```

2. Executar os testes (se houver) com:

```bash
flutter test
```

3. Teste manual rápido:
   - Abra a tela de fornecedores, adicione um fornecedor, verifique que ele aparece.
   - Edite o mesmo item e verifique a persistência após fechar/abrir a tela.
   - Remova o item e verifique que o registro desapareceu do `SharedPreferences` (inspecione com logs ou debug).

Localizações de código (referência rápida)
----------------------------------------
- Page / orquestração: `lib/features/providers/presentation/providers_page.dart`
- Formulário: `lib/features/providers/presentation/dialogs/provider_form_dialog.dart`
- Detalhes: `lib/features/providers/presentation/dialogs/provider_details_dialog.dart`
- DTO: `lib/features/providers/infrastructure/dtos/provider_dto.dart`
- DAO interface: `lib/features/providers/infrastructure/local/providers_local_dao.dart`
- DAO SharedPreferences: `lib/features/providers/infrastructure/local/providers_local_dao_shared_prefs.dart`

Perguntas / próximos passos
---------------------------
- Deseja que eu implemente `deleteById(int id)` no DAO e substitua `_removeProvider` para usá-lo? Posso também adicionar testes unitários para o DAO (fast, isolado com `SharedPreferences.setMockInitialValues({})`).
- Quer que eu abra um branch e prepare um PR com as mudanças sugeridas (deleteById + testes + pequenas melhorias)?

-----------------------------
Arquivo gerado automaticamente para onboarding de devs — mantenha-o atualizado quando a camada de persistência mudar.

/* fim */
