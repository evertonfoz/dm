# Supabase init, sync & RLS troubleshooting prompt (v2)

Resumo do problema
-------------------
Durante testes locais a app imprimia que o Supabase foi inicializado, mas chamadas a `SupabaseService().client` lançavam exceção. Além disso, quando o fluxo de sincronização tentava fazer `upsert`, o push retornava 0 itens — depois diagnosticamos que o Supabase rejeitou a inserção por Row‑Level Security (RLS).

O que eu fiz no código
----------------------
- `SupabaseService.client`: agora tenta adotar `Supabase.instance.client` caso `_client` ainda seja null. Evita exceção quando a SDK é inicializada diretamente em `main.dart`.
- Adicionei prints condicionais (`kDebugMode`) para visibilidade em:
  - `SupabaseProvidersRemoteDatasource.fetchProviders`
  - `ProvidersRepositoryImpl.syncFromServer` (agora com logs 1/3,2/3,3/3)
  - `SupabaseProvidersRemoteDatasource.upsertProviders` (diagnósticos RLS)
- Compatibilidade com versões do cliente Supabase: `._executeQuery()` tenta `.select()`, `.execute()` e `await builder` em ordem segura para evitar NoSuchMethodError.
- Tratamento de erros do Postgrest: `_executeQuery` captura exceções e retorna um objeto com `error` em vez de deixar a exceção explodir no debugger — isso permite ao código logar e continuar em vez de pausar a execução.
- Melhorei o logging na UI (`_loadProviders`) para imprimir exceção e stacktrace em debug, facilitando encontrar onde o fluxo falha.

Por que isso ajuda
------------------
- O wrapper `SupabaseService` agora é tolerante à forma como o SDK foi inicializada.
- Os prints numerados deixam claro em qual fase o sync está (push, fetch, apply) — o último log antes da pausa indica o local do problema.
- Ao retornar um `response.error` em vez de estourar exceções não tratadas, o debugger não pausa em exceções que já estão sendo gerenciadas.

Como testar (passo-a-passo)
--------------------------
1. Full restart da app:

```bash
flutter clean
flutter pub get
flutter run -d <device>
```

2. No debugger VS Code: abra o painel BREAKPOINTS e **desmarque** `All Exceptions`, deixando marcado apenas `Uncaught Exceptions`.

3. Acione a ação que dispara sync (abrir `ProvidersPage`, adicionar um fornecedor ou pull-to-refresh).

4. Observe o console — você deverá ver logs como:
- `ProvidersRepositoryImpl.syncFromServer: starting`
- `[1/3] About to push local cache...`
- `[1/3] Calling remoteApi.upsertProviders...`
- `SupabaseProvidersRemoteDatasource.upsertProviders: sending X items`
- `Supabase upsert response error: ...` (se houver)
- `Supabase upsert diagnostic: the request was denied by Row-Level Security (RLS).` (quando aplicável)
- `[2/3] About to fetch remote deltas...` / `[2/3] Remote fetch complete: N items`
- `[3/3] About to upsert into local cache...` / `complete (... items applied)`

Diagnóstico RLS — o que fazer
----------------------------
Se o log der `Supabase upsert diagnostic: the request was denied by Row-Level Security (RLS).` siga estes passos:

1) Pelo Dashboard (mais simples):
- Acesse `app.supabase.com` → seu projeto → **Table Editor** → selecione a tabela `providers` → **Policies** → **New Policy**.
- Crie política de `INSERT` (e `UPDATE`) para role `anon` com `USING (true)` e `WITH CHECK (true)` apenas para testes.

2) Via SQL (exemplo):

```sql
-- teste rápido (não usar em produção)
CREATE POLICY "Allow anonymous inserts" ON providers FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Allow anonymous updates" ON providers FOR UPDATE TO anon WITH CHECK (true);
```

3) Teste via curl para confirmar:

```bash
# substituir URL e ANON_KEY
curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "apikey: <ANON_KEY>" \
  -H "Authorization: Bearer <ANON_KEY>" \
  -H "Prefer: return=representation" \
  -d '{"id":-999,"name":"Test via curl","updated_at":"2025-11-27T00:00:00Z"}' \
  "https://<PROJECT>.supabase.co/rest/v1/providers"
```

Se o POST retornar o registro criado, as policies foram aplicadas com sucesso.

Segurança / produção
---------------------
- `USING (true)` é SOMENTE para testes. Em produção use políticas baseadas em autenticação (`TO authenticated`) e `auth.uid()` para restringir operações por usuário.
- Nunca exponha `service_role` no cliente. Use funções no backend com service key para operações privilegiadas.

Próximos passos opcionais que posso aplicar
------------------------------------------
- Adicionar `SupabaseService.adoptSdkClient()` e chamá-lo em `main()` para tornar a inicialização explícita.
- Inserir um botão temporário de debug na UI que chama `repo.syncFromServer()` para testes manuais mais rápidos.
- Ajudar a escrever políticas RLS seguras (baseadas em usuários) depois do teste inicial.

Se quiser, eu atualizo a prompt com exemplos de políticas seguras conforme seu modelo de autenticação (por e-mail, JWT custom, etc.).
