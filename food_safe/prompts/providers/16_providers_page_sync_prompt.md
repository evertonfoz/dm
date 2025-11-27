````markdown
# Prompt operacional: Integrar sincronização Supabase na `ProvidersPage`

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

3. Manter o comportamento atual do tutorial/indicator caso a lista permaneça vazia.

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

````
