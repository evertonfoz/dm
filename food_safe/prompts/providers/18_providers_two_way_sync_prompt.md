# 18 - Implementar sincronização bidirecional de Fornecedores (Push então Pull) — versão didática

**Este prompt foi adaptado para fins didáticos.** As alterações e implementações devem conter comentários explicativos, dicas práticas, checklist de erros comuns, exemplos de logs esperados e referências aos arquivos de debug, facilitando o aprendizado e a implementação correta pelos alunos.

Resumo
------
Esta mudança implementa um fluxo de sincronização bidirecional para `Fornecedores` entre o cache local (DAO baseado em SharedPreferences) e o Supabase. O repositório agora realiza um push (melhor esforço) dos itens do cache local para o remoto e, em seguida, faz um pull das deltas remotas (desde o último sync bem-sucedido) aplicando-as localmente.

Arquivos alterados
------------------
- `lib/features/providers/infrastructure/remote/providers_remote_api.dart`
  - Adicionada a assinatura `Future<int> upsertProviders(List<ProviderDto> dtos);` na interface para permitir upserts em lote pelos datasources.

- `lib/features/providers/infrastructure/remote/supabase_providers_remote_datasource.dart`
  - Implementado `upsertProviders` usando a API `upsert` do cliente Supabase.
  - Envia mapas de DTO para a tabela `providers` e retorna o número de linhas reconhecidas pelo servidor (melhor esforço).

- `lib/features/providers/infrastructure/repositories/providers_repository_impl.dart`
  - Atualizado `syncFromServer()` para realizar:
    1. Push: ler o cache local (`ProvidersLocalDao.listAll()`), chamar `remoteApi.upsertProviders(local)` (melhor esforço; falhas são ignoradas para não bloquear o pull).
    2. Pull: buscar atualizações remotas desde `lastSync` e aplicar via `localDao.upsertAll()`.
    3. Atualizar o marcador `lastSync` usando o maior `updated_at` dos itens remotos aplicados.


Notas de design e justificativa
------------------------------
- Fazemos o push de todo o cache local porque o DAO atual não rastreia flags "dirty" por item; isso mantém a implementação simples e segura para apps onde o cache local é a fonte autoritativa das edições do usuário.
- O push é "best-effort": falhas de rede ou do remoto não impedem que o repositório faça o pull; o push será tentado novamente no próximo sync.
- O pull usa timestamps `updated_at` para buscar mudanças incrementais e confia em timestamps do servidor para resolver conflitos (Last-Write-Wins por timestamp).
- **Inclua comentários explicativos em cada etapa do fluxo de sync, detalhando o motivo de cada ação e boas práticas (ex.: usar try/catch, logs para debug, não bloquear a UI).**
- **Adicione prints/logs (usando `kDebugMode`) nos pontos principais do fluxo para facilitar o diagnóstico de problemas de push/pull e integração.** Exemplo de log esperado:
```dart
if (kDebugMode) {
  print('ProvidersRepositoryImpl.syncFromServer: pushed $pushed items to remote');
}
```


Como verificar
--------------
1. Rodar análise estática:

```bash
flutter analyze
```

2. Executar o app com `SUPABASE_URL` e `SUPABASE_ANON_KEY` válidos. Passos sugeridos:
  - Inicie o app em um dispositivo/emulador com cache local limpo.
  - Adicione ou edite um fornecedor localmente; abra o app em outro cliente (ou atualize via dashboard) e rode o sync; verifique que ambos os lados convergem.
  - **Verifique os logs no console para mensagens como:**
    - ProvidersRepositoryImpl.syncFromServer: pushed 3 items to remote
    - SupabaseProvidersRemoteDatasource.upsertProviders: sending 3 items
    - Supabase upsert response error: ...
    - ProvidersRepositoryImpl.syncFromServer: aplicados 3 registros ao cache

3. Observe os logs (modo dev/debug) para erros de push; a implementação ignora falhas de push para não bloquear o pull, mas sempre registra o erro para facilitar o diagnóstico.
  - **Checklist de erros comuns e como evitar:**
    - Erro de conversão de tipos: garanta que o DTO/entidade aceita múltiplos formatos vindos do backend.
    - Falha ao atualizar UI após sync: sempre verifique se o widget está `mounted` antes de chamar `setState`.
    - Dados não aparecem após sync: adicione prints/logs para inspecionar o conteúdo do cache e o fluxo de conversão.
    - Problemas de integração com Supabase (RLS, inicialização): consulte `supabase_rls_remediation.md` e `supabase_init_debug_prompt.md`.

Próximos passos sugeridos (Follow-ups)
-------------------------------------
- O DAO pode suportar IDs temporários e um mapeamento que substitua IDs temporários pelos IDs atribuídos pelo servidor após o upsert. Isso exige lógica de reconciliação mais complexa e testes adicionais.

Alterações adicionais (diagnósticos & sync na inicialização)
---------------------------------------------------------
Após implementar a sincronização bidirecional descrita acima, apliquei três pequenas alterações operacionais para ajudar a diagnosticar falhas de push e garantir que itens do cache sejam enviados ao Supabase mesmo quando o cache não está vazio:

- Sincronizar sempre na inicialização da UI:
  - Arquivo: `lib/features/providers/presentation/providers_page.dart`
  - Comportamento: `_loadProviders()` agora carrega o cache local para responsividade imediata da UI e, em seguida, sempre chama `ProvidersRepositoryImpl.syncFromServer()` (push então pull). Durante o sync a página exibe um `LinearProgressIndicator` no topo.
  - Justificativa: anteriormente o sync rodava apenas quando o cache local estava vazio, o que fazia com que itens armazenados localmente nunca fossem enviados ao remoto se já existissem localmente.

- Prints de diagnóstico no datasource Supabase:
  - Arquivo: `lib/features/providers/infrastructure/remote/supabase_providers_remote_datasource.dart`
  - Comportamento: `upsertProviders()` agora registra no console a quantidade de itens enviados, `response.error` e `response.data.length`. Isso ajuda a identificar erros de RLS/permissão ou problemas de esquema retornados pelo Supabase.
  - Observação: esses prints são para depuração; podem ser envoltos por `if (kDebugMode)` ou substituídos por um logger antes de irem para produção.

- Print de diagnóstico no repositório:
  - Arquivo: `lib/features/providers/infrastructure/repositories/providers_repository_impl.dart`
  - Comportamento: após chamar `remoteApi.upsertProviders(local)` o repositório registra quantos itens foram empurrados: `print('ProvidersRepositoryImpl: pushed $pushed items to remote')`.


Como isso ajuda no diagnóstico
-----------------------------
- Se o app printa `sending N items` mas `response.error` não é nulo, o texto do erro provavelmente é um erro PostgREST/Supabase (ex.: violação de RLS ou payload malformado). Consulte os arquivos de debug do projeto para exemplos e soluções.
- Se `response.error` for `null` mas `data.length` for `0`, o upsert pode ter sido aceito pelo PostgREST mas retornado sem linhas (verifique o schema da tabela e o comportamento de `RETURNING` no Supabase).
- **Referências úteis:**
  - providers_cache_debug_prompt.md
  - supabase_init_debug_prompt.md
  - supabase_rls_remediation.md

Recomendações finais
-------------------
- Torne os logs de debug condicionais a `kDebugMode` para evitar `print` em builds de produção.
- Se o push for bem-sucedido mas as linhas não aparecem no Dashboard, verifique as políticas de RLS para a tabela `providers` e a role `anon`.

**IMPORTANTE: RefreshIndicator no estado vazio da lista**
-----------------------------------------------------
⚠️ **Erro comum**: após implementar a sincronização bidirecional, se a lista estiver vazia e você apenas mostrar uma mensagem "Nenhum item" sem envolver em `RefreshIndicator`, o usuário não conseguirá puxar para baixo para sincronizar e buscar registros do Supabase.

**Solução**: sempre envolva o estado de lista vazia com `RefreshIndicator` + `ListView` usando `AlwaysScrollableScrollPhysics()` para habilitar pull-to-refresh mesmo ao iniciar com cache vazio. Isso permite que o usuário:
1. Puxe para baixo na tela vazia
2. Acione `_loadProviders()` que chama `syncFromServer()`
3. Faça o push de mudanças locais e o pull de atualizações remotas
4. Veja os itens sincronizados aparecerem na lista

Veja o prompt 12 (`12_agent_list_refresh.md`) para o exemplo completo de implementação.

# Observações adicionais

1. Caso o prompt proponha criar algum arquivo que já exista no projeto: renomeie a versão existente para `*.backup` e remova-a antes de criar o novo arquivo.
2. Crie o novo arquivo conforme o prompt.
3. Garanta que a definição da classe esteja declarada apenas uma vez no código.
4. Se o arquivo gerado for grande, considere refatorar extraindo partes para subpastas e arquivos menores.
5. Ao refatorar e reorganizar, remova os arquivos antigos para evitar wrappers redundantes ou documentação desatualizada.