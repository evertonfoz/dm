````markdown
# Prompt operacional: Gerar DataSource remoto Supabase + Repository Impl

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
Antes de gerar os arquivos o agente deve:
1. Confirmar existência da interface remota (`ProvidersRemoteApi` ou parametrizada) e da interface de repositório (`<SUFFIX>Repository`).
2. Confirmar existência de DTO e Mapper.
3. Extrair o nome dos campos necessários (ex.: `id`, `updated_at`, etc.) da DTO para montar o select.

Arquivo 1: Supabase Remote Datasource Impl
-----------------------------------------
Nome sugerido: `supabase_<ENTITY_PLURAL>_remote_datasource.dart` ou `<ENTITY_PLURAL>_remote_datasource_supabase.dart`.
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

Arquivo 2: Repository Impl
--------------------------
Nome sugerido: `<ENTITY_PLURAL>_repository_impl.dart`.
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
5. `loadFromCache()` converte todos DTOs via mapper para entidade.
6. `listFeatured()` filtra `.featured` na entidade.
7. `getById()` usa DAO e mapper.
8. Ênfase em não duplicar lógica de parse já existente no mapper.
9. Usar sempre chaves em `if` / `try` / `catch` conforme convenções do projeto.

Docstrings & Estilo
-------------------
Cada método público deve ter comentário `///` explicando brevemente a função.
Usar português conforme arquivos existentes.
Constantes privadas: lowerCamelCase com underscore inicial (`_lastSyncKey`).

Checklist de validação
----------------------
- [ ] Imports mínimos (Supabase, DTO, mapper, DAO, interfaces).
- [ ] Nenhum print de segredo (keys). Só lógica de dados.
- [ ] Uso de `SharedPreferences` lazy (`SharedPreferences.getInstance()`).
- [ ] Sem dependência circular.
- [ ] Tratamento defensivo em parsing de datas.

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

Notas finais
------------
Para testar:
1. Mockar `ProvidersRemoteApi` retornando lista de DTOs;
2. Verificar que `localDao.upsertAll` é chamado e que o retorno é a contagem;
3. Verificar atualização de `_lastSyncKey` em SharedPreferences (pode mockar com um wrapper)
4. Testar `listFeatured()` com DTOs que possuam `metadata.featured = true`.

````