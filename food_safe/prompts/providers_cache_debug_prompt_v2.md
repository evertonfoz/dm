```markdown
# Providers Cache & DTO Debug (prompt v2.1)

Contexto
-------
O app grava e lê o cache de `providers` usando `SharedPreferences` e DTOs
(`ProviderDto`). Problemas comuns: formatos de campo vindos do Supabase
(`id` como string, `updated_at` com offset diferente) que quebram o mapeamento,
ou widget desmontado durante sync impedindo atualização da UI.

Padrão UI-first implementado
----------------------------
Desde a v2 do fluxo:
- Dados do cache são aplicados à UI **imediatamente** ao abrir a página
- Sync roda em segundo plano (não bloqueia a exibição)
- Se o widget for desmontado durante sync, não tem problema — dados já foram mostrados

Passos de verificação rápidos
----------------------------
1. Abra a `ProvidersPage`. Veja os logs que adicionamos:
   - `[_loadProviders] Applying cached data to UI...` — dados mostrados instantaneamente
   - `ProvidersRepositoryImpl: persisted local cache JSON: ...` (após sync)
   - `ProvidersPage._loadProviders: raw cache JSON: ...` (ao ler cache)

2. Confirme que os dois JSONs existem e contêm o mesmo registro.
   - Se id/updated_at estiverem iguais, o cache foi gravado e lido corretamente.

3. Se o cache contém o registro mas a lista não mostra nada:
   - Verifique se há log `[_loadProviders] NOT mounted, returning early` — isso significa
     que o widget foi desmontado **após** aplicar os dados; a UI deveria ter mostrado.
   - Possível problema no `ProviderMapper.toEntity` (conversão do DTO para domínio).
   - Adicione logs adicionais — exemplo:

```dart
// Em ProviderMapper.toEntity (somente em debug)
if (kDebugMode) {
  print('ProviderMapper: converting DTO id=${d.id} updated_at=${d.updated_at}');
}
```

4. JSON bruto para inspeção manual
- Se quiser, copie o JSON e valide os campos:
  - `id`: número inteiro
  - `updated_at`: string ISO8601 (ex.: 2025-11-13T14:56:36.80377+00:00)
  - `rating`: number

5. Correções automáticas que aplicamos
- `ProviderDto.fromMap` agora aceita `id` como `int`, `num` ou `String`;
  `rating`/`distance_km` como `num`/`String`; `updated_at` aceita `DateTime` ou `String`.
- UI-first loading: dados do cache são aplicados **antes** do sync para UX instantânea.
- Proteção contra widget desmontado: verificações de `mounted` em pontos críticos.

Problema comum: Widget desmontado durante sync
----------------------------------------------
Se você vir nos logs:
```
[_loadProviders] NOT mounted, returning early
```
Isso significa que o widget foi desmontado **durante** o sync. Com o padrão UI-first,
os dados já foram aplicados à UI antes, então a tela não deve ficar em branco.

Se a tela ainda ficar em branco:
- Confirme que vê o log `[_loadProviders] Applying cached data to UI...` **antes** do sync.
- Verifique se há exceções durante a conversão DTO→entidade (procure por `EXCEPTION` nos logs).

Fluxo esperado (logs)
---------------------
```
[_loadProviders] START
[_loadProviders] Loading from DAO...
[_loadProviders] Loaded 1 DTOs
[_loadProviders] Converting DTOs to entities...
[_loadProviders] Converted 1 entities
[_loadProviders] Applying cached data to UI...      ← DADOS MOSTRADOS AQUI
[_loadProviders] Cached data applied to UI
[_loadProviders] Starting sync...
... (sync roda em segundo plano)
[_loadProviders] Sync returned: 1 items applied
[_loadProviders] Converted 1 entities after sync
[_loadProviders] NOT mounted, returning early       ← OK, dados já foram mostrados
```

Se quiser, eu aplico um patch adicional que imprime, em `kDebugMode`, a conversão do DTO para entidade (opção segura e reversível). Deseja que eu adicione esse print automaticamente?
```
