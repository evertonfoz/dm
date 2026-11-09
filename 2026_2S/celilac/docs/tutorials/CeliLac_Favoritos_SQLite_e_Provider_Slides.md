# Base para Slides de Aula: Favoritos, SQLite e Provider no CeliLac

## Estrutura didática por Problemas → Como Resolver → As Opções

> **Objetivo deste documento:** servir como roteiro e conteúdo-base para a geração de slides de aula sobre a **Etapa 5 do CeliLac (Favoritos, SQLite e Provider)**.
> Cada bloco de slides é organizado em torno de **três perguntas pedagógicas**:
> 1. **Qual é o problema real?** (de produto, de arquitetura ou de engenharia)
> 2. **Quais são as opções disponíveis?** (com vantagens, limites e quando usar cada uma)
> 3. **Como resolvemos na prática?** (código-chave, diagrama e validação)

---

## Visão geral da apresentação (Mapa de blocos)

| Bloco | Tema central | Slides sugeridos | Tempo estimado |
|---|---|---|---|
| **Bloco 1** | Do registro único à coleção de dados: o problema de favoritar *offline* | Slides 1 a 4 | 15 min |
| **Bloco 2** | Persistência local de coleções: `SharedPreferences` vs `SQLite` vs Nuvem | Slides 5 a 9 | 25 min |
| **Bloco 3** | Modelagem e evolução no SQLite: tipos, segurança (`?`) e migração (`onUpgrade`) | Slides 10 a 14 | 30 min |
| **Bloco 4** | Escala de estado compartilhado: do `InheritedNotifier` manual ao `provider` | Slides 15 a 19 | 25 min |
| **Bloco 5** | Desafios reais de UI e Acessibilidade: `Hero` em `IndexedStack` e cartão com 2 ações | Slides 20 a 23 | 20 min |
| **Bloco 6** | Testes de banco em memória (`sqflite_common_ffi`) e aplicação nos projetos | Slides 24 a 27 | 15 min |

---

# Bloco 1 — O Problema de Produto: Favoritos em Trânsito e Sincronizados

---

## Slide 1 — Capa

### Título
**Favoritos, Persistência Relacional com SQLite e Estado Compartilhado com Provider**

### Subtítulo
Como evoluir um aplicativo Flutter de **um registro simples** para **coleções consultáveis, migrações de banco sem perda de dados e múltiplos estados sincronizados**

### Elementos visuais sugeridos
- Linha de evolução do CeliLac:
  1. Splash + Onboarding (`bool`)
  2. Home + Shell (`FutureBuilder`)
  3. Detalhe do Estabelecimento (`Hero` + rotas)
  4. Perfil Alimentar (`JSON` + `InheritedNotifier`)
  5. **Favoritos (`SQLite` + `Provider`)** ← *Estamos aqui*

---

## Slide 2 — O Problema de Produto: "Encontrei um lugar seguro. E na semana que vem?"

### 1. O Problema
- Para quem tem doença celíaca ou intolerância à lactose, descobrir um estabelecimento seguro exige ler selos, conferir práticas contra contaminação cruzada e verificar horários.
- Sem uma lista de favoritos:
  - o usuário precisa **procurar tudo de novo** a cada saída;
  - quando está na rua (muitas vezes **sem internet ou com sinal fraco**), não consegue abrir rapidamente os lugares em que já confia.

### 2. O que a solução precisa entregar
1. **Marcar/desmarcar de qualquer lugar:** tanto no cartão da **Home** quanto na barra superior da **tela de detalhes**.
2. **Sincronia instantânea:** favoritou no detalhe e voltou? O coração na Home já está preenchido e a aba **Favoritos** já mostra o lugar.
3. **Acesso *offline* imediato:** a aba **Favoritos** precisa exibir os cartões completos mesmo sem conexão.

---

## Slide 3 — O que mudou em relação às etapas anteriores?

### Comparativo das 3 necessidades de armazenamento do CeliLac até aqui

| Etapa | O que guardamos? | Quantos registros? | Que perguntas fazemos aos dados? |
|---|---|---|---|
| **Etapa 1 — Onboarding** | `onboarding_completed` | **1 booleano** | *"Já viu a introdução?"* |
| **Etapa 4 — Perfil Alimentar** | `DietaryProfile` (nome, restrições, contaminação) | **1 único objeto** | *"Qual é o perfil atual desta pessoa?"* |
| **Etapa 5 — Favoritos** | Coleção de `Establishment` salvos | **0, 10, 50, 200 itens...** | *"Quais estão salvos (do mais recente ao mais antigo)?"*, *"O lugar `X` é favorito?"*, *"Adicione `Y`"*, *"Remova `Z`"* |

> **Nota para o professor:** destaque para a turma que mudar de **1 objeto** para **N objetos independentes** muda completamente o custo de leitura, gravação e busca.

---

## Slide 4 — Os 6 Problemas Técnicos desta Etapa

1. **Onde gravar uma coleção que cresce?** (`SharedPreferences` vs `SQLite` vs Nuvem)
2. **O que gravar na tabela?** (Apenas o `id` vs Instantâneo dos dados do cartão)
3. **Como traduzir objetos ricos do Dart para o SQLite e evoluir a tabela sem apagar os dados do usuário?** (`CREATE TABLE`, tipos, `?`, `onUpgrade`)
4. **Como responder `isFavorite(id)` rápido para dezenas de cartões na tela?** (`List` vs `Set`)
5. **Como compartilhar múltiplos estados (`ProfileController` + `FavoritesController`) sem repetir código manual?** (`InheritedNotifier` manual vs `provider`)
6. **Como evitar colisão de `Hero` e manter a acessibilidade quando o mesmo cartão aparece em duas abas e ganha um segundo botão?**

---

# Bloco 2 — Onde Guardar Coleções? E o que Guardar?

---

## Slide 5 — Problema 1: Onde persistir a coleção de favoritos?

### 1. O Problema
Quando o usuário toca no coração de **um** estabelecimento, queremos gravar ou remover **apenas aquele item**, consultar rapidamente se um `id` existe e listar todos em ordem de data (`saved_at DESC`).

### 2. As Opções

| Opção | Como funciona | Vantagens | Problemas / Limites |
|---|---|---|---|
| **A. `SharedPreferences` (JSON de lista inteira)** | Converte toda a `List<Establishment>` em uma única `String` JSON | Zero pacotes novos | A cada clique no coração, precisa **ler, decodificar, recodificar e regravar a lista inteira**; não filtra nem ordena no disco |
| **B. SQLite local (`sqflite`)** | Banco de dados relacional em arquivo `.db` no aparelho | Insere/remove **1 linha por vez**; índice na `PRIMARY KEY`; ordena com `ORDER BY`; migração de versão nativa | Exige modelar tabela, tipos SQL e conversão de linhas |
| **C. Banco em Nuvem (ex.: Supabase)** | Tabela remota acessada via internet | Sincroniza entre vários aparelhos do mesmo usuário | **Exige login e internet**; sem cache local, a aba Favoritos falha quando o usuário está *offline* |

### 3. Como Resolver (Nossa Escolha)
- Escolhemos a **Opção B (`SQLite` via `sqflite`)**, escondida atrás da interface `FavoritesRepository` (no `domain`).
- Assim, o app funciona **100% *offline* e sem exigir cadastro**, e no futuro podemos plugar a sincronização em nuvem sem tocar nas telas!

---

## Slide 6 — Visualizando a Diferença: JSON Único vs Tabela SQLite

### Diagrama para o slide

```text
SharedPreferences (1 chave = 1 string gigante):
┌────────────────────────────────────────────────────────────────┐
│ "favorites" → "[{\"id\":\"1\",...},{\"id\":\"2\",...}, ...]"   │
└────────────────────────────────────────────────────────────────┘
Para remover o id "2": lê tudo → converte tudo → filtra → regrava tudo!

SQLite (Tabela "favorites" com chave primária indexada):
┌────┬───────────────────┬──────────┬─────────────────┬───────────────┐
│ id │ name              │ category │ dietary_options │ saved_at      │
├────┼───────────────────┼──────────┼─────────────────┼───────────────┤
│ 1  │ Café Aconchego    │ cafe     │ glutenFree,...  │ 1762267200000 │
│ 2  │ Padaria Leve Grão │ bakery   │ glutenFree      │ 1762270800000 │
└────┴───────────────────┴──────────┴─────────────────┴───────────────┘
Para remover o id "2": DELETE FROM favorites WHERE id = '2' (1 linha!)
```

---

## Slide 7 — Problema 2: Guardar só o `id` ou guardar os dados do cartão?

### 1. O Problema
Já decidimos usar uma tabela `favorites` no SQLite. Mas quais colunas essa tabela deve ter?

### 2. As Opções

| Opção | Estrutura da tabela | O que acontece quando o usuário abre a aba Favoritos *offline*? |
|---|---|---|
| **Opção 1: Apenas o `id`** | `CREATE TABLE favorites (id TEXT PRIMARY KEY, saved_at INTEGER)` | O app sabe que os IDs `'1'` e `'3'` são favoritos, mas se o catálogo vier da rede e não houver internet, **não tem nome, bairro, nota nem selos para desenhar os cartões**! |
| **Opção 2: Instantâneo (*Snapshot*) do cartão** | Guarda `id`, `name`, `category`, `neighborhood`, `distance_in_km`, `rating`, `dietary_options`, `logo_source`, `saved_at` | A aba Favoritos **abre na hora e desenha todos os cartões *offline***, sem depender da rede! |

### 3. Como Resolver
- Adotamos a **Opção 2 (Instantâneo do cartão)**:
  - Resolve o caso de uso real (consultar seus lugares seguros na rua sem sinal).
  - Quando o usuário toca no cartão salvo para ver os detalhes completos (horários, fotos, telefone), aí sim a `EstablishmentDetailsPage` consulta o repositório de estabelecimentos.

---

## Slide 8 — O Contrato no Domínio: `FavoritesRepository`

### Por que começar pela interface em `domain/`?
- A camada de apresentação (`FavoritesController`) **não deve saber** que existe SQLite.
- Isso permite trocar a implementação real (`SqliteFavoritesRepository`) por uma implementação rápida em memória (`MemoryFavoritesRepository`) nos testes de interface.

```dart
abstract interface class FavoritesRepository {
  Future<List<Establishment>> loadAll();

  Future<bool> isFavorite(String establishmentId);

  Future<void> add(Establishment establishment, {DateTime? savedAt});

  Future<void> remove(String establishmentId);
}
```

> **Pergunta para a turma:** Por que `loadAll()` devolve `Future<List<Establishment>>` sem que a tela precise ordenar nada?
> *Resposta:* Porque a responsabilidade de entregar do mais recente para o mais antigo (`ORDER BY saved_at DESC`) é do repositório!

---

# Bloco 3 — Modelagem Relacional, Segurança e Evolução no SQLite

---

## Slide 9 — Problema 3: Os tipos do Dart não existem no SQLite!

### 1. O Problema
Nossa entidade `Establishment` em Dart usa `EstablishmentCategory` (`enum`), `Set<DietaryOption>`, `double`, `String?` e `DateTime`. Mas o SQLite só possui **5 classes de armazenamento** (`NULL`, `INTEGER`, `REAL`, `TEXT`, `BLOB`).

### 2. As Opções para representar tipos compostos (`DateTime`, `enum`, `Set`)

| Tipo no Dart | Opção A | Opção B | Qual escolhemos e por quê |
|---|---|---|---|
| **`DateTime` (`savedAt`)** | `TEXT` em ISO-8601 (`'2026-11-04T12:00Z'`) | `INTEGER` em `millisecondsSinceEpoch` | **`INTEGER`**: mais compacto e mais rápido para ordenar com `ORDER BY saved_at DESC` |
| **`enum` (`category`)** | `INTEGER` pelo índice (`.index`: `0, 1, 2`) | `TEXT` pelo nome (`.name`: `'cafe'`) | **`TEXT` (`.name`)**: se reordenarmos o `enum` no código, o `.index` corrompe os dados salvos; o `.name` continua legível e seguro |
| **`Set<DietaryOption>`** | Tabela auxiliar `favorite_options` com `JOIN` | `TEXT` separado por vírgulas (`'glutenFree,lactoseFree'`) | **`TEXT` com vírgulas**: como nunca filtramos uma opção isolada via SQL nos favoritos, evita um `JOIN` desnecessário mantendo simplicidade |

---

## Slide 10 — Traduzindo `Establishment` ↔ Linha SQLite (`Map<String, Object?>`)

### Como Resolver (`favorite_establishment_row.dart`)

```dart
extension FavoriteEstablishmentRow on Establishment {
  Map<String, Object?> toRow({required DateTime savedAt}) {
    final options =
        dietaryOptions.map((option) => option.name).toList()..sort();

    return {
      'id': id,
      'name': name,
      'category': category.name,
      'neighborhood': neighborhood,
      'distance_in_km': distanceInKm,
      'rating': rating,
      'dietary_options': options.join(','),
      'logo_source': logoSource,
      'saved_at': savedAt.millisecondsSinceEpoch,
    };
  }
}
```

### Duas defesas essenciais na leitura (`establishmentFromRow`)
1. **`(row['rating']! as num).toDouble()`**: protege contra valores inteiros (`5`) devolvidos por colunas `REAL`.
2. **Busca tolerante nos `enum`s (`.where(...).firstOrNull`)**: se um valor antigo mudar no futuro, o app não quebra ao abrir o banco do usuário.

---

## Slide 11 — Problema 4: Segurança nas Consultas e Conflitos de Chave Primária

### 1. O Problema
- Como filtrar pelo `id` em um `SELECT` ou `DELETE` sem abrir brecha para **Injeção de SQL (*SQL Injection*)** ou erros com aspas?
- O que acontece se `add()` for chamado para um `id` que já está salvo?

### 2. As Opções

| Situação | Abordagem Frágil (NÃO fazer) | Abordagem Profissional (Adotada) |
|---|---|---|
| **Passar parâmetros para o SQL** | Concatenar string: `where: "id = '$id'"` (quebra com aspas e permite injeção de SQL) | Usar marcador **`?`** + **`whereArgs: [id]`**: o SQLite trata o valor estritamente como dado |
| **Inserir item já existente** | Consultar antes com `SELECT` e decidir entre `INSERT` ou `UPDATE` (2 idas ao banco) | Usar **`ConflictAlgorithm.replace`** (`INSERT OR REPLACE` em 1 única operação atômica) |

### 3. Como fica no `SqliteFavoritesRepository`

```dart
@override
Future<void> add(Establishment establishment, {DateTime? savedAt}) async {
  final db = await _db;
  await db.insert(
    tableName,
    establishment.toRow(savedAt: savedAt ?? DateTime.now()),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

@override
Future<void> remove(String establishmentId) async {
  final db = await _db;
  await db.delete(tableName, where: 'id = ?', whereArgs: [establishmentId]);
}
```

---

## Slide 12 — Problema 5: O App Evoluiu! Como adicionar uma coluna sem apagar os dados do usuário?

### 1. O Problema
- Na **versão 1**, a tabela `favorites` não tinha a coluna `logo_source`.
- Na **versão 2**, os cartões passaram a exibir a logo do estabelecimento (`logo_source`).
- **Armadilha clássica:** para quem já tinha o app instalado no celular, o arquivo `celilac_favorites.db` **já existe no disco** — portanto, o SQLite **não executa `onCreate` de novo**!

### 2. As Opções quando o esquema muda

| Opção | O que faz | Consequência para o usuário |
|---|---|---|
| **1. Só mudar o `CREATE TABLE` sem mudar `version`** | Nada roda para usuários antigos | **Crash em produção:** `DatabaseException(no such column: logo_source)` |
| **2. `DROP TABLE favorites` + `CREATE TABLE` no `onUpgrade`** | Apaga a tabela antiga e cria a nova | Funciona sem erro técnico, mas **destrói todos os favoritos salvos pelo usuário**! |
| **3. Migração incremental (`ALTER TABLE` no `onUpgrade`)** | Mantém as linhas antigas e adiciona apenas a coluna nova (`logo_source TEXT`) | **Zero perda de dados**; usuários novos usam `onCreate` (já na v2) e usuários antigos rodam `onUpgrade` (`v1 → v2`) |

---

## Slide 13 — Como Resolver a Migração (`onCreate` + `onUpgrade`)

```dart
static const int schemaVersion = 2;

static Future<void> createSchema(Database db, int version) async {
  await db.execute('''
    CREATE TABLE $tableName (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      neighborhood TEXT NOT NULL,
      distance_in_km REAL NOT NULL,
      rating REAL NOT NULL,
      dietary_options TEXT NOT NULL,
      logo_source TEXT,
      saved_at INTEGER NOT NULL
    )
  ''');
}

static Future<void> upgradeSchema(
  Database db,
  int oldVersion,
  int newVersion,
) async {
  if (oldVersion < 2) {
    await db.execute(
      'ALTER TABLE $tableName ADD COLUMN logo_source TEXT',
    );
  }
}
```

```text
Usuário Novo (sem arquivo .db) ─────────► roda createSchema (já nasce na v2)
Usuário Antigo (tinha .db na v1) ───────► roda upgradeSchema (ALTER TABLE v1 → v2)
```

---

# Bloco 4 — Estado Compartilhado: Performance em Memória e Pacote `provider`

---

## Slide 14 — Problema 6: Como responder `isFavorite(id)` rápido para cada cartão?

### 1. O Problema
- A aba **Favoritos** precisa de uma coleção **ordenada** (do mais recente ao mais antigo).
- Mas a **Home** desenha vários cartões e, para **cada cartão**, pergunta `favorites.isFavorite(establishment.id)` durante o `build`.

### 2. As Opções em memória dentro do `FavoritesController`

| Opção | Estrutura interna | Ordem preservada? | Custo de `isFavorite(id)` |
|---|---|---|---|
| **A. Apenas `List<Establishment>`** | `list.any((e) => e.id == id)` | Sim | **`O(n)`** (percorre a lista inteira para cada cartão da tela) |
| **B. Apenas `Set<Establishment>`** | Conjunto sem índice de busca por `id` | Não é pensado para reordenação por data | Ainda precisaria comparar objetos ou `id` |
| **C. `List<Establishment>` + `Set<String> _favoriteIds`** | Lista para a ordem + Conjunto de IDs para consulta rápida | **Sim** | **`O(1)` instantâneo** (`_favoriteIds.contains(id)`) |

### 3. Como Resolver
Mantemos os dois sincronizados dentro do `FavoritesController`:
- `List<Establishment> get favorites` alimenta a `FavoritesPage`.
- `bool isFavorite(String id) => _favoriteIds.contains(id)` responde em `O(1)` para os cartões e para a `AppBar` do detalhe.

---

## Slide 15 — Problema 7: Dois Estados Globais (`Profile` + `Favorites`) — Como compartilhar na árvore?

### 1. O Problema
Na Etapa 4, tínhamos apenas o `ProfileController` e criamos manualmente a classe `ProfileScope extends InheritedNotifier<ProfileController>`.
Agora temos **dois** controladores globais (`ProfileController` e `FavoritesController`), e nas próximas etapas poderemos ter mais.

### 2. As Opções para compartilhar estado na árvore do Flutter

| Opção | Como funciona | Vantagens | Desvantagens quando o app cresce |
|---|---|---|---|
| **1. `InheritedNotifier` manual para cada estado** | Criar `ProfileScope`, `FavoritesScope`, transformar `CeliLacApp` em `StatefulWidget`, dar `initState` e `dispose` na mão | Zero pacotes externos; excelente para aprender o fundamento | Código repetido para cada novo estado; pirâmide de escopos aninhados; risco de esquecer `dispose()` |
| **2. Pacote `provider` (`MultiProvider` + `ChangeNotifierProvider`)** | Usa `InheritedWidget` por baixo, cria e descarta os `ChangeNotifier`s automaticamente e adiciona `context.watch` / `context.read` | Simples, oficial na documentação do Flutter, limpa o `CeliLacApp` (volta a ser `StatelessWidget`) | Exige disciplina entre `watch` (no `build`) e `read` (em cliques) |
| **3. `Riverpod` / `flutter_bloc`** | Arquiteturas completas de fluxos/eventos ou provedores compilados | Poderosos para regras assíncronas muito complexas | Curva de aprendizado e verbosidade maiores para esta etapa |

---

## Slide 16 — A Evolução na Prática: `ProfileScope` Manual vs `MultiProvider`

### Antes (Etapa 4 — Manual no `CeliLacApp` como `StatefulWidget`)
- Precisava de `_CeliLacAppState`, `initState()`, `dispose()` e da classe `ProfileScope`.

### Agora (Etapa 5 — `MultiProvider` no `CeliLacApp` como `StatelessWidget`)

```dart
class CeliLacApp extends StatelessWidget {
  const CeliLacApp({
    super.key,
    this.profileRepository,
    this.favoritesRepository,
  });

  final ProfileRepository? profileRepository;
  final FavoritesRepository? favoritesRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileController>(
          create: (_) => ProfileController(
            profileRepository ?? LocalProfileRepository(),
          ),
        ),
        ChangeNotifierProvider<FavoritesController>(
          create: (_) => FavoritesController(
            favoritesRepository ?? SqliteFavoritesRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        // ...
        home: const SplashPage(),
      ),
    );
  }
}
```

---

## Slide 17 — A Regra de Ouro do `provider`: `context.watch` vs `context.read`

| Pergunta | `context.watch<T>()` | `context.read<T>()` |
|---|---|---|
| **Substitui o quê da Etapa 4?** | `ProfileScope.of(context)` | `ProfileScope.read(context)` |
| **Onde deve ser chamado?** | **Apenas dentro do `build(context)`** | **Em cliques (`onPressed`, `onTap`), métodos `_save()` / `_toggle()` e `initState()`** |
| **Reagenda `build` quando o estado muda?** | **Sim** (o widget vira ouvinte) | **Não** (apenas pega a referência para chamar um método) |
| **Exemplo real no CeliLac** | `final favorites = context.watch<FavoritesController>();` na `HomePage` e na `FavoritesPage` | `await context.read<FavoritesController>().toggle(establishment);` ao tocar no coração |

---

## Slide 18 — Inicialização em Paralelo na `SplashPage`

### 1. O Problema
Agora o app precisa ler **três fontes locais** ao abrir:
1. `OnboardingStorage().isCompleted()` (`SharedPreferences`)
2. `ProfileController.load()` (`SharedPreferences` JSON)
3. `FavoritesController.load()` (`SQLite`)

Se esperarmos uma terminar para começar a outra (`await a; await b; await c;`), somamos os tempos de espera!

### 2. Como Resolver: Disparo paralelo com `Record.wait`

```dart
final profileLoad = context.read<ProfileController>().load();
final favoritesLoad = context.read<FavoritesController>().load();

await _introController.forward();
await _progressController.forward();

final (completed, _, _) = await (
  OnboardingStorage().isCompleted(),
  profileLoad,
  favoritesLoad,
).wait;
```

---

# Bloco 5 — Desafios Reais de Interface e Acessibilidade

---

## Slide 19 — Problema 8: Colisão de `Hero` entre Abas Vivas no `IndexedStack`

### 1. O Problema
- O `AppShell` usa um **`IndexedStack`**, que mantém a **`HomePage` (aba 0)** e a **`FavoritesPage` (aba 2)** montadas na árvore ao mesmo tempo.
- Quando o usuário favorita o **Café Aconchego (`id: '1'`)**, o cartão dele passa a existir **nas duas abas simultaneamente**.
- Se ambos os cartões usarem `Hero(tag: 'establishment-icon-1')`, o Flutter quebra na transição com:
  > `There are multiple heroes that share the same tag within a subtree.`

### 2. As Opções

| Opção | Como funciona | Veredito |
|---|---|---|
| **A. Trocar `IndexedStack` por troca simples de widget** | Destrói a aba anterior ao trocar | Perde a posição de rolagem da Home sempre que o usuário visita outra aba |
| **B. Remover a animação `Hero` na aba Favoritos** | Só a Home anima a logo | Experiência inconsistente entre abas |
| **C. Prefixar a tag do `Hero` com a aba de origem (`origin`)** | `'home-establishment-icon-1'` na Home e `'favorites-establishment-icon-1'` nos Favoritos | **Mantém o `IndexedStack` e preserva a animação `Hero` nas duas abas!** |

### 3. Como Resolver

```dart
String establishmentHeroTag(
  String establishmentId, {
  String origin = 'home',
}) => '$origin-establishment-icon-$establishmentId';
```

---

## Slide 20 — Problema 9: Um Cartão com Duas Ações de Toque e a Armadilha do `MergeSemantics`

### 1. O Problema
- Na Etapa 2, o `EstablishmentCard` tinha **1 única ação** (abrir detalhes) e usava `MergeSemantics` na raiz do cartão.
- Agora o cartão tem **2 ações independentes**:
  1. Tocar no corpo do cartão → abre `EstablishmentDetailsPage`.
  2. Tocar no `FavoriteButton` (coração) → salva ou remove dos favoritos **sem abrir os detalhes**.
- **Armadilha:** se o `MergeSemantics` continuar envolvendo o cartão inteiro, ele **absorve o `FavoriteButton` dentro do nó do cartão**, impedindo que usuários de leitores de tela (*TalkBack* / *VoiceOver*) acionem o botão de favoritar!

### 2. Como Resolver
1. Retiramos o `MergeSemantics` global do cartão: o `InkWell` já agrupa automaticamente os textos informativos, e o `FavoriteButton` (`IconButton`) permanece como um **nó semântico separado de `48×48 dp`**.
2. Damos ao `FavoriteButton` um `tooltip` que inclui o **nome do lugar**:
   - `'Salvar Café Aconchego nos favoritos'`
   - `'Remover Café Aconchego dos favoritos'`
3. Posicionamos o coração **abaixo da nota** (em uma `Column` à direita) em vez de ao lado, evitando *overflow* em telas de `320 px` com fonte a `200%`.

---

# Bloco 6 — Testes de SQLite em Memória e Aplicação nos Projetos

---

## Slide 21 — Problema 10: Como testar SQL real sem emulador e sem sujar o disco?

### 1. O Problema
- O plugin `sqflite` padrão depende dos canais nativos do Android/iOS (não roda sozinho no `flutter test` do computador).
- Mas se testarmos apenas o `MemoryFavoritesRepository`, **quem garante que o nosso `CREATE TABLE`, `ALTER TABLE` e `ORDER BY saved_at DESC` estão com a sintaxe SQL correta?**

### 2. Como Resolver: `sqflite_common_ffi` + `inMemoryDatabasePath`

```dart
Future<Database> _openInMemoryDatabase() {
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: SqliteFavoritesRepository.schemaVersion,
      onCreate: SqliteFavoritesRepository.createSchema,
      onUpgrade: SqliteFavoritesRepository.upgradeSchema,
      singleInstance: false, // isola cada banco em memória!
    ),
  );
}
```

- Executa o **motor real do SQLite** na memória RAM em milissegundos.
- Permite testar inclusive a **migração da versão 1 para a versão 2 (`upgradeSchema`)** criando uma tabela v1, inserindo dados, rodando `upgradeSchema(v1Db, 1, 2)` e conferindo que os dados antigos continuam lá!

---

## Slide 22 — Resumo Executivo: Problemas × Soluções × Opções

| # | Problema | Opções avaliadas | Solução adotada no CeliLac |
|---|---|---|---|
| 1 | Persistir coleção de favoritos | `SharedPreferences` vs `SQLite` vs Nuvem | **`SQLite` (`sqflite`)** por trás de `FavoritesRepository` |
| 2 | O que guardar na tabela | Só o `id` vs Instantâneo do cartão | **Instantâneo do cartão** (funciona 100% *offline*) |
| 3 | Tipos compostos no SQLite | Índices numéricos / tabelas extras vs `.name` / `epoch ms` | `enum.name` (`TEXT`), `Set` com vírgula (`TEXT`) e `DateTime` em `INTEGER` |
| 4 | Evoluir a tabela sem perder dados | `DROP TABLE` vs `ALTER TABLE` no `onUpgrade` | **`version: 2` + `onUpgrade` com `ALTER TABLE`** |
| 5 | Consulta rápida `isFavorite(id)` | Busca linear em `List` `O(n)` vs `List` + `Set` `O(1)` | **`List<Establishment>` + `Set<String> _favoriteIds`** |
| 6 | Múltiplos estados globais | Vários `InheritedNotifier` manuais vs `provider` | **`MultiProvider` + `ChangeNotifierProvider`** (`watch` / `read`) |
| 7 | Colisão de `Hero` no `IndexedStack` | Desligar `Hero` vs Tag com origem | **`'$origin-establishment-icon-$id'`** |
| 8 | Testar SQL no `flutter test` | Só dublê em memória vs SQLite FFI em memória | **Ambos**: `MemoryFavoritesRepository` nas telas + `sqflite_common_ffi` no repositório |

---

## Slide 23 — Atividade Prática: Aplicando no Projeto de Cada Grupo

### Roteiro para os alunos executarem em seus projetos
1. **Identificar a coleção local do seu domínio:** cursos salvos, imóveis favoritos, vagas marcadas, receitas guardadas ou profissionais de saúde favoritos.
2. **Definir o contrato (`domain`) e a tabela (`data`):** criar a tabela no SQLite com `id PRIMARY KEY`, `saved_at INTEGER` e as colunas necessárias para desenhar o cartão *offline*.
3. **Migrar para `provider`:** configurar `MultiProvider` acima do `MaterialApp` e sincronizar o botão de favoritar entre a listagem principal, a tela de detalhes e a aba de salvos.
4. **Provar com testes automatizados:**
   - Conversão de linha (`toRow` / `fromRow`)
   - Banco SQLite em memória com `sqflite_common_ffi` (incluindo 1 teste de `onUpgrade`)
   - Acessibilidade (`meetsGuideline`) e fonte a `200%` em tela `320×640`

