# CeliLac: Favoritos, SQLite e Provider no Flutter

## Persistência relacional, migração de esquema e estado compartilhado em múltiplas telas

---

## Como usar este material

Este é o **quinto material** da série de construção do **CeliLac**, um aplicativo para pessoas com restrição ao glúten (doença celíaca, sensibilidade não celíaca) e à lactose. Nos materiais anteriores, o aplicativo ganhou:

1. **Splash e Onboarding** (`CeliLac_Splash_e_Onboarding.md`) — identidade visual, animações de entrada, carrossel de apresentação e uma flag booleana no `SharedPreferences`.
2. **HomePage e AppShell** (`CeliLac_HomePage.md`) — shell de navegação com quatro abas, tema centralizado, modelo de domínio e busca assíncrona com `FutureBuilder`.
3. **Detalhe do Estabelecimento** (`CeliLac_Detalhe_Estabelecimento.md`) — navegação mestre-detalhe, animação `Hero`, carrossel de fotos e abertura de mapa e telefone.
4. **Perfil Alimentar** (`CeliLac_Perfil_Alimentar.md`) — formulário validado, persistência de **um registro único** em JSON no `SharedPreferences` e estado compartilhado feito à mão com `ChangeNotifier` + `InheritedNotifier` (`ProfileScope`).

Naquele quarto material, duas promessas ficaram registradas para esta etapa:

- Na **Parte 3.5**, vimos que o `SharedPreferences` era adequado para **um único registro pequeno** (o perfil alimentar), mas que **coleções que crescem, precisam ser consultadas por identificador e ordenadas por data** pedem um **banco de dados local (`SQLite`)**.
- Na **Parte 10.3**, vimos que construir `ProfileScope` à mão com `InheritedNotifier` ensinou como a árvore do Flutter propaga mudanças, e que quando o aplicativo passasse a ter **mais de um estado compartilhado** (Perfil **e** Favoritos), daríamos o próximo passo natural do mercado: substituir o escopo manual pelo pacote **`provider`** (`MultiProvider`, `ChangeNotifierProvider`, `context.watch` e `context.read`).

Neste quinto material, cumprimos essas duas promessas dando vida à **terceira aba da barra inferior (`Favoritos`)** e permitindo salvar ou remover estabelecimentos tanto nos cartões da **Home** quanto na barra superior da **tela de detalhes** — com tudo sincronizado na hora e disponível mesmo sem internet.

Duas marcações aparecem ao longo do texto:

- **No CeliLac** — o código exato deste projeto.
- **No seu projeto** — como adaptar a mesma decisão para outro domínio (cursos salvos, imóveis favoritos, vagas marcadas, receitas guardadas, pacientes acompanhados).

### Pré-requisitos

Este material parte do projeto como ele terminou no tutorial do **Perfil Alimentar**:

```text
lib/
├── main.dart
├── app/
│   ├── celilac_app.dart
│   ├── common/
│   ├── routes/
│   ├── shell/
│   │   └── app_shell.dart
│   └── theme/
└── features/
    ├── startup/
    ├── onboarding/
    ├── establishments/
    ├── home/
    └── profile/
```

Antes de começar, confirme que o projeto está limpo:

```bash
flutter analyze
flutter test
```

### Ao final deste material, você será capaz de

1. Decidir com critério técnico entre **`SharedPreferences`**, **banco de dados local (`SQLite`)** e **banco em nuvem**, entendendo o que cada um resolve.
2. Projetar uma **tabela relacional no SQLite** (`CREATE TABLE`, `PRIMARY KEY`, `NOT NULL`) e mapear tipos ricos do Dart (`enum`, `Set`, `DateTime`, `double`) para os tipos de armazenamento do SQLite (`TEXT`, `INTEGER`, `REAL`).
3. Escrever consultas seguras com **parâmetros `?` (`whereArgs`)**, evitando **injeção de SQL** (*SQL Injection*), e ordenar resultados no próprio banco (`ORDER BY saved_at DESC`).
4. Evoluir a estrutura do banco sem apagar os dados do usuário usando **versões de esquema e `onUpgrade` (`ALTER TABLE`)**.
5. Substituir um `InheritedNotifier` manual pelo pacote **`provider`**, combinando múltiplos estados no topo do app com **`MultiProvider`** e **`ChangeNotifierProvider`**.
6. Usar **`context.watch<T>()`** (para reconstruir a tela quando o estado muda) e **`context.read<T>()`** (para disparar ações em cliques e no `initState` sem assinar reconstruções).
7. Resolver colisões de **`Hero`** quando a mesma entidade aparece em mais de uma aba mantida viva por um **`IndexedStack`**.
8. Manter a **acessibilidade** de um cartão que possui **duas ações de toque independentes** (abrir os detalhes e favoritar), respeitando áreas mínimas de `48×48 dp` e rótulos semânticos claros.
9. Testar um repositório SQLite **em memória (`inMemoryDatabasePath`)** no computador com **`sqflite_common_ffi`**, incluindo o teste automatizado da **migração da versão 1 para a versão 2**.

---

# Parte 0: Antes do código — os três problemas desta etapa

Antes de instalar pacotes ou criar pastas, vale entender **quais problemas reais** estamos resolvendo e por que as ferramentas das etapas anteriores não bastam.

## 0.1 Por que uma pessoa com restrição alimentar precisa de favoritos *offline*?

Encontrar um restaurante seguro para um celíaco ou intolerante à lactose dá trabalho: a pessoa lê os selos, abre a tela de detalhes, confere se há utensílios exclusivos e verifica o endereço. Quando encontra um lugar confiável, ela não quer repetir toda essa garimpagem na semana seguinte — e muitas vezes consulta a lista **já na rua**, com sinal de celular instável.

Por isso, favoritar no CeliLac precisa cumprir duas promessas de produto:

1. **Sincronização imediata entre telas**: se a pessoa tocar no coração de um cartão na **Home**, ou no coração da barra superior na **tela de detalhes**, o ícone muda na hora e a aba **Favoritos** já reflete a escolha sem precisar recarregar nada.
2. **Disponibilidade *offline* do resumo**: a aba **Favoritos** deve abrir instantaneamente e mostrar o cartão completo de cada lugar salvo (nome, categoria, bairro, distância de referência, nota, opções alimentares e logo), mesmo que o aparelho esteja sem conexão.

## 0.2 Problema 1: Por que não guardar os favoritos no `SharedPreferences`?

No Material 1, guardamos um `bool` (`onboarding_completed`). No Material 4, guardamos **um único objeto pequeno** (`DietaryProfile`) convertido em JSON. Seria tentador guardar os favoritos como uma grande string JSON no `SharedPreferences`, mas compare o que acontece à medida que a coleção cresce:

| Operação | Lista em JSON no `SharedPreferences` | Tabela `favorites` no SQLite (`sqflite`) |
|---|---|---|
| **Adicionar 1 favorito** | Lê a string inteira, decodifica todos os itens, insere 1, codifica todos de novo e regrava tudo | Executa `INSERT OR REPLACE` de **1 linha** |
| **Remover 1 favorito** | Lê tudo, filtra na memória, codifica tudo de novo e regrava tudo | Executa `DELETE FROM favorites WHERE id = ?` de **1 linha** |
| **Perguntar se o item `X` é favorito** | Precisa ter carregado e decodificado a string inteira | Pode consultar `SELECT id FROM favorites WHERE id = ? LIMIT 1` pelo índice da chave primária |
| **Ordenar do mais recente para o mais antigo** | Precisa ordenar toda a lista em código Dart | O próprio banco devolve ordenado com `ORDER BY saved_at DESC` |
| **Evoluir os campos no futuro** | Mistura versões diferentes dentro da mesma string | Tem controle nativo de versão (`version`, `onCreate`, `onUpgrade`) |

> **Regra de bolso para os seus projetos:**
> - **1 valor simples ou 1 pequeno documento de configuração** → `SharedPreferences`.
> - **Coleção de registros que cresce, é inserida/removida item a item e precisa de busca ou ordenação** → **SQLite (`sqflite`)**.

## 0.3 Problema 2: Guardar só o `id` ou guardar os dados do cartão?

Quando pensamos em favoritar, surgem duas modelagens possíveis para a tabela `favorites`:

- **Opção 1 — Guardar apenas o `id` e o `saved_at`**: a tabela teria só duas colunas (`id`, `saved_at`). Para desenhar a aba Favoritos, o app precisaria cruzar esses IDs com o repositório de estabelecimentos.
  - *Vantagem*: zero duplicação de dados.
  - *Desvantagem*: se os estabelecimentos vierem da internet (como faremos na etapa de nuvem) e o usuário abrir a aba Favoritos no metrô sem sinal, o app só terá uma lista de IDs (`'1'`, `'3'`) e **não conseguirá desenhar os cartões**!
- **Opção 2 — Guardar um instantâneo (*snapshot*) dos dados do cartão**: a tabela guarda as colunas necessárias para desenhar o `EstablishmentCard` (`id`, `name`, `category`, `neighborhood`, `distance_in_km`, `rating`, `dietary_options`, `logo_source`, `saved_at`).
  - *Vantagem*: a aba Favoritos abre **instantaneamente e 100% *offline***, e ainda exercitamos no SQLite todos os tipos de colunas (`TEXT`, `REAL`, `INTEGER`, `NULL`).
  - *Desvantagem*: se a nota do restaurante mudar no servidor, o cartão salvo localmente só terá a nota atualizada quando for sincronizado ou salvo de novo.

No CeliLac, adotamos a **Opção 2**: ela resolve o uso real em trânsito (ver seus lugares seguros sem internet) e ensina na prática como modelar uma tabela completa no SQLite.

## 0.4 Problema 3: Dois estados globais e o nascimento do `provider`

No Material 4, criamos o `ProfileScope` (um `InheritedNotifier<ProfileController>`) e transformamos o `CeliLacApp` em um `StatefulWidget` para criar o `ProfileController` no `initState` e descartá-lo no `dispose`.

Agora temos **dois** controladores globais: `ProfileController` e `FavoritesController`. Se continuássemos fazendo tudo à mão:

1. Teríamos de criar mais uma classe `FavoritesScope extends InheritedNotifier<FavoritesController>` quase idêntica ao `ProfileScope`.
2. O `CeliLacApp` teria de declarar dois campos `late final`, inicializar os dois no `initState`, descartar os dois no `dispose` e aninhar um escopo dentro do outro (`ProfileScope(child: FavoritesScope(child: MaterialApp(...)))`).

Em um aplicativo com 5 ou 6 estados compartilhados, essa pirâmide manual fica repetitiva e sujeita a esquecimentos de `dispose()`. É exatamente esse problema que o pacote **`provider`** resolve:

- **`ChangeNotifierProvider<T>`** cria o controlador sob demanda, expõe na árvore via `InheritedWidget` e **chama `dispose()` sozinho** quando sai da árvore — permitindo que o `CeliLacApp` volte a ser um simples `StatelessWidget`!
- **`MultiProvider`** recebe uma lista plana de *providers* (`providers: [...]`), eliminando a pirâmide de indentação.
- **`context.watch<T>()`** substitui `MeuEscopo.of(context)` (lê e **assina** reconstruções).
- **`context.read<T>()`** substitui `MeuEscopo.read(context)` (lê **sem assinar** reconstruções, ideal para cliques de botão e `initState`).

## 0.5 Mapa dos arquivos desta etapa

Seguindo a organização **por funcionalidade (*feature-first*)** e em **três camadas (`domain`, `data`, `presentation`)**:

```text
lib/
├── app/
│   ├── celilac_app.dart                              ← ATUALIZADO (MultiProvider + StatelessWidget)
│   └── shell/
│       └── app_shell.dart                            ← ATUALIZADO (aba Favoritos ligada à FavoritesPage)
└── features/
    ├── startup/
    │   └── presentation/
    │       └── splash_page.dart                      ← ATUALIZADO (carrega perfil e favoritos em paralelo)
    ├── establishments/
    │   └── presentation/
    │       ├── establishment_hero_tag.dart           ← ATUALIZADO (parâmetro origin para evitar colisão de Hero)
    │       ├── pages/
    │       │   └── establishment_details_page.dart   ← ATUALIZADO (botão de favoritar na AppBar)
    │       └── widgets/
    │           ├── favorite_button.dart              ← NOVO (botão de coração acessível e reutilizável)
    │           └── establishment_card.dart           ← ATUALIZADO (botão de favoritar e heroOrigin)
    ├── home/
    │   └── presentation/
    │       └── pages/
    │           └── home_page.dart                    ← ATUALIZADO (usa provider e permite favoritar no cartão)
    ├── profile/
    │   └── presentation/
    │       ├── profile_scope.dart                    ← REMOVIDO (substituído pelo pacote provider)
    │       └── pages/
    │           ├── profile_page.dart                 ← ATUALIZADO (context.watch<ProfileController>())
    │           └── profile_form_page.dart            ← ATUALIZADO (context.read<ProfileController>())
    └── favorites/                                    ← NOVA FEATURE
        ├── domain/
        │   └── repositories/
        │       └── favorites_repository.dart         ← NOVO (contrato da persistência de favoritos)
        ├── data/
        │   ├── favorite_establishment_row.dart       ← NOVO (conversão Establishment ↔ linha SQLite)
        │   └── sqlite_favorites_repository.dart      ← NOVO (banco SQLite, CREATE TABLE e migração v1→v2)
        └── presentation/
            ├── favorites_controller.dart             ← NOVO (ChangeNotifier com lista + Set O(1))
            └── pages/
                └── favorites_page.dart               ← NOVO (aba Favoritos: vazio, lista e selo do perfil)
```

---

# Parte 1: Preparando o terreno — dependências e tags de `Hero`

## 1.1 Instalando `provider`, `sqflite`, `path` e `sqflite_common_ffi`

No terminal, na raiz do projeto, execute:

```bash
flutter pub add provider sqflite path dev:sqflite_common_ffi
```

Entenda o papel de cada pacote no `pubspec.yaml`:

| Pacote | Onde entra | Para que serve |
|---|---|---|
| **`provider`** | `dependencies` | Entrega objetos `ChangeNotifier` na árvore de widgets (`ChangeNotifierProvider`, `MultiProvider`, `context.watch`, `context.read`) e gerencia seu ciclo de vida (`dispose`). |
| **`sqflite`** | `dependencies` | Plugin que acessa o motor nativo do **SQLite** no Android e no iOS. |
| **`path`** | `dependencies` | Junta caminhos de diretórios e nomes de arquivos (`join(dir, 'celilac_favorites.db')`) respeitando o separador de cada sistema operacional (`/` ou `\`). |
| **`sqflite_common_ffi`** | `dev_dependencies` | Permite rodar o SQLite diretamente na máquina de desenvolvimento (macOS, Linux ou Windows) durante o `flutter test`, **sem precisar de emulador ou celular plugado**. |

> **Por que `sqflite_common_ffi` fica em `dev_dependencies`?** Porque no celular o Android e o iOS já trazem o SQLite instalado de fábrica. Só precisamos da biblioteca FFI (*Foreign Function Interface*) quando rodamos os testes automatizados no computador. Colocá-la em `dev_dependencies` mantém o aplicativo final menor.

## 1.2 Evitando colisão de `Hero` entre abas do `IndexedStack`

Lembre-se de dois fatos que já construímos nos materiais anteriores:

1. No Material 2, o `AppShell` colocou as quatro abas dentro de um **`IndexedStack`**. Isso significa que a `HomePage` (aba 0) e a `FavoritesPage` (aba 2) **existem ao mesmo tempo na árvore de widgets**, mesmo quando apenas uma está visível.
2. No Material 3, cada `EstablishmentCard` envolveu a logo do estabelecimento em um widget **`Hero`** com a tag `'establishment-icon-${establishment.id}'`.

O que aconteceria se o usuário salvasse o **Café Aconchego** (`id: '1'`) nos favoritos?

- O cartão do Café Aconchego na **`HomePage`** teria um `Hero(tag: 'establishment-icon-1')`.
- Ao mesmo tempo, o cartão do Café Aconchego na **`FavoritesPage`** também teria um `Hero(tag: 'establishment-icon-1')`.
- Como o `IndexedStack` mantém as duas subárvores vivas na mesma tela (`AppShell`), ao navegar para o detalhe o Flutter lançaria a exceção clássica:
  > *"There are multiple heroes that share the same tag within a subtree."*

A solução é simples e elegante: incluir na tag **a origem do voo** (`origin: 'home'` ou `origin: 'favorites'`), e informar à `EstablishmentDetailsPage` de qual aba ela foi aberta!

Atualize `lib/features/establishments/presentation/establishment_hero_tag.dart`:

```dart
/// Garante que o cartão de origem e a tela de detalhes usem a mesma tag no
/// [Hero], sem duplicar a string e sem colidir entre abas do [IndexedStack].
String establishmentHeroTag(
  String establishmentId, {
  String origin = 'home',
}) => '$origin-establishment-icon-$establishmentId';
```

### Conceitos

- **Parâmetro nomeado opcional com valor padrão (`{String origin = 'home'}`).** Quem não passar `origin` continua recebendo `'home-establishment-icon-1'`. Quem estiver na aba Favoritos passa `origin: 'favorites'` e recebe `'favorites-establishment-icon-1'`.
- **Simetria origem ↔ destino.** Para o voo do `Hero` acontecer quando o usuário toca em um cartão na aba Favoritos, tanto o `EstablishmentCard` da aba Favoritos quanto a `EstablishmentDetailsPage` aberta por ele recebem `heroOrigin: 'favorites'`.

---

# Parte 2: O domínio dos favoritos (`domain`)

## 2.1 Precisamos de uma nova entidade ou reutilizamos `Establishment`?

Um favorito no CeliLac não é um tipo diferente de lugar: **é um `Establishment`** que o usuário escolheu guardar. Criar uma classe `FavoriteEstablishment` com exatamente os mesmos campos de `Establishment` só nos obrigaria a converter um no outro para conseguir usar o `EstablishmentCard`, o `EstablishmentDetailsPage` e a função `meetsProfile(establishment, profile)`.

E a data em que o lugar foi salvo (`saved_at`)? Ela serve para **ordenar a lista** do mais recente para o mais antigo no banco de dados. Quem cuida dessa ordenação é o repositório ao executar a consulta (`ORDER BY saved_at DESC`), devolvendo a `List<Establishment>` já na ordem certa!

## 2.2 O contrato `FavoritesRepository`

Crie `lib/features/favorites/domain/repositories/favorites_repository.dart`:

```dart
import '../../../establishments/domain/entities/establishment.dart';

abstract interface class FavoritesRepository {
  Future<List<Establishment>> loadAll();

  Future<bool> isFavorite(String establishmentId);

  Future<void> add(Establishment establishment, {DateTime? savedAt});

  Future<void> remove(String establishmentId);
}
```

### Conceitos

- **A interface não fala de SQLite.** Repare que o contrato não importa `sqflite` nem menciona tabelas ou SQL. Para a camada de apresentação (`FavoritesController`), tanto faz se os favoritos estão em um banco SQLite no aparelho (`SqliteFavoritesRepository`), em uma lista na memória durante os testes (`MemoryFavoritesRepository`) ou, no futuro, em uma tabela do Supabase na nuvem.
- **`{DateTime? savedAt}` opcional em `add`.** Em uso normal, ninguém precisa passar a data: o repositório usa `DateTime.now()` automaticamente. Mas deixar `savedAt` como parâmetro opcional permite que os **testes automatizados** salvem dois estabelecimentos com horários exatos e determinísticos (por exemplo, `10:00` e `11:00`) sem precisar usar `Future.delayed`!

---

# Parte 3: Persistência relacional com SQLite (`data`)

## 3.1 Os tipos de armazenamento do SQLite

Ao contrário do Dart, que tem dezenas de tipos específicos (`String`, `int`, `double`, `bool`, `DateTime`, `Set<T>`, `enum`), o **SQLite** trabalha com apenas **cinco classes de armazenamento**:

| Tipo no SQLite | O que guarda | Como mapeamos tipos do Dart |
|---|---|---|
| **`NULL`** | ausência de valor | `null` (por exemplo, `String? logoSource` quando não há logo) |
| **`INTEGER`** | número inteiro (até 64 bits) | `int`, `bool` (`0` ou `1`) e **`DateTime`** (`millisecondsSinceEpoch`) |
| **`REAL`** | número de ponto flutuante (64 bits) | `double` (`distanceInKm`, `rating`) |
| **`TEXT`** | texto em UTF-8 | `String`, **`enum`** (`.name`) e **`Set<Enum>`** (nomes separados por vírgula: `'glutenFree,lactoseFree'`) |
| **`BLOB`** | sequência bruta de bytes | arquivos binários (raramente usado; para imagens, guardamos o caminho em `TEXT`) |

> **Por que guardar `DateTime` como `INTEGER` (`millisecondsSinceEpoch`)?**
> O SQLite não tem um tipo `DATETIME` dedicado: datas podem ser salvas como texto ISO-8601 (`'2026-11-04T14:30:00.000Z'`) ou como número inteiro de milissegundos desde 01/01/1970 (`INTEGER`). Como usamos `saved_at` exclusivamente para **ordenar do mais recente para o mais antigo** (`ORDER BY saved_at DESC`), comparar números inteiros de 64 bits é mais rápido e compacto do que comparar textos caractere por caractere.

## 3.2 Conversão entre `Establishment` e linha da tabela (`Map<String, Object?>`)

No pacote `sqflite`, cada linha da tabela vai e volta como um **`Map<String, Object?>`**, em que as chaves são os nomes das colunas (por convenção do SQL, em `snake_case`) e os valores são tipos primitivos aceitos pelo SQLite.

Assim como fizemos com `dietary_profile_json.dart` no Material 4, separamos a tradução em um arquivo próprio na camada `data`, mantendo a entidade `Establishment` pura no `domain`.

Crie `lib/features/favorites/data/favorite_establishment_row.dart`:

```dart
import '../../establishments/domain/entities/dietary_option.dart';
import '../../establishments/domain/entities/establishment.dart';
import '../../establishments/domain/entities/establishment_category.dart';

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

Establishment establishmentFromRow(Map<String, Object?> row) {
  final categoryName = row['category'] as String?;
  final category = EstablishmentCategory.values
      .where((item) => item.name == categoryName)
      .firstOrNull ??
      EstablishmentCategory.values.first;

  final rawOptions = (row['dietary_options'] as String?) ?? '';
  final optionNames = rawOptions
      .split(',')
      .where((name) => name.isNotEmpty)
      .toSet();
  final dietaryOptions = DietaryOption.values
      .where((option) => optionNames.contains(option.name))
      .toSet();

  return Establishment(
    id: row['id']! as String,
    name: row['name']! as String,
    category: category,
    neighborhood: row['neighborhood']! as String,
    distanceInKm: (row['distance_in_km']! as num).toDouble(),
    rating: (row['rating']! as num).toDouble(),
    dietaryOptions: dietaryOptions,
    logoSource: row['logo_source'] as String?,
  );
}
```

### Conceitos

- **Por que `(row['rating']! as num).toDouble()` em vez de `as double`?** Mesmo quando a coluna é declarada como `REAL`, se um valor redondo como `5` for inserido, algumas plataformas ou consultas podem devolvê-lo como `int` (`5`) em vez de `double` (`5.0`). Em Dart, ambos herdam de `num`: fazer o *cast* para `num` e chamar `.toDouble()` evita um erro em tempo de execução (`type 'int' is not a subtype of type 'double'`).
- **Tolerância a mudanças nos `enum`s.** Se uma versão futura do app renomear uma opção alimentar ou categoria, usar `.where(...).firstOrNull` e filtrar apenas os nomes conhecidos impede que um registro antigo salvo no banco do usuário quebre a abertura do app.
- **`..sort()` antes do `join(',')`.** Como um `Set` não tem ordem obrigatória, ordenar os nomes antes de juntar garante que `{glutenFree, lactoseFree}` sempre gere exatamente `'glutenFree,lactoseFree'`, facilitando comparações nos testes.

## 3.3 O repositório SQLite e a evolução de esquema (`onCreate` e `onUpgrade`)

Imagine o ciclo de vida real de um aplicativo publicado na loja:

1. **Na versão 1 do banco**, criamos a tabela `favorites` com `id`, `name`, `category`, `neighborhood`, `distance_in_km`, `rating`, `dietary_options` e `saved_at`. Milhares de usuários instalam o app e salvam seus restaurantes favoritos.
2. **Na versão 2 do banco**, os cartões passam a exibir o logotipo do estabelecimento (`logo_source`).

Se você simplesmente alterar o comando `CREATE TABLE` no código e não aumentar a versão do banco, **o SQLite não roda o `onCreate` de novo para quem já tinha o app instalado**! Quando o app tentar gravar a coluna `logo_source`, o SQLite dará erro: *"table favorites has no column named logo_source"*.

E se você apagar a tabela (`DROP TABLE favorites`) e criá-la de novo? Funciona tecnicamente, mas **apaga todos os favoritos que o usuário salvou**!

A solução profissional no SQLite combina três peças no `openDatabase`:

| Parâmetro | Quando roda | O que deve fazer |
|---|---|---|
| **`version: 2`** | Sempre que o banco é aberto | Informa ao SQLite em qual versão o esquema do app está hoje. |
| **`onCreate(db, version)`** | Só quando o arquivo `.db` **ainda não existe** (usuário novo) | Cria a tabela já no formato mais recente (`version 2`, com `logo_source`). |
| **`onUpgrade(db, oldVersion, newVersion)`** | Quando o arquivo `.db` já existia no aparelho com uma versão menor (`oldVersion < newVersion`) | Executa os comandos incrementais (`ALTER TABLE ... ADD COLUMN ...`) que transformam a versão antiga na nova **preservando as linhas existentes**! |

Crie `lib/features/favorites/data/sqlite_favorites_repository.dart`:

```dart
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../establishments/domain/entities/establishment.dart';
import '../domain/repositories/favorites_repository.dart';
import 'favorite_establishment_row.dart';

typedef DatabaseOpener = Future<Database> Function();

class SqliteFavoritesRepository implements FavoritesRepository {
  SqliteFavoritesRepository({DatabaseOpener? openDatabase})
    : _openDatabase = openDatabase ?? _openDefaultDatabase;

  static const String tableName = 'favorites';
  static const int schemaVersion = 2;

  final DatabaseOpener _openDatabase;
  Future<Database>? _database;

  Future<Database> get _db => _database ??= _openDatabase();

  static Future<Database> _openDefaultDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'celilac_favorites.db');

    return openDatabase(
      path,
      version: schemaVersion,
      onCreate: createSchema,
      onUpgrade: upgradeSchema,
    );
  }

  /// Cria a tabela já na versão atual para instalações novas.
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

  /// Atualiza instalações existentes sem apagar os favoritos já salvos.
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

  @override
  Future<List<Establishment>> loadAll() async {
    final db = await _db;
    final rows = await db.query(tableName, orderBy: 'saved_at DESC');
    return rows.map(establishmentFromRow).toList();
  }

  @override
  Future<bool> isFavorite(String establishmentId) async {
    final db = await _db;
    final rows = await db.query(
      tableName,
      columns: const ['id'],
      where: 'id = ?',
      whereArgs: [establishmentId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

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
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [establishmentId],
    );
  }
}
```

### Conceitos fundamentais deste arquivo

1. **`Future<Database> get _db => _database ??= _openDatabase();` (abertura preguiçosa e única).**
   Abrir o banco no disco tem custo. O operador `??=` abre o banco na primeira chamada e guarda o mesmo `Future<Database>` para todas as chamadas seguintes. Se duas chamadas acontecerem quase ao mesmo tempo, ambas aguardam o **mesmo** `Future`, sem abrir duas conexões concorrentes.
2. **Injeção de `DatabaseOpener` para testes.**
   No celular, `_openDefaultDatabase` descobre a pasta de bancos do sistema (`getDatabasesPath()`) e abre o arquivo `celilac_favorites.db`. Nos testes automatizados no computador (Parte 8), passamos um `openDatabase` que abre um banco **em memória** via `sqflite_common_ffi`. E como `createSchema` e `upgradeSchema` são métodos `static`, os testes exercitam **exatamente o mesmo SQL** usado em produção!
3. **`ConflictAlgorithm.replace` no `insert`.**
   Como `id` é `PRIMARY KEY`, tentar inserir um `id` que já existe lançaria erro de chave duplicada. Com `ConflictAlgorithm.replace`, o SQLite executa um `INSERT OR REPLACE`: se o estabelecimento já estava salvo, ele atualiza os dados do cartão e o `saved_at` sem duplicar a linha.
4. **Segurança: nunca concatene valores no `where`!**
   Compare estas duas linhas:
   ```dart
   // ERRADO e perigoso (vulnerável a SQL Injection e quebra com aspas no texto):
   await db.delete(tableName, where: "id = '$establishmentId'");

   // CERTO: marcador '?' em where + valor separado em whereArgs:
   await db.delete(tableName, where: 'id = ?', whereArgs: [establishmentId]);
   ```
   Quando você usa `?` e `whereArgs`, o SQLite compila o comando SQL primeiro e passa o valor **como dado puro**, nunca como parte do comando. Mesmo que um texto contenha aspas (`'`) ou pontos e vírgulas (`;`), ele jamais será interpretado como instrução SQL.
5. **Por que `if (oldVersion < 2)` em vez de `switch (oldVersion)` no `onUpgrade`?**
   Imagine que no futuro exista a versão 3 (`if (oldVersion < 3) { ... }`). Se um usuário estava na versão 1 e atualiza direto para a versão 3, ter blocos `if (oldVersion < 2)` seguidos de `if (oldVersion < 3)` faz o banco aplicar **todas as migrações intermediárias em sequência** (`1 → 2 → 3`)!

---

# Parte 4: Estado compartilhado com `FavoritesController` e `provider`

## 4.1 Lista ordenada + Conjunto (`Set`) para consulta instantânea `O(1)`

Na interface do CeliLac, fazemos duas perguntas diferentes ao controlador de favoritos:

1. **Na aba Favoritos (`FavoritesPage`)**: *"Quais são todos os estabelecimentos salvos, do mais recente para o mais antigo?"* → precisa de uma **`List<Establishment>`** (que preserva a ordem).
2. **Em cada cartão da Home e na tela de detalhes**: *"O estabelecimento de `id` `'1'` está nos favoritos?"* → chama `isFavorite(id)` **para cada cartão visível** a cada `build`!

Se `isFavorite(id)` percorresse uma `List<Establishment>` com `.any((e) => e.id == id)`, para cada cartão ele faria uma busca linear (`O(n)`). Mantendo internamente um **`Set<String> _favoriteIds`** sincronizado com a lista, a pergunta `_favoriteIds.contains(id)` é respondida instantaneamente em tempo constante (**`O(1)`**), não importa quantos lugares estejam salvos.

Crie `lib/features/favorites/presentation/favorites_controller.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../../establishments/domain/entities/establishment.dart';
import '../domain/repositories/favorites_repository.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController(this._repository);

  final FavoritesRepository _repository;

  List<Establishment> _favorites = const [];
  Set<String> _favoriteIds = const {};
  bool _isLoaded = false;
  Future<void>? _loading;

  List<Establishment> get favorites => _favorites;

  bool get isLoaded => _isLoaded;

  bool isFavorite(String establishmentId) =>
      _favoriteIds.contains(establishmentId);

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final loaded = await _repository.loadAll();
      _favorites = List.unmodifiable(loaded);
      _favoriteIds = {for (final item in loaded) item.id};
    } on Object catch (error) {
      debugPrint('Não foi possível carregar os favoritos: $error');
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Alterna o estado de favorito de [establishment].
  ///
  /// Devolve `true` se o lugar passou a ser favorito e `false` se foi removido.
  Future<bool> toggle(Establishment establishment) async {
    if (isFavorite(establishment.id)) {
      await _repository.remove(establishment.id);
      _favorites = List.unmodifiable(
        _favorites.where((item) => item.id != establishment.id),
      );
      _favoriteIds = {..._favoriteIds}..remove(establishment.id);
      notifyListeners();
      return false;
    }

    await _repository.add(establishment);
    _favorites = List.unmodifiable([
      establishment,
      ..._favorites.where((item) => item.id != establishment.id),
    ]);
    _favoriteIds = {..._favoriteIds, establishment.id};
    notifyListeners();
    return true;
  }
}
```

### Conceitos

- **Gravar no banco antes de atualizar a memória e chamar `notifyListeners()`.** Assim como no `ProfileController.save` do Material 4, `toggle` faz `await _repository.add(...)` (ou `remove`) **antes** de mudar `_favorites` e `_favoriteIds`. Se a gravação no SQLite falhar, a exceção sobe para a tela (que mostra um `SnackBar`), e a interface **não mente** mostrando um coração preenchido que não foi salvo.
- **`List.unmodifiable(...)`.** Quem lê `controller.favorites` recebe uma lista somente-leitura. Nenhuma tela consegue fazer `controller.favorites.clear()` por engano sem passar pelo `toggle`.
- **Novo item entra na frente (`[establishment, ..._favorites]`).** Como o banco devolve `ORDER BY saved_at DESC`, colocar o recém-adicionado no índice `0` mantém a lista em memória exatamente na mesma ordem que virá do banco na próxima abertura do app.

## 4.2 Migrando do `ProfileScope` manual para o pacote `provider`

No Material 4, escrevemos o `ProfileScope` à mão para enxergar por dentro como o `InheritedNotifier` funciona. Veja a equivalência direta entre o que fazíamos à mão e o que o pacote `provider` faz por nós:

| O que fazíamos à mão (Material 4) | Como fica com `provider` (Material 5) |
|---|---|
| Criar a classe `ProfileScope extends InheritedNotifier<ProfileController>` | Não precisa criar classe de escopo! Usa **`ChangeNotifierProvider<ProfileController>`** |
| Transformar `CeliLacApp` em `StatefulWidget` para dar `initState` e `dispose` nos controladores | `CeliLacApp` volta a ser **`StatelessWidget`**: `ChangeNotifierProvider(create: ...)` cria e chama `dispose()` sozinho |
| Aninhar escopos (`ProfileScope(child: FavoritesScope(...))`) | Lista plana com **`MultiProvider(providers: [...])`** |
| `ProfileScope.of(context)` (lê e reconstrói quando muda) | **`context.watch<ProfileController>()`** |
| `ProfileScope.read(context)` (lê sem reconstruir) | **`context.read<ProfileController>()`** |

Remova o arquivo antigo `lib/features/profile/presentation/profile_scope.dart` e atualize `lib/app/celilac_app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../features/favorites/data/sqlite_favorites_repository.dart';
import '../features/favorites/domain/repositories/favorites_repository.dart';
import '../features/favorites/presentation/favorites_controller.dart';
import '../features/profile/data/local_profile_repository.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/profile/presentation/profile_controller.dart';
import '../features/startup/presentation/splash_page.dart';
import 'theme/app_theme.dart';

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
    // Acima do MaterialApp: as rotas empilhadas também enxergam os
    // controladores, e o ChangeNotifierProvider cuida de criar e descartar.
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
        title: 'CeliLac',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const SplashPage(),
      ),
    );
  }
}
```

### Quando usar `context.watch<T>()` vs `context.read<T>()`?

Essa é a regra mais importante ao trabalhar com `provider`:

| Método | Onde usar | O que faz |
|---|---|---|
| **`context.watch<T>()`** | **Apenas dentro do método `build`** | Devolve o controlador e **inscreve o widget**: sempre que o controlador chamar `notifyListeners()`, aquele `build` roda de novo. |
| **`context.read<T>()`** | **Fora do `build`**: em `onPressed`, `onTap`, `_save()`, `initState()` | Devolve o controlador **sem inscrever o widget**. Se você tentar chamar `watch` dentro de um `onPressed`, o próprio `provider` lançará um erro em modo debug avisando que um clique de botão não pode assinar reconstruções! |

## 4.3 Carregando perfil e favoritos em paralelo na `SplashPage`

Em `lib/features/startup/presentation/splash_page.dart`, troque a importação de `profile_scope.dart` por `package:provider/provider.dart`, `profile_controller.dart` e `favorites_controller.dart`, e atualize o método `_initialize()`:

```dart
  Future<void> _initialize() async {
    // Começam já, em paralelo com as animações: a Splash não fica mais longa.
    final profileLoad = context.read<ProfileController>().load();
    final favoritesLoad = context.read<FavoritesController>().load();

    await _introController.forward();
    if (!mounted) {
      return;
    }

    await _progressController.forward();
    if (!mounted) {
      return;
    }

    final (completed, _, _) = await (
      OnboardingStorage().isCompleted(),
      profileLoad,
      favoritesLoad,
    ).wait;
    if (!mounted) {
      return;
    }

    _goTo(completed ? const AppShell() : const OnboardingPage());
  }
```

Repare na beleza do *record* `(OnboardingStorage().isCompleted(), profileLoad, favoritesLoad).wait`: as três leituras de disco (preferência do onboarding, JSON do perfil e banco SQLite de favoritos) acontecem **ao mesmo tempo** enquanto a animação da Splash roda! Quando o `AppShell` abre, tanto o perfil quanto os favoritos já estão prontos na memória.

## 4.4 Atualizando `ProfilePage` e `ProfileFormPage` para `provider`

Nos dois arquivos do perfil, a mudança é cirúrgica:

1. Em `lib/features/profile/presentation/pages/profile_page.dart`:
   - Troque `import '../profile_scope.dart';` por:
     ```dart
     import 'package:provider/provider.dart';
     import '../profile_controller.dart';
     ```
   - No `build`, troque `ProfileScope.of(context)` por `context.watch<ProfileController>()`.
2. Em `lib/features/profile/presentation/pages/profile_form_page.dart`:
   - Troque `import '../profile_scope.dart';` por:
     ```dart
     import 'package:provider/provider.dart';
     import '../profile_controller.dart';
     ```
   - Em `initState` e em `_save`, troque `ProfileScope.read(context)` por `context.read<ProfileController>()`.

---

# Parte 5: Favoritar no Cartão e na Tela de Detalhes

## 5.1 O componente `FavoriteButton`

O botão de coração aparece em três lugares diferentes do aplicativo: nos cartões da **Home**, nos cartões da aba **Favoritos** e na barra superior da **tela de detalhes**. Criar um widget próprio evita repetir ícone, cor, fundo e rótulo de acessibilidade.

Crie `lib/features/establishments/presentation/widgets/favorite_button.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.establishmentName,
    required this.isFavorite,
    required this.onPressed,
  });

  final String establishmentName;
  final bool isFavorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = isFavorite
        ? 'Remover $establishmentName dos favoritos'
        : 'Salvar $establishmentName nos favoritos';

    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      color: AppColors.navy,
      style: IconButton.styleFrom(
        backgroundColor: isFavorite
            ? AppColors.gold.withValues(alpha: 0.22)
            : null,
      ),
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
    );
  }
}
```

### Conceitos

- **Três sinais visuais e semânticos (não depender só da cor).** Quando um lugar está salvo (`isFavorite: true`), mudam ao mesmo tempo:
  1. a **forma** do ícone (`Icons.favorite` cheio em vez de `Icons.favorite_border` vazado);
  2. o **fundo circular suave** (`AppColors.gold.withValues(alpha: 0.22)`), mantendo o ícone em `AppColors.navy` para garantir alto contraste;
  3. o **rótulo de acessibilidade (`tooltip`)**, que passa de *"Salvar Café Aconchego nos favoritos"* para *"Remover Café Aconchego dos favoritos"*.
- **Por que incluir o nome do estabelecimento no `tooltip`?** Na `HomePage` ou na `FavoritesPage`, existem vários botões de coração na mesma tela. Se todos dissessem apenas *"Favoritar"*, uma pessoa que navega por comando de voz ou leitor de tela ouviria quatro botões idênticos sem saber a qual restaurante cada um pertence — e nos testes automatizados podemos clicar exatamente em `find.byTooltip('Salvar Café Aconchego nos favoritos')`!

## 5.2 Evoluindo o `EstablishmentCard`: duas ações no mesmo cartão

Até o Material 4, o `EstablishmentCard` tinha **uma única ação de toque**: tocar em qualquer lugar do cartão abria a tela de detalhes, e por isso envolvíamos o cartão inteiro em um `MergeSemantics`.

Agora o cartão passa a ter **duas ações de toque independentes**:

```text
┌──────────────────────────────────────────┐
│ ┌────┐  Café Aconchego          ★ 4,8    │ ← tocar no cartão abre o detalhe
│ │    │  Café · Centro · 350 m    (♡)     │ ← tocar no coração salva/remove
│ └────┘  [✓ Sem glúten] [✓ Sem lactose]   │
│                   [👤 Atende ao perfil]  │
└──────────────────────────────────────────┘
```

### A armadilha do `MergeSemantics` com dois botões

O que acontece se mantivermos o `MergeSemantics` por fora do `Card` quando adicionamos um `IconButton` (`FavoriteButton`) lá dentro?

O `MergeSemantics` **funde todos os nós semânticos da subárvore em um único nó**, inclusive botões filhos! Com isso:

- O leitor de tela deixa de enxergar o `FavoriteButton` como um botão separado e passa a ler tudo grudado em um único item.
- Um usuário de *TalkBack* ou *VoiceOver* fica **impedido de favoritar pelo cartão**, porque o toque duplo no item fundido aciona apenas o `onTap` do `InkWell` externo.

Quando retiramos o `MergeSemantics` externo, o próprio `InkWell` do Flutter já agrupa automaticamente os textos que não têm ação própria (nome, bairro, distância, selos, nota e selo de perfil) no nó de toque do cartão, enquanto o `FavoriteButton` (que é um `IconButton` com `tooltip` e `onPressed` próprios) permanece como um **segundo nó semântico independente de `48×48 dp`**!

### Por que empilhar o coração abaixo da nota (e não ao lado)?

Em uma tela estreita (`320 px`) com fonte ampliada a `200%`, a nota `★ 4,8` já ocupa cerca de `62 px` de largura. Se colocássemos o botão de `48 px` **ao lado** da nota na mesma `Row`, sobraria pouco espaço horizontal para o nome e os selos alimentares. Empilhando o `FavoriteButton` **abaixo** da nota em uma `Column` alinhada à direita (`CrossAxisAlignment.end`), não consumimos **nenhum pixel extra de largura**!

Atualize `lib/features/establishments/presentation/widgets/establishment_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../app/common/formatters.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/establishment.dart';
import '../establishment_hero_tag.dart';
import 'dietary_badge.dart';
import 'establishment_logo.dart';
import 'favorite_button.dart';

class EstablishmentCard extends StatelessWidget {
  const EstablishmentCard({
    super.key,
    required this.establishment,
    required this.onTap,
    this.matchesProfile = false,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.heroOrigin = 'home',
  });

  final Establishment establishment;
  final VoidCallback onTap;

  /// Quem decide é a tela que usa o cartão: estabelecimentos não conhecem
  /// o perfil.
  final bool matchesProfile;

  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final String heroOrigin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final details = [
      establishment.category.label,
      establishment.neighborhood,
      formatDistance(establishment.distanceInKm),
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: establishmentHeroTag(
                      establishment.id,
                      origin: heroOrigin,
                    ),
                    child: EstablishmentLogo(establishment: establishment),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          establishment.name,
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          details,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.navy.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final option in establishment.dietaryOptions)
                              DietaryBadge(option: option),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: AppColors.gold,
                            semanticLabel: 'Nota',
                          ),
                          const SizedBox(width: 2),
                          Text(
                            formatDecimal(establishment.rating),
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.navy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (onFavoriteToggle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        FavoriteButton(
                          establishmentName: establishment.name,
                          isFavorite: isFavorite,
                          onPressed: onFavoriteToggle!,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              // Abaixo da linha toda, à direita: alinhado com a nota.
              if (matchesProfile) ...[
                const SizedBox(height: AppSpacing.sm),
                const _ProfileMatchBadge(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMatchBadge extends StatelessWidget {
  const _ProfileMatchBadge();

  @override
  Widget build(BuildContext context) {
    // Navy cheio, diferente dos selos dourados: é sobre a pessoa, não
    // sobre o lugar. Ícone e texto, para não depender só da cor.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_pin_outlined, size: 14, color: Colors.white),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'Atende ao seu perfil',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
```

> **Repare na direção das dependências:** `EstablishmentCard` continua em `features/establishments/` e **não importa** nem `profile/` nem `favorites/`. Ele apenas recebe `matchesProfile: bool`, `isFavorite: bool` e `onFavoriteToggle: VoidCallback?`. Isso mantém o cartão puro, fácil de testar e reutilizável em qualquer tela.

## 5.3 Favoritar na `EstablishmentDetailsPage`

Na tela de detalhes (`lib/features/establishments/presentation/pages/establishment_details_page.dart`), adicionamos:

1. O parâmetro opcional `this.heroOrigin = 'home'` no construtor de `EstablishmentDetailsPage`, repassado para `establishmentHeroTag(widget.establishment.id, origin: widget.heroOrigin)`.
2. O método `_toggleFavorite()` em `_EstablishmentDetailsPageState`, que usa `context.read<FavoritesController>().toggle(widget.establishment)` e exibe um `SnackBar` se o banco falhar.
3. No `build`, `final isFavorite = context.watch<FavoritesController>().isFavorite(widget.establishment.id);` e o `FavoriteButton` nos `actions` da `AppBar`, ao lado da logo animada pelo `Hero`:

```dart
    return Scaffold(
      appBar: AppBar(
        actions: [
          FavoriteButton(
            establishmentName: widget.establishment.name,
            isFavorite: isFavorite,
            onPressed: _toggleFavorite,
          ),
          const SizedBox(width: AppSpacing.xs),
          Padding(
            padding: EdgeInsets.only(right: horizontalPadding),
            child: Hero(
              tag: establishmentHeroTag(
                widget.establishment.id,
                origin: widget.heroOrigin,
              ),
              child: EstablishmentLogo(
                establishment: widget.establishment,
                size: 40,
              ),
            ),
          ),
        ],
      ),
      // ...
```

## 5.4 Conectando os cartões da `HomePage` ao `FavoritesController`

Em `lib/features/home/presentation/pages/home_page.dart`:

1. Substitua `import '../../../profile/presentation/profile_scope.dart';` por:
   ```dart
   import 'package:provider/provider.dart';
   import '../../../favorites/presentation/favorites_controller.dart';
   import '../../../profile/presentation/profile_controller.dart';
   ```
2. Adicione o método `_toggleFavorite(Establishment establishment)` em `_HomePageState`:
   ```dart
   Future<void> _toggleFavorite(Establishment establishment) async {
     try {
       await context.read<FavoritesController>().toggle(establishment);
     } on Object {
       if (!mounted) return;
       ScaffoldMessenger.of(context)
         ..hideCurrentSnackBar()
         ..showSnackBar(
           const SnackBar(
             content: Text('Não foi possível atualizar os favoritos.'),
           ),
         );
     }
   }
   ```
3. No `build`, observe tanto o perfil quanto os favoritos com `context.watch`:
   ```dart
   final profile = context.watch<ProfileController>().profile;
   final favorites = context.watch<FavoritesController>();
   ```
4. Passe `favorites` para `_buildNearby(profile, favorites)` e, dentro do `SliverList.separated`, entregue `isFavorite` e `onFavoriteToggle` ao `EstablishmentCard`:
   ```dart
   return EstablishmentCard(
     establishment: establishment,
     matchesProfile: meetsProfile(establishment, profile),
     isFavorite: favorites.isFavorite(establishment.id),
     onFavoriteToggle: () => _toggleFavorite(establishment),
     onTap: () => _openDetails(establishment),
   );
   ```

Veja o que ganhamos sem escrever nenhuma linha de sincronização manual: se o usuário abrir a `EstablishmentDetailsPage`, tocar no coração lá dentro e voltar para a `HomePage`, o cartão da `HomePage` **já estará com o coração preenchido**, porque ambas as telas observam o mesmo `FavoritesController` via `context.watch<FavoritesController>()`!

---

# Parte 6: A Aba Favoritos (`FavoritesPage` e `AppShell`)

## 6.1 Construindo a `FavoritesPage`

A aba Favoritos tem três estados possíveis:

1. **Carregando (`!favoritesController.isLoaded`)** — exibe um `CircularProgressIndicator` centralizado se o banco ainda estiver abrindo.
2. **Vazia (`favorites.isEmpty`)** — usa o mesmo componente `StatusMessage` das outras telas, explicando como salvar um lugar (*"Toque no coração em um lugar para encontrá-lo rápido aqui."*) e oferecendo um botão **"Ver estabelecimentos"** que leva o usuário de volta à aba **Início**.
3. **Com itens (`favorites.isNotEmpty`)** — mostra a contagem no topo (*"1 lugar salvo"* ou *"2 lugares salvos"*) seguida da lista de `EstablishmentCard`s, cruzando cada favorito com o `ProfileController` para exibir o selo **"Atende ao seu perfil"** e passando `heroOrigin: 'favorites'` tanto para o cartão quanto para a `EstablishmentDetailsPage`.

Crie `lib/features/favorites/presentation/pages/favorites_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/common/widgets/status_message.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_layout.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../establishments/data/fake_establishment_repository.dart';
import '../../../establishments/domain/entities/establishment.dart';
import '../../../establishments/domain/repositories/establishment_repository.dart';
import '../../../establishments/presentation/pages/establishment_details_page.dart';
import '../../../establishments/presentation/widgets/establishment_card.dart';
import '../../../profile/domain/profile_match.dart';
import '../../../profile/presentation/profile_controller.dart';
import '../favorites_controller.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({
    super.key,
    this.repository = const FakeEstablishmentRepository(),
    this.onExploreTap,
  });

  final EstablishmentRepository repository;
  final VoidCallback? onExploreTap;

  void _openDetails(BuildContext context, Establishment establishment) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EstablishmentDetailsPage(
          establishment: establishment,
          repository: repository,
          heroOrigin: 'favorites',
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    Establishment establishment,
  ) async {
    try {
      await context.read<FavoritesController>().toggle(establishment);
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não foi possível atualizar os favoritos.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritesController = context.watch<FavoritesController>();
    final profile = context.watch<ProfileController>().profile;
    final favorites = favoritesController.favorites;
    final horizontalPadding = AppLayout.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: !favoritesController.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : favorites.isEmpty
          ? SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.sm,
                horizontalPadding,
                AppSpacing.xl,
              ),
              child: StatusMessage(
                icon: Icons.favorite_border,
                message:
                    'Você ainda não salvou nenhum estabelecimento. '
                    'Toque no coração em um lugar para encontrá-lo rápido aqui.',
                actionLabel: onExploreTap != null
                    ? 'Ver estabelecimentos'
                    : null,
                onAction: onExploreTap,
              ),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.sm,
                horizontalPadding,
                AppSpacing.xl,
              ),
              children: [
                Text(
                  favorites.length == 1
                      ? '1 lugar salvo'
                      : '${favorites.length} lugares salvos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < favorites.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  EstablishmentCard(
                    establishment: favorites[i],
                    matchesProfile: meetsProfile(favorites[i], profile),
                    isFavorite: true,
                    heroOrigin: 'favorites',
                    onFavoriteToggle: () =>
                        _toggleFavorite(context, favorites[i]),
                    onTap: () => _openDetails(context, favorites[i]),
                  ),
                ],
              ],
            ),
    );
  }
}
```

## 6.2 Ligando a `FavoritesPage` no `AppShell`

Em `lib/app/shell/app_shell.dart`, trocamos o `ComingSoonView(title: 'Favoritos', ...)` pela `FavoritesPage`, passando `onExploreTap: () => _onDestinationSelected(0)` para que o botão **"Ver estabelecimentos"** do estado vazio leve o usuário para a aba **Início**:

```dart
class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  late final List<Widget> _tabs = [
    const HomePage(repository: FakeEstablishmentRepository()),
    const ComingSoonView(title: 'Explorar', icon: Icons.explore_outlined),
    FavoritesPage(
      repository: const FakeEstablishmentRepository(),
      onExploreTap: () => _onDestinationSelected(0),
    ),
    const ProfilePage(),
  ];
  // ...
```

> **Por que `_tabs` mudou de `static const` para `late final`?** Porque o callback `onExploreTap: () => _onDestinationSelected(0)` referencia um método da instância `_AppShellState`. Com `late final`, a lista de abas ainda é criada **uma única vez** na vida do `_AppShellState` (preservando o estado das abas no `IndexedStack`), mas já pode chamar métodos da própria classe.

---

# Parte 7: Qualidade, Responsividade e Acessibilidade

Revisemos os cuidados de qualidade aplicados nesta etapa:

1. **Dois alvos de toque independentes no cartão (`>= 48×48 dp`).** O `IconButton` do `FavoriteButton` já garante área mínima de `48×48 dp` no Material 3, e por não estar preso dentro de um `MergeSemantics`, pode ser focado individualmente por leitores de tela.
2. **Rótulos semânticos contextualizados.** Cada botão de favoritar anuncia a ação exata e o nome do estabelecimento (*"Salvar Café Aconchego nos favoritos"* / *"Remover Café Aconchego dos favoritos"*), passando na diretriz `labeledTapTargetGuideline`.
3. **Contraste WCAG e independência de cor.** O estado favoritado combina mudança de ícone (`favorite_border` → `favorite`), fundo dourado translúcido (`alpha: 0.22`) e ícone em azul-marinho (`AppColors.navy`), garantindo contraste acima de `4.5:1`.
4. **Fonte a `200%` em tela de `320×640`.** Na `FavoritesPage`, o estado vazio fica dentro de um `SingleChildScrollView` e a lista de favoritos usa um `ListView`, impedindo qualquer *overflow* vertical ou horizontal quando o usuário dobra o tamanho da fonte do sistema.

---

# Parte 8: Testes Automatizados (incluindo SQLite em memória com `sqflite_common_ffi`)

## 8.1 Atualizando os dublês de teste (`MemoryFavoritesRepository` e `pumpWithProfile`)

Para os testes de widgets das telas (`HomePage`, `EstablishmentDetailsPage`, `FavoritesPage`, `AppShell`), não precisamos abrir o SQLite a cada teste: um repositório em memória (`MemoryFavoritesRepository`) é instantâneo e permite simular falhas com `failOnLoad` e `failOnChange`.

Crie `test/support/memory_favorites_repository.dart`:

```dart
import 'package:celilac/features/establishments/domain/entities/establishment.dart';
import 'package:celilac/features/favorites/domain/repositories/favorites_repository.dart';

class MemoryFavoritesRepository implements FavoritesRepository {
  MemoryFavoritesRepository({
    List<Establishment> stored = const [],
    this.failOnLoad = false,
    this.failOnChange = false,
  }) : _stored = List.of(stored);

  final List<Establishment> _stored;
  bool failOnLoad;
  bool failOnChange;
  int loadCalls = 0;
  int addCalls = 0;
  int removeCalls = 0;

  List<Establishment> get stored => List.unmodifiable(_stored);

  @override
  Future<List<Establishment>> loadAll() async {
    loadCalls++;
    if (failOnLoad) {
      throw Exception('falha ao ler favoritos');
    }
    return List.of(_stored);
  }

  @override
  Future<bool> isFavorite(String establishmentId) async {
    return _stored.any((item) => item.id == establishmentId);
  }

  @override
  Future<void> add(Establishment establishment, {DateTime? savedAt}) async {
    addCalls++;
    if (failOnChange) {
      throw Exception('falha ao salvar favorito');
    }
    _stored.removeWhere((item) => item.id == establishment.id);
    _stored.insert(0, establishment);
  }

  @override
  Future<void> remove(String establishmentId) async {
    removeCalls++;
    if (failOnChange) {
      throw Exception('falha ao remover favorito');
    }
    _stored.removeWhere((item) => item.id == establishmentId);
  }
}
```

E atualize `test/support/pump_app.dart` para fornecer tanto o `ProfileController` quanto o `FavoritesController` via `MultiProvider`:

```dart
  final controller = ProfileController(repository ?? MemoryProfileRepository());
  final favoritesController = FavoritesController(
    favoritesRepository ?? MemoryFavoritesRepository(),
  );
  addTearDown(controller.dispose);
  addTearDown(favoritesController.dispose);
  await (controller.load(), favoritesController.load()).wait;

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileController>.value(value: controller),
        ChangeNotifierProvider<FavoritesController>.value(
          value: favoritesController,
        ),
      ],
      child: MaterialApp(
        // ...
```

> **Por que `ChangeNotifierProvider.value` no helper de teste e `ChangeNotifierProvider(create: ...)` no `CeliLacApp`?**
> No `pumpWithProfile`, nós criamos os controladores **antes** do `pumpWidget` para poder fazer `await (controller.load(), favoritesController.load()).wait` e já registrar o `addTearDown(controller.dispose)`. Quando o objeto já existe fora da árvore, a regra do pacote `provider` é usar o construtor `.value`.

## 8.2 Testando a conversão de linhas (`favorite_establishment_row_test.dart`)

Crie `test/features/favorites/favorite_establishment_row_test.dart` para provar que `toRow` e `establishmentFromRow` preservam todos os campos, aceitam inteiros vindos de colunas `REAL` e ignoram valores desconhecidos de `enum` sem quebrar.

## 8.3 Testando o SQLite real em memória (`sqlite_favorites_repository_test.dart`)

Um erro comum em projetos acadêmicos é testar apenas o repositório falso e descobrir só no celular que o comando `CREATE TABLE` ou `ALTER TABLE` tinha um erro de sintaxe SQL!

Com `sqflite_common_ffi` e `inMemoryDatabasePath`, abrimos um **banco SQLite verdadeiro na memória RAM** durante o `flutter test`:

- Ele executa o motor C real do SQLite.
- Não cria arquivos sujos no disco do computador.
- Roda em milissegundos.
- Permite testar inclusive a **migração da versão 1 para a versão 2 (`upgradeSchema`)**!

Crie `test/features/favorites/sqlite_favorites_repository_test.dart`:

```dart
import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/establishments/domain/entities/establishment.dart';
import 'package:celilac/features/establishments/domain/entities/establishment_category.dart';
import 'package:celilac/features/favorites/data/sqlite_favorites_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _cafe = Establishment(
  id: '1',
  name: 'Café Aconchego',
  category: EstablishmentCategory.cafe,
  neighborhood: 'Centro',
  distanceInKm: 0.35,
  rating: 4.8,
  dietaryOptions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
  logoSource: 'assets/images/establishments/cafe_aconchego_logo.png',
);

const _bakery = Establishment(
  id: '2',
  name: 'Padaria Leve Grão',
  category: EstablishmentCategory.bakery,
  neighborhood: 'Jardim das Flores',
  distanceInKm: 1.2,
  rating: 4.6,
  dietaryOptions: {DietaryOption.glutenFree},
);

Future<Database> _openInMemoryDatabase() {
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: SqliteFavoritesRepository.schemaVersion,
      onCreate: SqliteFavoritesRepository.createSchema,
      onUpgrade: SqliteFavoritesRepository.upgradeSchema,
      singleInstance: false,
    ),
  );
}

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late SqliteFavoritesRepository repository;

  setUp(() async {
    db = await _openInMemoryDatabase();
    repository = SqliteFavoritesRepository(openDatabase: () async => db);
  });

  tearDown(() async {
    await db.close();
  });

  test('começa vazio', () async {
    expect(await repository.loadAll(), isEmpty);
    expect(await repository.isFavorite('1'), isFalse);
  });

  test('salva e devolve do mais recente para o mais antigo', () async {
    await repository.add(_cafe, savedAt: DateTime.utc(2026, 11, 4, 10));
    await repository.add(_bakery, savedAt: DateTime.utc(2026, 11, 4, 11));

    final all = await repository.loadAll();
    expect(all.map((e) => e.id).toList(), ['2', '1']);
    expect(await repository.isFavorite('1'), isTrue);
    expect(await repository.isFavorite('2'), isTrue);
  });

  test('salvar o mesmo id atualiza sem duplicar', () async {
    await repository.add(_cafe, savedAt: DateTime.utc(2026, 11, 4, 10));
    await repository.add(_bakery, savedAt: DateTime.utc(2026, 11, 4, 11));
    await repository.add(_cafe, savedAt: DateTime.utc(2026, 11, 4, 12));

    final all = await repository.loadAll();
    expect(all.map((e) => e.id).toList(), ['1', '2']);
  });

  test('remove apenas o estabelecimento indicado', () async {
    await repository.add(_cafe);
    await repository.add(_bakery);

    await repository.remove('1');

    final all = await repository.loadAll();
    expect(all.map((e) => e.id).toList(), ['2']);
    expect(await repository.isFavorite('1'), isFalse);
  });

  test('migra da versão 1 para a 2 preservando os dados já salvos', () async {
    final v1Db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        singleInstance: false,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE ${SqliteFavoritesRepository.tableName} (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              category TEXT NOT NULL,
              neighborhood TEXT NOT NULL,
              distance_in_km REAL NOT NULL,
              rating REAL NOT NULL,
              dietary_options TEXT NOT NULL,
              saved_at INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
    addTearDown(v1Db.close);

    await v1Db.insert(SqliteFavoritesRepository.tableName, {
      'id': '2',
      'name': 'Padaria Leve Grão',
      'category': 'bakery',
      'neighborhood': 'Jardim das Flores',
      'distance_in_km': 1.2,
      'rating': 4.6,
      'dietary_options': 'glutenFree',
      'saved_at': 1000,
    });

    await SqliteFavoritesRepository.upgradeSchema(v1Db, 1, 2);

    final migratedRepo = SqliteFavoritesRepository(
      openDatabase: () async => v1Db,
    );
    await migratedRepo.add(_cafe, savedAt: DateTime.utc(2026, 11, 4, 12));

    final all = await migratedRepo.loadAll();
    expect(all.map((e) => e.id).toList(), ['1', '2']);
    expect(all.first.logoSource, _cafe.logoSource);
    expect(all.last.logoSource, isNull);
  });
}
```

> **Detalhe importante: `singleInstance: false` no `OpenDatabaseOptions`.**
> Por padrão, o `sqflite` reaproveita a mesma instância se dois bancos forem abertos com o mesmo caminho (`inMemoryDatabasePath`). Passar `singleInstance: false` garante que cada teste — e até um segundo banco aberto dentro do mesmo teste, como o `v1Db` de migração — receba um banco em memória 100% isolado!

## 8.4 Testando o controlador e a página (`favorites_controller_test.dart` e `favorites_page_test.dart`)

Com os testes de `favorites_controller_test.dart`, `favorites_page_test.dart` e o novo teste de integração em `app_shell_test.dart` (que favorita um item na Home, troca para a aba Favoritos e abre o detalhe verificando que não há colisão de `Hero`), rode toda a suíte:

```bash
flutter analyze
flutter test
```

Todos os **122 testes** devem passar sem nenhum aviso!

---

# Parte 9: Revisão — decisões, armadilhas e alternativas de mercado

## 9.1 Resumo das decisões tomadas nesta etapa

| Problema | Como resolvemos | Alternativas e por que escolhemos esta |
|---|---|---|
| **Onde persistir a lista de favoritos?** | Banco relacional local **SQLite (`sqflite`)** | `SharedPreferences` obrigaria a regravar a lista inteira a cada toque; nuvem exige login e internet. |
| **O que salvar na tabela `favorites`?** | Instantâneo dos dados do cartão (`id`, `name`, `category`, `neighborhood`, `distance_in_km`, `rating`, `dietary_options`, `logo_source`, `saved_at`) | Salvar só o `id` impediria desenhar os cartões da aba Favoritos quando o aparelho estivesse *offline*. |
| **Como evoluir a tabela sem perder dados?** | `version: 2`, `onCreate` completo + `onUpgrade` com `ALTER TABLE ... ADD COLUMN` | Apagar e recriar a tabela (`DROP TABLE`) destruiria os favoritos que o usuário já salvou. |
| **Como responder `isFavorite(id)` rápido em listas?** | `List<Establishment>` (para ordem) + `Set<String> _favoriteIds` (para busca `O(1)`) | Percorrer a `List` com `.any()` faria busca linear `O(n)` em cada cartão a cada `build`. |
| **Como expor múltiplos estados na árvore?** | Pacote **`provider`** (`MultiProvider` + `ChangeNotifierProvider`) | Continuar criando classes `InheritedNotifier` manuais geraria código repetido e pirâmide no `CeliLacApp`. |
| **Como evitar colisão de `Hero` no `IndexedStack`?** | Tag com prefixo de origem: `'$origin-establishment-icon-$id'` (`'home'` vs `'favorites'`) | Desligar o `Hero` perderia a continuidade visual ao abrir o detalhe. |
| **Como manter o cartão acessível com dois toques?** | Retirar o `MergeSemantics` global do cartão e dar `tooltip` específico ao `FavoriteButton` | Manter `MergeSemantics` fundiria o botão de coração ao toque do cartão, impedindo seu uso por leitores de tela. |

## 9.2 Outras opções no ecossistema Flutter para persistência e estado

Vale conhecer as alternativas que você encontrará em vagas e projetos maiores:

- **Em bancos de dados locais:**
  - **`sqflite`** (usado aqui): acesso direto ao SQLite com SQL explícito. Excelente para aprender modelagem relacional, tipos, `CREATE TABLE`, `ALTER TABLE` e consultas parametrizadas.
  - **`drift`**: constrói uma camada fortemente tipada em cima do SQLite com geração de código, verificando suas consultas em tempo de compilação.
- **Em gerenciamento de estado:**
  - **`InheritedNotifier` nativo** (usado no Material 4): zero pacotes externos, ótimo para entender como o Flutter funciona por baixo.
  - **`provider`** (usado aqui): padrão recomendado pela documentação do Flutter para trabalhar com `ChangeNotifier` sem código repetitivo.
  - **`riverpod`** ou **`flutter_bloc`**: opções populares em equipes grandes quando há muitos estados assíncronos encadeados ou fluxos baseados em eventos.

---

# Parte 10: Aplicando no seu projeto

## 10.1 Como adaptar para o tema do seu aplicativo

Quase todo aplicativo tem uma coleção de itens que o usuário quer guardar localmente no aparelho:

| Tema do projeto | O que o usuário salva na tabela SQLite | Colunas principais além de `id` e `saved_at` |
|---|---|---|
| **Catálogo de cursos / aulas** | Cursos salvos para assistir depois | `title`, `instructor`, `duration_minutes`, `level`, `thumbnail_url` |
| **Imobiliária / moradia estudantil** | Imóveis favoritos para visitar | `title`, `neighborhood`, `rent_value`, `rooms`, `accepts_pets` |
| **Feira / receitas culinárias** | Receitas guardadas no caderno local | `title`, `prep_time_minutes`, `difficulty`, `tags` |
| **Saúde / clínicas e médicos** | Profissionais ou clínicas de confiança | `name`, `specialty`, `neighborhood`, `accepts_insurance`, `rating` |
| **Eventos / vagas de estágio** | Vagas marcadas para candidatura | `role`, `company`, `modality`, `stipend_value`, `deadline_epoch` |

## 10.2 Checklist de aplicação para os alunos

Use esta lista para conferir a implementação desta etapa no seu próprio projeto:

- [ ] **Dependências instaladas:** `provider`, `sqflite`, `path` em `dependencies` e `sqflite_common_ffi` em `dev_dependencies`.
- [ ] **Contrato no domínio:** interface `...Repository` em `domain/repositories/` sem importar `sqflite`.
- [ ] **Conversão isolada em `data/`:** métodos `toRow` e `...FromRow` traduzindo `enum`, `Set`, `DateTime` (`millisecondsSinceEpoch`) e `num.toDouble()`.
- [ ] **SQLite com versão e migração:** `createSchema` (`CREATE TABLE`) e `upgradeSchema` (`ALTER TABLE` com `if (oldVersion < ...)`), usando sempre `where: 'id = ?'` e `whereArgs: [id]`.
- [ ] **Controlador com `ChangeNotifier`:** persiste no banco antes de atualizar a memória e chamar `notifyListeners()`, mantendo um `Set<String>` para consultas `O(1)`.
- [ ] **`MultiProvider` no topo do app:** acima do `MaterialApp`, carregando os controladores em paralelo na `SplashPage`.
- [ ] **Uso correto de `watch` e `read`:** `context.watch<T>()` apenas dentro do `build`; `context.read<T>()` em callbacks (`onPressed`, `onTap`) e no `initState`.
- [ ] **Acessibilidade e responsividade:** botão de favoritar com `tooltip` contendo o nome do item, sem colisão de `Hero` entre abas e sem *overflow* com fonte a `200%` em tela `320×640`.
- [ ] **Testes automatizados passando:** testes de conversão, testes de banco SQLite em memória (incluindo migração de versão) e testes de widget da nova aba.

## 10.3 Desafios opcionais para ir além

1. **Desfazer remoção (*Undo* no `SnackBar`):** quando o usuário remover um favorito na `FavoritesPage`, mostre um `SnackBar` com `"Removido dos favoritos"` e uma `SnackBarAction(label: 'Desfazer', onPressed: ...)` que chama `toggle` de novo para restaurar o lugar.
2. **Ordenação escolhida pelo usuário na aba Favoritos:** adicione um seletor no topo da `FavoritesPage` permitindo alternar entre *"Mais recentes"*, *"Menor distância"* e *"Maior nota"*.
3. **Filtro "Apenas os que atendem ao meu perfil":** quando o perfil alimentar estiver completo, ofereça um `FilterChip` na `FavoritesPage` para filtrar apenas os favoritos compatíveis com as restrições atuais.

---

# Apêndice A: Solução de problemas comuns

| Sintoma / Mensagem de erro | Causa provável | Como corrigir |
|---|---|---|
| `DatabaseException(no such column: logo_source)` no celular ou emulador | A tabela foi criada em uma versão anterior do banco e o número de `version` não foi incrementado ou falta o `ALTER TABLE` no `onUpgrade`. | Incremente `schemaVersion` e adicione `if (oldVersion < novaVersao) { await db.execute('ALTER TABLE ... ADD COLUMN ...'); }` no `onUpgrade`. |
| `Bad state: Tried to listen to a value exposed with provider, from outside of the widget tree` | Foi chamado `context.watch<T>()` dentro de um `onPressed`, `onTap` ou `initState`. | Troque por **`context.read<T>()`** sempre que estiver fora do método `build`. |
| `ProviderNotFoundException: Error: Could not find the correct Provider<FavoritesController>` | O `ChangeNotifierProvider<FavoritesController>` ficou abaixo do `MaterialApp` (não alcança rotas empilhadas com `Navigator.push`) ou faltou no helper de teste. | Coloque o `MultiProvider` **acima** do `MaterialApp` em `CeliLacApp` e no `pumpWithProfile`. |
| `There are multiple heroes that share the same tag within a subtree` | O mesmo estabelecimento aparece na `HomePage` e na `FavoritesPage` dentro do `IndexedStack` com a mesma tag de `Hero`. | Passe `heroOrigin: 'favorites'` no cartão da `FavoritesPage` e na abertura da `EstablishmentDetailsPage`. |
| `SqfliteFfiException: duplicate column name` ao testar migração no `flutter test` | Dois `openDatabase(inMemoryDatabasePath)` compartilharam a mesma instância em memória. | Passe **`singleInstance: false`** no `OpenDatabaseOptions` dos testes em memória. |

---

# Apêndice B: Glossário desta etapa

- **Chave primária (`PRIMARY KEY`):** coluna que identifica cada linha da tabela de forma única (no CeliLac, o `id` do estabelecimento) e cria automaticamente um índice de busca rápida.
- **Esquema (*Schema*):** a definição estrutural das tabelas, colunas e tipos de um banco de dados.
- **Injeção de SQL (*SQL Injection*):** falha de segurança causada por concatenar variáveis diretamente na string SQL em vez de usar marcadores `?` (`whereArgs`).
- **Migração de banco (*Schema Migration*):** conjunto de instruções SQL (`ALTER TABLE`) executadas no `onUpgrade` para atualizar a estrutura do banco de uma versão para outra sem perder os dados já salvos pelo usuário.
- **`MultiProvider`:** widget do pacote `provider` que registra vários provedores de estado no topo da árvore sem precisar aninhar um dentro do outro.
- **Instantâneo (*Snapshot*):** cópia dos dados essenciais de uma entidade salva no momento da ação para permitir exibição imediata e *offline*.
- **`sqflite_common_ffi`:** implementação do SQLite baseada em FFI (*Foreign Function Interface*) que permite executar bancos SQLite reais em memória no computador durante os testes automatizados.
