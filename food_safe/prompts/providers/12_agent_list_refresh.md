```markdown
## Prompt: Implementar Pull-to-Refresh (RefreshIndicator)

Objetivo
---
Adicionar a funcionalidade de Pull-to-Refresh à listagem de providers, isolando esta responsabilidade para que possa ser implementada separadamente do widget de listagem principal (listing-only).

Resumo do comportamento
---
- Envolver a listagem em um `RefreshIndicator` que, ao puxar para baixo, aciona a recarga dos dados chamando o DAO (por exemplo `ProvidersLocalDaoSharedPrefs.listAll`) ou um callback exposto pelo widget listing-only.
- Enquanto a atualização está em progresso, exibir o spinner do `RefreshIndicator` e, se aplicável, um `SnackBar` de erro em caso de falha.
- Garantir que o `RefreshIndicator` funcione com grandes listas e com os builders existentes (não substituir o `ListView.builder`, apenas envolvê-lo).
- A operação de recarga deve ser segura para concorrência: se já houver uma carga em andamento, a chamada de refresh deve aguardar ou ser ignorada (ex.: usar uma flag `_isLoading`).

Integração e API esperada
---
Opções de implementação — escolha uma conforme a arquitetura desejada:

1) Implementação direta no widget de listagem (patch):
   - Abra `lib/features/{FEATURE_FOLDER}/presentation/widgets/provider_list_view.dart` e envolva o `ListView` existente com `RefreshIndicator`, chamando internamente o método de reload que já existe na página (por exemplo via callback `onRefresh`).
   - Aceita um parâmetro opcional `Future<void> Function()? onRefresh` para delegar a ação de recarga ao `providers_page.dart` (onde a persistência e o DAO vivem).

2) Implementação via wrapper/adapter (não intrusiva):
   - Criar um pequeno widget `ProviderListWithRefresh` em `lib/features/{FEATURE_FOLDER}/presentation/widgets/provider_list_with_refresh.dart` que receba um child `Widget list` e um callback `onRefresh`. O wrapper apenas fornece o `RefreshIndicator` e delega a ação para o callback.
   - Vantagem: não altera o listing-only original; é um patch local que pode ser aplicado apenas quando desejar ativar o refresh.

Comportamento esperado do callback `onRefresh`
---
- Assinatura: `Future<void> Function()`.
- Deve chamar o DAO (por ex. `await dao.listAll(...)`) e atualizar o estado visível (via `setState` no `providers_page.dart` ou via um `ValueNotifier`/`Stream`), tratando erros com `try/catch`.
- Em caso de erro, retornar sem lançar (capturar e mostrar `SnackBar`) para que o `RefreshIndicator` finalize corretamente.

Exemplo de uso (conceitual)
---
- Listing-only widget exporta um parâmetro `onRefresh`.
- `providers_page.dart` passa sua função `_loadProviders` para `onRefresh`.
- Quando usuário puxa para baixo, `RefreshIndicator` chama `await onRefresh()` e o page atualiza a lista.

Critérios de aceitação
---
1. Puxar para baixo na lista aciona a recarga dos dados via DAO (ou callback delegado).
2. O `RefreshIndicator` mostra o spinner enquanto a operação está em andamento.
3. Falhas durante a recarga exibem `SnackBar` amigável e não quebram o estado do widget.
4. A implementação pode ser aplicada como wrapper não intrusivo ou integrada diretamente ao widget de listagem.

Notas adicionais
---
- Recomenda-se delegar a lógica de recarga ao nível da página (onde o DAO e o estado de persistência estão) para manter os widgets puros/visuais.
- Documente no prompt de listagem que o `onRefresh` é esperado caso queira ativar pull-to-refresh mais tarde.
 - Recomenda-se delegar a lógica de recarga ao nível da página (onde o DAO e o estado de persistência estão) para manter os widgets puros/visuais.
 - Documente no prompt de listagem que o `onRefresh` é esperado caso queira ativar pull-to-refresh mais tarde.
 - Observação: se o refresh abrir diálogos de erro/alerta, esses diálogos devem ser não-dismissable ao tocar fora (use `showDialog(..., barrierDismissible: false)`) para manter consistência com as diretrizes de UX.

```
