```markdown
# Supabase RLS Remediation (curto)

Objetivo
--------
Passos rápidos e seguros para validar/instrumentar e (temporariamente) permitir ações de escrita enquanto você testa a integração cliente.

1) Diagnóstico rápido via curl

```bash
# substitua SUPABASE_URL e SUPABASE_ANON_KEY
curl -i -X POST "${SUPABASE_URL}/rest/v1/providers" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"id":1234,"name":"curl-test","updated_at":"2025-11-27T00:00:00Z"}'
```

- Resposta 201/200 com JSON → permissões OK para `anon`.
- Resposta 4xx com texto `row-level security` / `42501` → RLS bloqueando.

2) Ajuste temporário (apenas para testes)

No Supabase SQL editor execute **apenas em ambiente de teste**:

```sql
CREATE POLICY "Allow anon insert providers" ON public.providers
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anon update providers" ON public.providers
  FOR UPDATE TO anon WITH CHECK (true);
```

3) Teste via curl e via app
- Rode o curl acima; se funcionar, reinicie o app e faça sync.

4) Reversão e boas práticas
- Depois de testar, remova as políticas temporárias e aplique políticas seguras:
  - Exigir autenticação: `FOR INSERT TO authenticated` (ou `auth.role() = 'authenticated'`)
  - Usar `auth.uid()` para filtrar por dono quando aplicável.

5) Segurança
- Nunca publique `service_role` key em clientes. Use `service_role` apenas em servidores confiáveis.

Se precisar, eu posso gerar um script SQL para aplicar/reverter as policies automaticamente.

```
```
