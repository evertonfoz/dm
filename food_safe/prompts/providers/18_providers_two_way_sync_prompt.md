````markdown

# 18 - Implement Two-Way Providers Sync (Push then Pull) — versão didática

> **Este prompt foi adaptado para fins didáticos. As alterações e implementações devem conter comentários explicativos, dicas práticas, checklist de erros comuns, exemplos de logs esperados e referências aos arquivos de debug, facilitando o aprendizado e a implementação correta pelos alunos.**

Summary
-------
This change implements a two-way synchronization flow for `Providers` between
the local cache (SharedPreferences DAO) and Supabase. The repository now
performs a best-effort push of local cache items to the remote, then pulls
remote deltas (since the last successful sync) and applies them locally.

Files changed
-------------
- `lib/features/providers/infrastructure/remote/providers_remote_api.dart`
  - Added `Future<int> upsertProviders(List<ProviderDto> dtos);` to the
    interface so datasources can accept bulk upserts.

- `lib/features/providers/infrastructure/remote/supabase_providers_remote_datasource.dart`
  - Implemented `upsertProviders` using the Supabase client's `upsert` API.
  - It sends DTO maps to the `providers` table and returns the number of
    rows acknowledged by the server (best-effort).

- `lib/features/providers/infrastructure/repositories/providers_repository_impl.dart`
  - Updated `syncFromServer()` to perform:
    1. Push: read local cache (`ProvidersLocalDao.listAll()`), call
       `remoteApi.upsertProviders(local)` (best-effort; failures are ignored
       to avoid blocking pulls).
    2. Pull: fetch remote updates since `lastSync` and `localDao.upsertAll()`
    3. Update `lastSync` marker using the greatest `updated_at` from remote
       items applied.


Design notes & rationale
------------------------
- We push the local cache wholesale because the current local DAO doesn't track per-item 'dirty' flags; this keeps the implementation simple and safe for apps where the local cache is authoritative for user edits.
- Push is best-effort: network or remote errors don't prevent the repository from pulling remote deltas; the push will be retried on the next sync.
- Pull uses `updated_at` timestamps to fetch incremental changes and relies on server-side timestamps to resolve conflicts (Last-Write-Wins by timestamp).
- **Inclua comentários explicativos em cada etapa do fluxo de sync, detalhando o motivo de cada ação e boas práticas (ex: sempre usar try/catch, logs para debug, não bloquear a UI).**
- **Adicione prints/logs (usando kDebugMode) nos principais pontos do fluxo para facilitar o diagnóstico de problemas de push/pull e integração. Exemplo de log esperado:**
```dart
if (kDebugMode) {
  print('ProvidersRepositoryImpl.syncFromServer: pushed $pushed items to remote');
}
```


How to verify
--------------
1. Run static analysis:

```bash
flutter analyze
```

2. Run the app with a working Supabase anon URL and key. Steps:
  - Start the app on a device/emulator with a fresh local cache.
  - Add or edit a provider locally; open the app on another client (or update server-side) and run sync; verify both sides converge.
  - **Verifique os logs no console para mensagens como:**
    - ProvidersRepositoryImpl.syncFromServer: pushed 3 items to remote
    - SupabaseProvidersRemoteDatasource.upsertProviders: sending 3 items
    - Supabase upsert response error: ...
    - ProvidersRepositoryImpl.syncFromServer: aplicados 3 registros ao cache

3. Observe logs (dev/debug) para push errors; a implementação ignora falhas de push para não bloquear pulls, mas sempre loga o erro para facilitar o diagnóstico.
  - **Checklist de erros comuns e como evitar:**
    - Erro de conversão de tipos: garanta que o DTO/entidade aceita múltiplos formatos vindos do backend.
    - Falha ao atualizar UI após sync: sempre verifique se o widget está mounted antes de chamar setState.
    - Dados não aparecem após sync: adicione prints/logs para inspecionar o conteúdo do cache e o fluxo de conversão.
    - Problemas de integração com Supabase (RLS, inicialização): consulte supabase_rls_remediation.md e supabase_init_debug_prompt.md.

Follow-ups
  DAO to support temporary IDs and a mapping step that replaces temporary IDs
  with server-assigned ones after upsert. That requires more complex
  reconciliation logic and tests.

````

Additional changes (diagnostics & startup sync)
----------------------------------------------
After implementing the two-way sync described above I made three small
operational changes to help diagnose push failures and ensure cached items are
sent to Supabase even when the cache is not empty:

- Always-run sync on startup in the UI:
  - File: `lib/features/providers/presentation/providers_page.dart`
  - Behavior: `_loadProviders()` now loads the local cache for immediate UI
    responsiveness, then always calls `ProvidersRepositoryImpl.syncFromServer()`
    (push then pull). While syncing the page shows a top `LinearProgressIndicator`.
  - Rationale: previously sync ran only when the local cache was empty, which
    caused cached items to never be pushed to remote if they already existed
    locally.

- Diagnostic prints in Supabase datasource:
  - File: `lib/features/providers/infrastructure/remote/supabase_providers_remote_datasource.dart`
  - Behavior: `upsertProviders()` now prints the number of items sent,
    `response.error` and `response.data.length` to the app console. This helps
    identify RLS/permission or schema errors returned by Supabase.
  - Note: these prints are intended for debugging; I can make them conditional
    (e.g. `if (kDebugMode)`) or replace with a logger before merging to
    production.

- Diagnostic print in repository:
  - File: `lib/features/providers/infrastructure/repositories/providers_repository_impl.dart`
  - Behavior: after calling `remoteApi.upsertProviders(local)` the repo logs
    how many items were pushed: `print('ProvidersRepositoryImpl: pushed $pushed items to remote')`.


How this helps debugging
------------------------
- If the app prints `sending N items` but `response.error` is non-null, the error text is likely a Supabase/PostgREST error (e.g. RLS violation or malformed payload). Consulte os arquivos de debug do projeto para exemplos de erros e soluções.
- If the `response.error` is `null` but `data.length` is `0`, the upsert may have been accepted by PostgREST but returned no rows (verify table schema and the presence of `RETURNING` behavior in Supabase settings).
- **Referências úteis:**
  - providers_cache_debug_prompt.md
  - supabase_init_debug_prompt.md
  - supabase_rls_remediation.md

Recommended follow-ups
----------------------
- Make the debug logs conditional on `kDebugMode` to avoid `print` in
  production builds.
- If push succeeds but rows don't appear in the Dashboard, verify
  RLS policies for the `providers` table and the anon role.

**IMPORTANT: RefreshIndicator on empty list**
----------------------
⚠️ **Common mistake**: after implementing two-way sync, if the list is empty and you only show a "No items" message without wrapping it in a `RefreshIndicator`, users cannot pull-to-refresh to trigger sync and fetch records from Supabase.

**Solution**: always wrap the empty list state with `RefreshIndicator` + `ListView` with `AlwaysScrollableScrollPhysics()` to enable pull-to-refresh even when starting with an empty cache. This allows users to:
1. Pull down on the empty screen
2. Trigger `_loadProviders()` which calls `syncFromServer()`
3. Push local changes and pull remote updates
4. See the synced items appear in the list

See prompt 12 (12_agent_list_refresh.md) for complete implementation example.
