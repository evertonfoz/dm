# Prompt operacional: Gerar DataSource remoto Supabase + Repository Impl (versão didática)

> **Este prompt foi adaptado para fins didáticos. O código gerado deve conter comentários explicativos, exemplos de uso (em comentário), dicas práticas e checklist de erros comuns, facilitando o aprendizado e a implementação correta pelos alunos.**

Objetivo
--------
Gerar dois arquivos Dart para uma feature de domínio:
1. Implementação concreta do remote datasource (`<entity_plural>_remote_datasource_supabase.dart`) que acessa uma tabela Supabase.
2. Implementação concreta do repositório (`<entity_plural>_repository_impl.dart`) que usa o remote API + DAO local.

Parâmetros (substitua antes de executar)
---------------------------------------
- ENTITY: nome da entidade em PascalCase (ex.: `Provider`).
- ENTITY_PLURAL: forma plural usada para tabela/pastas (ex.: `providers`).
- TABLE_NAME (opcional): nome da tabela Supabase; padrão = ENTITY_PLURAL.
- DEST_DIR_REMOTE (opcional): diretório destino para o arquivo remoto. Padrão: `lib/features/<ENTITY_PLURAL>/infrastructure/remote/`.
- DEST_DIR_REPO (opcional): diretório destino para o repositório impl. Padrão: `lib/features/<ENTITY_PLURAL>/infrastructure/repositories/`.
- DAO_IMPORT_PATH (opcional): import para DAO local, ex.: `../local/<ENTITY_PLURAL>_local_dao.dart`.
- MAPPER_IMPORT_PATH (opcional): import para mapper (DTO -> entidade), ex.: `../mappers/<entity>_mapper.dart`.
- DTO_IMPORT_PATH (opcional): import para DTO, ex.: `../dtos/<entity>_dto.dart`.
- REMOTE_API_INTERFACE_IMPORT (opcional): caminho da interface remota, ex.: `providers_remote_api.dart`.
 - REPOSITORY_INTERFACE_IMPORT: caminho da interface do repositório de domínio.


Investigação obrigatória
------------------------
Antes de gerar os arquivos, o agente deve:
1. Confirmar existência da interface remota (`ProvidersRemoteApi` ou parametrizada) e da interface de repositório (`<SUFFIX>Repository`).
2. Confirmar existência de DTO e Mapper.
3. Extrair o nome dos campos necessários (ex.: `id`, `updated_at`, etc.) da DTO para montar o select.
4. **Verificar se os métodos de conversão (fromMap/toMap) do DTO e Mapper são robustos para aceitar diferentes formatos de dados vindos do backend (ex: id como int/string, datas como DateTime/String).**
5. **Consultar os arquivos de debug do projeto (ex: providers_cache_debug_prompt.md, supabase_init_debug_prompt.md, supabase_rls_remediation.md) para exemplos de logs, prints e soluções de problemas reais.**


Arquivo 1: Supabase Remote Datasource Impl
------------------------------------------
Nome sugerido: `supabase_<ENTITY_PLURAL>_remote_datasource.dart` ou `<ENTITY_PLURAL>_remote_datasource_supabase.dart`.

**Inclua no topo do arquivo um comentário explicando o papel do datasource remoto e dicas para evitar erros comuns, como:**
- Garanta que o DTO e o Mapper aceitam múltiplos formatos vindos do backend (ex: id como int/string, datas como DateTime/String).
- Sempre adicione prints/logs (usando kDebugMode) nos métodos de fetch/upsert mostrando o conteúdo dos dados recebidos e convertidos.
- Envolva parsing de datas, conversão de tipos e chamadas externas em try/catch, logando o erro e retornando valores seguros.
- Não exponha segredos (keys) em prints/logs.
- Consulte os arquivos de debug do projeto para exemplos de logs e soluções de problemas reais.

Requisitos:
1. Classe: `Supabase<ENTITY_PLURAL_Pascal>RemoteDatasource` implementando a interface remota (`ProvidersRemoteApi` ou equivalente).
2. Construtor aceita `SupabaseClient? client` (fallback para `SupabaseService().client`).
3. Método `fetch<ENTITY_PLURAL_Pascal>` (ou `fetchProviders` conforme interface) implementa:
  - Filtro `since` (`.gte('updated_at', since.toIso8601String())` se passado).
  - Ordenação por `updated_at DESC`.
  - Paginação por offset (`range(offset, offset+limit-1)`), lendo offset de `PageCursor.value` se inteiro.
4. Mapeia rows para DTO usando `.fromMap`.
5. Retorna `RemotePage<Dto>` com `next` se tamanho == limit.
6. Tratamento de erro: em qualquer exceção retorna página vazia (`RemotePage(items: [])`).
7. Não incluir lógica de cache aqui.
8. **Adicione prints/logs (usando kDebugMode) nos principais pontos do fluxo para facilitar o diagnóstico de problemas de integração e conversão. Exemplo de log esperado:**
```dart
if (kDebugMode) {
  print('SupabaseProvidersRemoteDatasource.fetchProviders: recebidos \\${rows.length} registros');
}
```
9. **Ao final do arquivo, inclua um bloco de comentário com exemplo de uso e checklist de erros comuns.**


Arquivo 2: Repository Impl
--------------------------
Nome sugerido: `<ENTITY_PLURAL>_repository_impl.dart`.

**Inclua no topo do arquivo um comentário explicando o papel do repositório, a importância de separar lógica de sync/cache, e dicas para evitar erros comuns, como:**
- Sempre verifique se o widget está mounted antes de chamar setState em métodos assíncronos.
- Adicione prints/logs (usando kDebugMode) nos métodos de sync, cache e conversão para facilitar o diagnóstico.
- Use tratamento defensivo em parsing de datas e conversão de tipos.
- Consulte os arquivos de debug do projeto para exemplos de logs e soluções de problemas reais.

Requisitos:
1. Classe: `<ENTITY_PLURAL_Pascal>RepositoryImpl` implementando interface `<SUFFIX>Repository`.
2. Recebe `ProvidersRemoteApi remoteApi` (parametrizado) e DAO local no construtor.
3. Mantém chave de last sync (`<entity_plural>_last_sync_vX`). Versão `vX` deve ser incrementável.
4. `syncFromServer()`:
  - Lê last sync de SharedPreferences.
  - Chama `remoteApi.fetchProviders(since: lastSync)` com limite adequado (ex.: 500).
  - Upsert dos itens via DAO.
  - Atualiza marcador com maior `updated_at` retornado ou `DateTime.now().toUtc()` se falhar parsing.
  - Retorna quantidade de itens aplicados.
  - **Adicione prints/logs (usando kDebugMode) nos principais pontos do fluxo para facilitar o diagnóstico de problemas de sync, cache e conversão.**
5. `loadFromCache()` converte todos DTOs via mapper para entidade.
6. `listFeatured()` filtra `.featured` na entidade.
7. `getById()` usa DAO e mapper.
8. Ênfase em não duplicar lógica de parse já existente no mapper.
9. Usar sempre chaves em `if` / `try` / `catch` conforme convenções do projeto.
10. **Ao final do arquivo, inclua um bloco de comentário com exemplo de uso, checklist de erros comuns, exemplos de logs esperados e referências aos arquivos de debug do projeto.**


Docstrings & Estilo
-------------------
Cada método público deve ter comentário `///` explicando brevemente a função.
Usar português conforme arquivos existentes.
Constantes privadas: lowerCamelCase com underscore inicial (`_lastSyncKey`).
**Inclua comentários explicativos detalhando o papel de cada classe, método e principais pontos de atenção.**


Checklist de validação
----------------------
- [ ] Imports mínimos (Supabase, DTO, mapper, DAO, interfaces).
- [ ] Nenhum print de segredo (keys). Só lógica de dados.
- [ ] Uso de `SharedPreferences` lazy (`SharedPreferences.getInstance()`).
- [ ] Sem dependência circular.
- [ ] Tratamento defensivo em parsing de datas.
- [ ] Comentários explicativos e exemplos de uso presentes.
- [ ] Prints/logs (kDebugMode) nos principais fluxos para debug.

Exemplo reduzido de trecho (Repository Impl - sync):
```dart
final prefs = await _prefs;
final lastSyncIso = prefs.getString(_lastSyncKey);
DateTime? since;
if (lastSyncIso != null && lastSyncIso.isNotEmpty) {
  try {
    since = DateTime.parse(lastSyncIso);
  } catch (_) {}
}
final page = await remoteApi.fetchProviders(since: since, limit: 500);
if (page.items.isEmpty) {
  return 0;
}
await localDao.upsertAll(page.items);
final newest = _computeNewest(page.items);
await prefs.setString(_lastSyncKey, newest.toIso8601String());
return page.items.length;
```


---

### Exemplo de bloco de comentário para o final de cada arquivo gerado:

```dart
/*
// Exemplo de uso:
final remote = SupabaseProvidersRemoteDatasource();
final dao = ProvidersLocalDaoSharedPrefs();
final repo = ProvidersRepositoryImpl(remoteApi: remote, localDao: dao);
final lista = await repo.listAll();

// Checklist de erros comuns e como evitar:
// - Erro de conversão de tipos (ex: id como string): ajuste o fromMap/toMap do DTO para aceitar múltiplos formatos.
// - Falha ao atualizar UI após sync: verifique se o widget está mounted antes de chamar setState.
// - Dados não aparecem após sync: adicione prints/logs para inspecionar o conteúdo do cache e o fluxo de conversão.
// - Problemas com Supabase (RLS, inicialização): consulte supabase_rls_remediation.md e supabase_init_debug_prompt.md.

// Exemplo de logs esperados:
// SupabaseProvidersRemoteDatasource.fetchProviders: recebidos 3 registros
// ProvidersRepositoryImpl.syncFromServer: aplicados 3 registros ao cache

// Referências úteis:
// - providers_cache_debug_prompt.md
// - supabase_init_debug_prompt.md
// - supabase_rls_remediation.md
*/
```

# Observações adicionas

1. Caso o prompt proponha criar algum arquivo e esse arquivo já existir no projeto. Renomeie-o para .backup. E em seguida o remova.
2. Crie o novo arquivo
3. Garanta que a definição da classe do arquivo esteja escrita uma única vez no código
4. Caso o arquivo gerado ou arquivos manipulados por esse prompt seja grandes (avalie profissionalmete isso), procure refatorar, extraindo para arquivos organizados em subpastas
5. Ao refatorar e organizar, remova os arquivos antigos. Não deixe o arquivo apenas como wrappers ou comentários orientando a remoção manual.