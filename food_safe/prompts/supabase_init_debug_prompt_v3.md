```markdown
# Supabase Debug & Test Guide (prompt v3.1)

Objetivo
-------
Guia curto e reproduzível para validar a integração do app com Supabase,
diagnosticar RLS (Row-Level Security), interpretar respostas do cliente
quando o runtime retorna formatos diferentes (List/Map/objeto), e resolver
problemas comuns de widget lifecycle (mounted state).

Uso rápido
----------
- Abra o app e navegue para a página `ProvidersPage` (ela dispara sync ao abrir).
- **Dados do cache são exibidos imediatamente** antes do sync começar.
- Observe o console/logs para as linhas de diagnóstico:
  - `[_loadProviders] Applying cached data to UI...` — dados mostrados instantaneamente
  - `SupabaseProvidersRemoteDatasource.upsertProviders: sending N items`
  - `Supabase upsert response data length: X` ou `Supabase upsert response error: <msg>`

Se o push retornar 0 ou houver um erro com código `42501`, a causa provável
é RLS (Row-Level Security) bloqueando a operação para o papel `anon`.

Diagnóstico rápido (curl)
------------------------
Testar diretamente com o `anon` key (temporário, para reproduzir):

```bash
curl -s -X POST "${SUPABASE_URL}/rest/v1/providers" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"id":"test-1","name":"Test Provider","updated_at":"2025-11-27T00:00:00Z"}'
```

- Resposta `201` ou `200` com o corpo do registro: ok.
- Resposta 4xx com mensagem contendo `row-level security` ou `42501`: RLS bloqueou.

Como ajustar RLS (temporário para testes)
--------------------------------------
No Supabase SQL Editor ou Table → Policies, executar (apenas para testes):

```sql
-- Permitir INSERTs anônimos temporariamente (testes)
CREATE POLICY "Allow anon insert providers" ON public.providers
  FOR INSERT TO anon WITH CHECK (true);

-- Permitir UPDATEs anônimos temporariamente (testes)
CREATE POLICY "Allow anon update providers" ON public.providers
  FOR UPDATE TO anon WITH CHECK (true);
```

Depois de validar, reverter essas políticas e aplicar regras mais seguras
(ex.: exigir autenticação e usar `auth.uid()` nas cláusulas `USING`/`WITH CHECK`).

Notas sobre formatos de resposta e compatibilidade do cliente
-----------------------------------------------------------
- O cliente Supabase/Postgrest pode retornar: `List` (dados), `Map` com
  chaves `data`/`error`, ou um objeto com propriedades `.data`/`.error`.
- No app implementamos `_executeQuery(...)` e extração tolerante para evitar
  `NoSuchMethodError` quando o runtime não expõe `.execute()`.
- Se encontrar `NoSuchMethodError`, verifique a versão do pacote `supabase_flutter`
  e confirme a forma de execução do `PostgrestFilterBuilder`.

Problema: Widget desmontado durante sync (mounted = false)
----------------------------------------------------------
- **Sintoma**: logs mostram `[_loadProviders] NOT mounted, returning early` e a UI fica em branco.
- **Causa**: o sync é assíncrono (pode levar segundos); se o usuário navegar para outra
  tela ou o widget for reconstruído durante o sync, `mounted` vira `false`.
- **Solução aplicada**: 
  - Dados do cache são aplicados à UI **antes** do sync começar (UX instantânea).
  - Sync roda em segundo plano com indicador de progresso no topo.
  - Se o widget for desmontado, os dados já foram mostrados — sem problema.
- **Verificação**: procure por `[_loadProviders] Applying cached data to UI...` nos logs.

Logs esperados (exemplo)
------------------------
- Sucesso (inseriu e retornou dados):
  - `SupabaseProvidersRemoteDatasource.upsertProviders: sending 1 items`
  - `Supabase upsert response data length: 1`
- RLS bloqueando (teste):
  - `Supabase upsert response error: new row violates row-level security policy for table 'providers'` 
  - `Supabase upsert diagnostic: the request was denied by Row-Level Security (RLS).`

Boas práticas
------------
- Nunca exponha a `service_role` key em apps clientes.
- Teste com `anon` apenas para validar fluxo; depois implemente policies seguras
  e autentique usuários em produção.
- Substitua `print()` por um logger estruturado antes de ir para produção.

Se quiser, eu posso:
- gerar um script que aplique/remoça policies temporárias via SQL;
- adicionar um botão de debug na UI que force sync manual e mostre a resposta bruta;
- ou varrer automaticamente o repositório para tornar outras chamadas ao
  Supabase tolerantes ao mesmo problema de formato de resposta.

Arquivo relacionado: `lib/features/providers/infrastructure/remote/supabase_providers_remote_datasource.dart`

```
```

``` 
