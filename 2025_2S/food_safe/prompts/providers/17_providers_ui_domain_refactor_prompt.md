# 17 - UI Domain Refactor: Providers (versão didática)

> **Este prompt foi adaptado para fins didáticos. As alterações e refatorações devem conter comentários explicativos, dicas práticas, checklist de erros comuns, exemplos de logs esperados e referências aos arquivos de debug, facilitando o aprendizado e a implementação correta pelos alunos.**

Context
-------
This prompt documents the changes made to the `Providers` UI to stop using `ProviderDto` directly and instead use the domain entity `Provider` in presentation code. The conversion is performed at the boundary with persistence (DAO) via `ProviderMapper`.

Files changed
-------------
- `lib/features/providers/presentation/providers_page.dart`
  - Use `List<Provider>` in UI state and UI widgets.
  - When reading from the local DAO, convert DTO -> domain via `ProviderMapper.toEntity`.
  - When persisting, convert domain -> DTO via `ProviderMapper.toDto` and call DAO methods.
  - Implement a one-shot sync from Supabase using `ProvidersRepositoryImpl`, and show a top `LinearProgressIndicator` during sync (flag `_syncingProviders`).
  - Replaced an old `_removeProvider` reference with `_remove_provider` used by the page; consider renaming to lowerCamelCase to satisfy lint.

- `lib/features/providers/presentation/widgets/provider_list_view.dart`
  - Now accepts domain `Provider` list and forwards domain objects to item widgets.

- `lib/features/providers/presentation/widgets/provider_list_item.dart`
  - Now accepts a `Provider` domain object (uses `imageUri`, `distanceKm`, etc.).

- `lib/features/providers/presentation/dialogs/provider_form_dialog.dart`
  - Produces and accepts domain `Provider` values from the form dialog.

- `lib/features/providers/presentation/dialogs/provider_details_dialog.dart`
  - Accepts domain `Provider` and uses domain fields in UI.


Why this change
---------------
- Keep presentation layer decoupled from DTOs and persistence shape.
- Simplify UI code (domain-focused) and concentrate mapping logic in `ProviderMapper`.
- **Facilita testes, manutenção e evolução do código, além de evitar bugs comuns de conversão e dependência entre camadas.**


How the mapping is done (pattern)
---------------------------------
- Read local cache:

```dart
final dao = ProvidersLocalDaoSharedPrefs();
final dtoList = await dao.listAll();
final domainList = dtoList.map(ProviderMapper.toEntity).toList();
// Comentário: Sempre converta DTO -> domínio na fronteira de persistência para manter a UI desacoplada.
setState(() => _providers = domainList);
```

- Persist UI changes (create/edit/remove):

```dart
final newDtos = newDomain.map(ProviderMapper.toDto).toList();
await dao.clear();
await dao.upsertAll(newDtos);
// Comentário: Converta domínio -> DTO apenas ao persistir, mantendo a lógica de mapeamento centralizada.
```


Syncing with Supabase
---------------------
- Use `SupabaseProvidersRemoteDatasource` + `ProvidersRepositoryImpl` to fetch remote changes and upsert into local DAO.
- During the one-shot sync the UI sets `_syncingProviders = true` and displays a top `LinearProgressIndicator`; it resets the flag and shows a short `SnackBar` once the sync finishes.
- **Inclua prints/logs (usando kDebugMode) nos principais pontos do fluxo para facilitar o diagnóstico de problemas de sync e conversão. Exemplo de log esperado:**
```dart
if (kDebugMode) {
  print('ProvidersPage: iniciando sync com Supabase...');
}
```


Verification steps
------------------
1. Run static analysis:

```bash
flutter analyze
```

2. Run the app (requires valid Supabase URL/anon key in environment) and verify:
  - On first open with empty local cache the progress bar appears and the app syncs and populates the list.
  - Add, edit, delete flows persist through DAO (domain -> DTO mapping) and visually update the list.
  - **Verifique os logs no console para mensagens como:**
    - ProvidersPage: iniciando sync com Supabase...
    - ProvidersRepositoryImpl.syncFromServer: aplicados 3 registros ao cache

3. If analyzer shows lints about constructor `key` or identifier naming, fix by using `const Foo({super.key});` and prefer lowerCamelCase for method names (e.g. `_removeProvider`).
  - **Checklist de erros comuns e como evitar:**
    - Erro de conversão de tipos: garanta que o Mapper aceita múltiplos formatos vindos do backend.
    - Falha ao atualizar UI após sync: sempre verifique se o widget está mounted antes de chamar setState.
    - Dados não aparecem após sync: adicione prints/logs para inspecionar o conteúdo do cache e o fluxo de conversão.
    - Problemas de integração com Supabase (RLS, inicialização): consulte supabase_rls_remediation.md e supabase_init_debug_prompt.md.


Notes & follow-ups
------------------
- Analyzer warnings found after the refactor may include `use_super_parameters` and `non_constant_identifier_names` (e.g., `_remove_provider` flagged as not lowerCamelCase). Consider renaming `_remove_provider` -> `_removeProvider` and using `const Foo({super.key});` in widgets.
- If you prefer to keep private snake_case names (not recommended), add a brief comment explaining the reason — otherwise align with Dart style.
- **Referências úteis:**
  - providers_cache_debug_prompt.md
  - supabase_init_debug_prompt.md
  - supabase_rls_remediation.md

**IMPORTANT: RefreshIndicator on empty list**
------------------
⚠️ **Common mistake**: when the list is empty (`_providers.isEmpty`), if you only show a "No items" message without wrapping it in a `RefreshIndicator`, users cannot pull-to-refresh to sync and fetch new records from the server.

**Solution**: always wrap the empty state with `RefreshIndicator` + `ListView` with `AlwaysScrollableScrollPhysics()` to enable pull-to-refresh even when the list is empty. See prompt 12 (12_agent_list_refresh.md) for complete implementation example.

If you want, I can:
- Apply the minor lint fixes (rename `_remove_provider` -> `_removeProvider` and update callers).
- Run `flutter analyze` and fix the `use_super_parameters` occurrences by converting `({Key? key}) : super(key: key)` to `({super.key})` across the changed widgets.





# Observações adicionas

1. Caso o prompt proponha criar algum arquivo e esse arquivo já existir no projeto. Renomeie-o para .backup. E em seguida o remova.
2. Crie o novo arquivo
3. Garanta que a definição da classe do arquivo esteja escrita uma única vez no código
4. Caso o arquivo gerado ou arquivos manipulados por esse prompt seja grandes (avalie profissionalmete isso), procure refatorar, extraindo para arquivos organizados em subpastas
5. Ao refatorar e organizar, remova os arquivos antigos. Não deixe o arquivo apenas como wrappers ou comentários orientando a remoção manual.
