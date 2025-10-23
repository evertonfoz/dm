Quais informações o dashboard precisa (mapeamento UI → campos)
=============================================================

Pelas telas, os itens que devem ser guardados localmente para a homepage são, no mínimo:

Provider (fornecedor):

- id (string) — identificador
- name (string)
- brandImageURL (string) — avatar/foto
- dominantColor (string) — se usado
- rating (float) — (se exibido)
- distance (float) — distância em metros/km (se calculada e mostrada)
- is_highlight (bool) — destaque do dia
- last_updated (timestamp)
- metadata/json (text) — campos extras

Product (produtos em banners/rodas):

- id (string)
- provider_id (string)
- name (string)
- description (text)
- image_url (string)
- price (real)
- currency (string)
- rating (real)
- is_favorite (bool)
- is_highlight (bool)
- tags (text) ou json
- last_updated (timestamp)

Contadores/estados (opcional):

- notificações não-lidas, mensagens não lidas, etc — podem ser uma tabela de counters ou saved in SharedPreferences.

Recomendações gerais de arquitetura
==================================

Use uma biblioteca de persistência local:

- Recomendação 1 (mais simples): `sqflite` (bom controle SQL, fácil de integrar).
- Recomendação 2 (melhor tipagem e produtividade): `drift` (antigo moor) — gera código, fornece modelos fortemente tipados, migrations automáticas.

Organização sugerida:

- Nova pasta: `lib/core/local_db/` ou `lib/app_libraries/local_db/`
- Camadas:
  - DB provider (abrir/upgrade): ex. `local_db.dart`
  - DAOs / Repositories: `providers_dao.dart`, `products_dao.dart`
  - Modelos/entidades (se usar drift, gerados automaticamente): `provider_entity`, `product_entity`
  - Services que exponham métodos ao presentation: `dashboard_repository.dart` (`getHighlights`, `getProviders`, `refreshFromRemote`, `markFavorite`)

Esquema de banco sugerido (SQL) — criação rápida
===============================================

Sugiro duas tabelas iniciais: `providers` e `products`.

SQL para sqlite (exemplo):

CREATE TABLE providers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  brand_image_url TEXT,
  dominant_color TEXT,
  rating REAL,
  distance REAL,
  is_highlight INTEGER DEFAULT 0,
  last_updated TEXT,
  metadata TEXT
);

CREATE TABLE products (
  id TEXT PRIMARY KEY,
  provider_id TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  price REAL,
  currency TEXT,
  rating REAL,
  is_favorite INTEGER DEFAULT 0,
  is_highlight INTEGER DEFAULT 0,
  tags TEXT,
  last_updated TEXT,
  FOREIGN KEY(provider_id) REFERENCES providers(id)
);

Observações:

- Uso de TEXT para timestamps em ISO8601 facilita debugar; em SQLite você também pode usar INTEGER (epoch).
- `is_*` armazenados como INTEGER 0/1.
- `metadata` JSON em TEXT para campos variáveis.

Exemplos de queries úteis
=========================

- Buscar providers em destaque:
  SELECT * FROM providers WHERE is_highlight = 1 ORDER BY last_updated DESC;

- Buscar produtos em destaque:
  SELECT * FROM products WHERE is_highlight = 1 ORDER BY last_updated DESC;

- Buscar produtos por provider:
  SELECT * FROM products WHERE provider_id = ? ORDER BY last_updated DESC;

- Marcar favorito:
  UPDATE products SET is_favorite = 1 WHERE id = ?;

Exemplo de integração em Dart (sqflite) — sketch
===============================================

Abrir DB:

final db = await openDatabase(
  join(await getDatabasesPath(), 'app_db.db'),
  onCreate: (db, version) async {
    await db.execute('''CREATE TABLE providers (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      brand_image_url TEXT,
      dominant_color TEXT,
      rating REAL,
      distance REAL,
      is_highlight INTEGER DEFAULT 0,
      last_updated TEXT,
      metadata TEXT
    );

    CREATE TABLE products (
      id TEXT PRIMARY KEY,
      provider_id TEXT NOT NULL,
      name TEXT NOT NULL,
      description TEXT,
      image_url TEXT,
      price REAL,
      currency TEXT,
      rating REAL,
      is_favorite INTEGER DEFAULT 0,
      is_highlight INTEGER DEFAULT 0,
      tags TEXT,
      last_updated TEXT
    );''');
  },
  version: 1,
);

DAO simples (inserir/ler):

Future<void> insertProvider(ProviderModel provider) async {
  await db.insert('providers', provider.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
}

Future<List<ProviderModel>> getHighlightProviders() async {
  final List<Map<String, dynamic>> maps = await db.query('providers', where: 'is_highlight = ?', whereArgs: [1]);
  return List.generate(maps.length, (i) => ProviderModel.fromMap(maps[i]));
}

Se preferir `drift`, eu posso gerar as classes `Table` e o código fonte (forte tipagem + migrations automáticas).

Onde adaptar o código do dashboard para ler do DB
================================================

Arquivos/locais onde trocar entradas temporárias / chamadas remotas por leitura local:

- Fornecedores/avatares:
  - `banner.dart` (ProvidersBannerTopToDashboardHomepage)
  - `listview.dart`
  - `brand_avatar.dart` (navega p/ ./providerCover)
  -> substituir `ListView.builder` com itemCount: 5 estático por um stream/future que leia do providers via repository.

- Produtos/banners:
  - `banner.dart`
  - `image.dart`
  - `product_features.dart`
  -> consumir `productsDao.getHighlights()` ou `dashboardRepository.getHighlightedProducts()`.

- Badges/contadores:
  - `actions.dart` — se quiser armazenar localmente o número de mensagens não lidas, criar tabela `counters` ou usar `SharedPreferences` dependendo do caso.

Onde popular o DB:
==================

- Implementar um método `dashboardRepository.refreshFromRemote()` que consulta API/Hasura e grava nas tabelas locais (sync strategy).
- Chamar `refreshFromRemote()` no fluxo de inicialização do dashboard (ex.: em `DashBoardHomePage initState`) ou em um background sync.