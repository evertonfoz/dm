# Prompt operacional: Integrar sincronização Supabase na `ProvidersPage` (versão didática)

> **Este prompt foi adaptado para fins didáticos. As alterações geradas devem conter comentários explicativos, dicas práticas, checklist de erros comuns, exemplos de logs esperados e referências aos arquivos de debug, facilitando o aprendizado e a implementação correta pelos alunos.**

Objetivo
--------
Gerar as alterações necessárias na tela de listagem de fornecedores (`ProvidersPage`) para que ela use o datasource remoto + repositório e execute uma sincronização única quando o cache local estiver vazio.

Contexto
--------
- Este projeto usa um DAO local (`ProvidersLocalDaoSharedPrefs`) e uma interface remota (`ProvidersRemoteApi`).
- Implementações concretas recentes: `SupabaseProvidersRemoteDatasource` e `ProvidersRepositoryImpl`.
- A UI atual consome `ProviderDto` via `ProvidersLocalDaoSharedPrefs.listAll()`.

Alterações a serem aplicadas
---------------------------
1. Adicionar imports no topo de `lib/features/providers/presentation/providers_page.dart`:

```dart
import '../infrastructure/remote/supabase_providers_remote_datasource.dart';
import '../infrastructure/repositories/providers_repository_impl.dart';
```


2. Modificar `_loadProviders()` para:
- Carregar lista local via `ProvidersLocalDaoSharedPrefs().listAll()`.
- Se a lista estiver vazia, construir `SupabaseProvidersRemoteDatasource()` e `ProvidersRepositoryImpl(remoteApi: remote, localDao: dao)` e chamar `await repo.syncFromServer()` dentro de `try/catch`.
- Após o sync (ou falha), recarregar `dao.listAll()` e atualizar o `setState` normalmente.
- **Inclua comentários explicativos em cada etapa do método, detalhando o motivo de cada ação e boas práticas (ex: sempre verificar se o widget está mounted antes de chamar setState, adicionar prints/logs para debug, tratar erros de conversão e integração).**
- **Adicione prints/logs (usando kDebugMode) nos principais pontos do fluxo para facilitar o diagnóstico de problemas de sync e cache. Exemplo de log esperado:**
```dart
if (kDebugMode) {
	print('ProvidersPage._loadProviders: carregando dados do cache...');
}
```


3. Manter o comportamento atual do tutorial/indicator caso a lista permaneça vazia.
	- **Inclua comentário explicando a importância de UX responsiva e de não bloquear a UI durante operações de sync.**

Motivação e benefícios
----------------------
- Popula automaticamente o cache local na primeira execução sem bloquear a experiência do usuário mais do que o necessário.
- Mantém separação de responsabilidades: UI continua lendo do DAO local; sync é feito pelo repositório.

Precondições
------------
- `SupabaseService` deve estar inicializado (ver `main.dart` e variáveis de ambiente).
- Implementações `SupabaseProvidersRemoteDatasource` e `ProvidersRepositoryImpl` devem existir (já implementadas).

Validação
--------
1. Rodar `flutter analyze` e `flutter test` (se houver testes relevantes).
2. Executar app com `.env` contendo `SUPABASE_URL` e `SUPABASE_ANON_KEY` e abrir a tela de Fornecedores.
3. Observações esperadas: na primeira execução (cache vazio) a lista deve ser preenchida pelo conteúdo remoto; em caso de falha a UI permanece em estado vazio com tutorial visível.


Notas de implementação
---------------------
- O sync é feito apenas quando o cache local está vazio para minimizar tráfego e evitar mudanças inesperadas em background.
- Para comportamento mais avançado (background sync, periodic sync) considere adicionar um serviço de sincronização separado.
- **Checklist de erros comuns e como evitar:**
	- Erro de conversão de tipos: garanta que o DTO/entidade aceita múltiplos formatos vindos do backend.
	- Falha ao atualizar UI após sync: sempre verifique se o widget está mounted antes de chamar setState.
	- Dados não aparecem após sync: adicione prints/logs para inspecionar o conteúdo do cache e o fluxo de conversão.
	- Problemas de integração com Supabase (RLS, inicialização): consulte supabase_rls_remediation.md e supabase_init_debug_prompt.md.
- **Exemplo de logs esperados:**
	- ProvidersPage._loadProviders: carregando dados do cache...
	- ProvidersRepositoryImpl.syncFromServer: aplicados 3 registros ao cache
- **Referências úteis:**
	- providers_cache_debug_prompt.md
	- supabase_init_debug_prompt.md
	- supabase_rls_remediation.md

**IMPORTANTE: RefreshIndicator na lista vazia**
---------------------
⚠️ **Erro comum**: quando a lista está vazia após sync, se apenas mostrar uma mensagem sem o `RefreshIndicator`, o usuário não conseguirá puxar para baixo para sincronizar novamente e buscar novos registros.

**Solução**: sempre envolva a tela vazia com `RefreshIndicator` + `ListView` com `AlwaysScrollableScrollPhysics()` para permitir pull-to-refresh mesmo sem itens na lista. Veja o prompt 12 (12_agent_list_refresh.md) para exemplo completo de implementação.



# Observações adicionas

1. Caso o prompt proponha criar algum arquivo e esse arquivo já existir no projeto. Renomeie-o para .backup. E em seguida o remova.
2. Crie o novo arquivo
3. Garanta que a definição da classe do arquivo esteja escrita uma única vez no código
4. Caso o arquivo gerado ou arquivos manipulados por esse prompt seja grandes (avalie profissionalmete isso), procure refatorar, extraindo para arquivos organizados em subpastas
5. Ao refatorar e organizar, remova os arquivos antigos. Não deixe o arquivo apenas como wrappers ou comentários orientando a remoção manual.
