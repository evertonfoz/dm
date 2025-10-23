Entities — Modelagem de domínio para o Dashboard
===============================================

Contexto e objetivo
-------------------
A partir do mapeamento presente em `supabase.md`, vamos transformar o esquema relacional sugerido em um conjunto de entidades de domínio bem modeladas para uso no app Flutter. O foco aqui é oferecer modelos claros (fields, tipos, constraints), relacionamentos, índices recomendados, queries de leitura/escrita comuns, e orientações para implementação em Dart usando `drift` (preferido) ou `sqflite`.

Tabelas identificadas (do escopo):
- providers
- products
- counters (opcional, para notificações/estados)

Para suportar futuras features sugiro ainda considerar:
- favorites (se quiser separá-los em vez de campo is_favorite em products)
- tags (tabela relacional para tags se precisar filtrar/consultar)

Entidades e modelagem
---------------------
1) Provider
-----------
- Objetivo: representar fornecedores exibidos no dashboard (banners, listagens, detalhes rápidos).
- Tabela: `providers`
- Campos (Dart type → SQL type):
  - id: String (TEXT) — PK, não nulo
  - name: String (TEXT) — não nulo
  - brandImageUrl: String? (TEXT) — nullable
  - dominantColor: String? (TEXT) — armazenar hex `#RRGGBB` ou `argb` opcional
  - rating: double? (REAL)
  - distance: double? (REAL) — metros/km conforme decisão de UI
  - isHighlight: bool (INTEGER 0/1) — default false
  - lastUpdated: DateTime? (TEXT) — ISO8601
  - metadata: Map<String, dynamic>? (TEXT) — JSON string

- Índices recomendados:
  - is_highlight (para filtrar destaques rapidamente)
  - last_updated (para ordenação/refresh)

- Relações:
  - 1:N → products (provider_id em products)

- Queries comuns:
  - getHighlights: SELECT * FROM providers WHERE is_highlight = 1 ORDER BY last_updated DESC;
  - getById(id)
  - searchByName(query) — LIKE '%query%'

- Domain model (Dart):
  class Provider {
    final String id;
    final String name;
    final String? brandImageUrl;
    final String? dominantColor;
    final double? rating;
    final double? distance;
    final bool isHighlight;
    final DateTime? lastUpdated;
    final Map<String, dynamic>? metadata;
  }

2) Product
---------
- Objetivo: representar produtos usados em banners/rodas/tiles.
- Tabela: `products`
- Campos:
  - id: String (TEXT) — PK
  - providerId: String (TEXT) — FK -> providers.id
  - name: String (TEXT) — não nulo
  - description: String? (TEXT)
  - imageUrl: String? (TEXT)
  - price: double? (REAL)
  - currency: String? (TEXT)
  - rating: double? (REAL)
  - isFavorite: bool (INTEGER 0/1) — default false
  - isHighlight: bool (INTEGER 0/1) — default false
  - tags: String? (TEXT) — JSON array ou CSV; se precisar filtrar, usar tabela relacional
  - lastUpdated: DateTime? (TEXT)

- Índices recomendados:
  - is_highlight
  - provider_id
  - is_favorite (se buscas frequentes por favoritos)

- Relações:
  - N:1 → provider

- Queries comuns:
  - getHighlights: SELECT * FROM products WHERE is_highlight = 1 ORDER BY last_updated DESC;
  - getByProvider(providerId)
  - markFavorite(productId, bool)

- Domain model (Dart):
  class Product {
    final String id;
    final String providerId;
    final String name;
    final String? description;
    final String? imageUrl;
    final double? price;
    final String? currency;
    final double? rating;
    final bool isFavorite;
    final bool isHighlight;
    final List<String>? tags;
    final DateTime? lastUpdated;
  }

3) Counter (opcional)
----------------------
- Objetivo: armazenar contadores simples (notificações não-lidas, mensagens, etc.)
- Tabela: `counters`
- Campos:
  - key: String (TEXT) — PK (ex: 'unread_notifications')
  - value: int (INTEGER)
  - last_updated: DateTime (TEXT)

- Alternativa: usar `SharedPreferences` para contadores simples sem necessidade de query complexa.

Modelagem de relacionamentos e decisões de normalização
------------------------------------------------------
- Tags e metadados: se a aplicação precisa filtrar por tags (ex.: filtrar produtos por 'gluten-free'), crie uma tabela `tags` e `product_tags(product_id, tag_id)` para eficiência. Caso contrário, mantenha `tags` como JSON/text em `products` para simplicidade.
- Favoritos: campo `is_favorite` em `products` é suficiente para a maioria dos casos; se houver necessidade de multi-device sync ou metadados por usuário, crie tabela `favorites(user_id, product_id, created_at)`.
- Metadata JSON: utilizar `TEXT` com JSON para flexibilidade. No `drift`, considere usar TypeConverters para Map<String,dynamic>.

Especificações técnicas para implementação (Drift vs Sqflite)
-------------------------------------------------------------
1) Drift (recomendado se quiser tipo-safe e migrations):
- Criar `Tables`:
  - Providers: class Providers extends Table { TextColumn get id => text()(); ... }
  - Products: class Products extends Table { TextColumn get id => text()(); TextColumn get providerId => text().customConstraint('REFERENCES providers(id)'); ... }
- Gerar DAOs:
  - ProvidersDao { Future<List<Provider>> getHighlights(); Future<Provider?> getById(String id); Future<void> upsertProvider(Provider provider); }
  - ProductsDao { Future<List<Product>> getHighlights(); Future<void> markFavorite(String id, bool isFav); }
- Migrations: drift gera suporte automático para schema changes quando usar moor_generator/build_runner.

2) Sqflite (mais manual):
- Criar `local_db.dart` com openDatabase e exec do CREATE TABLE quando onCreate.
- Implementar classes models (ProviderModel, ProductModel).
- Criar repositories/DAOs que usem queries raw e converta Map<String,dynamic> para modelos.

Índices e performance
---------------------
- Crie índices nos campos usados para filtragem/ordenação (is_highlight, provider_id, is_favorite).
- Se o app fizer buscas por nome com LIKE, considere criar uma coluna `name_normalized` para pesquisas mais rápidas e consistentes.

Exemplo de API de repositório (Dart)
------------------------------------
class DashboardRepository {
  Future<List<Provider>> getHighlights();
  Future<List<Product>> getHighlightedProducts();
  Future<void> refreshFromRemote();
  Future<void> markFavorite(String productId, bool isFavorite);
}

Onde adaptar no app
-------------------
- Trocar providers/banners estáticos por chamadas a `dashboardRepository.getHighlights()`.
- Produtos em UI: consumir `dashboardRepository.getHighlightedProducts()`.
- Ao receber dados remotos: mapear/normalizar e gravar via DAOs.

Boas práticas
------------
- Normalize apenas quando necessário; prefira JSON em TEXT para campos extensíveis que não serão filtrados.
- Versione o schema e mantenha migrations claras.
- Escreva testes unitários para DAOs (in-memory drift DB permite testes rápidos).

Índice rápido de arquivos sugeridos
-----------------------------------
- lib/core/local_db/local_db.dart (abertura/upgrade do DB)
- lib/core/local_db/tables.dart (se optar por drift)
- lib/core/local_db/providers_dao.dart
- lib/core/local_db/products_dao.dart
- lib/core/repositories/dashboard_repository.dart

Conclusão
---------
Este `entities.md` descreve as entidades centrais (Provider, Product, Counter) mapeadas do `supabase.md`, com recomendações para implementação em `drift` ou `sqflite`. Se quiser, posso gerar as classes `Table` do `drift` e os DAOs correspondentes automaticamente agora.