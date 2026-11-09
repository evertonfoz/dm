# Etapa 4 — Tradução de Tipos Ricos e Compostos (`Dart` ↔ `SQLite`)
## Do Abismo de Tipos à Camada de Mapeamento Resiliente e Desacoplada

> **Instrução para o Gamma:** Cada seção separada por `---` corresponde a um slide. O foco está na progressão **Problema → Dor Arquitetural → Fundamentação → Como Resolver**, utilizando diagramas visuais, tabelas comparativas e trechos mínimos de código.

---

## Slide 1 — Capa

### Etapa 4: Tradução de Tipos Ricos e Compostos (`Dart` ↔ `SQLite`)
**Como persistir Enums, Conjuntos, Datas e Decimais mantendo a entidade de domínio 100% pura**

- **Contexto:** Laboratório Sequencial CeliLac (Etapa 4 de 7)
- **Foco da aula:**
  1. Sentir o conflito entre o sistema de tipos estático do Dart e os 5 tipos primitivos do SQLite
  2. Desarmar a bomba-relógio do `.index` e prevenir o crash fatal de `TypeError` no `double`
  3. Aplicar o padrão *Data Mapper* com extensões Dart (`toRow` e `establishmentFromRow`)
  4. Serializar coleções `Set<Enum>` com determinismo e desserializar com recursos modernos do Dart 3

---

## Slide 2 — O Problema Real: Entidades Ricas vs. Banco Primitivo

### O abismo entre a linguagem orientada a objetos e o banco relacional em C

No mundo real do **CeliLac**, nossos estabelecimentos possuem atributos expressivos e fortemente tipados:

```text
SISTEMA DE TIPOS DO DART                        CLASSES DE ARMAZENAMENTO DO SQLITE
┌──────────────────────────────────────┐        ┌──────────────────────────────────┐
│ id: String                           │───────►│ TEXT                             │
│ name: String                         │───────►│ TEXT                             │
│ category: EstablishmentCategory      │───?───►│ ? (SQLite NÃO tem tipo ENUM)     │
│ neighborhood: String                 │───────►│ TEXT                             │
│ distanceInKm: double                 │───────►│ REAL                             │
│ rating: double                       │───────►│ REAL                             │
│ dietaryOptions: Set<DietaryOption>   │───?───►│ ? (SQLite NÃO tem tipo SET/ARRAY)│
│ logoSource: String?                  │───────►│ TEXT ou NULL                     │
│ savedAt: DateTime                    │───?───►│ ? (SQLite NÃO tem tipo DATETIME) │
└──────────────────────────────────────┘        └──────────────────────────────────┘
```

- **A realidade técnica:** o SQLite só possui **5 classes de armazenamento**: `NULL`, `INTEGER`, `REAL`, `TEXT` e `BLOB`.
- **A pergunta central:** Como trafegar esses dados complexos sem perder integridade, sem degradar performance e sem quebrar o app?

---

## Slide 3 — A Bomba-Relógio do `.index` em Enums

### O erro clássico de tutoriais na internet que corrompe dados em produção

Muitos desenvolvedores novatos persistem enums gravando seu índice posicional (`category.index`):

```dart
// ❌ CÓDIGO PERIGOSO E FRÁGIL:
'category': establishment.category.index, // Grava 0, 1, 2...
```

### O cenário do desastre em produção:
1. **Mês 1:** Enum declarado como `[restaurant (0), bakery (1), cafe (2)]`. O usuário salva o *Café Aconchego*. No banco do celular, grava o número **`2`**.
2. **Mês 3:** O time adiciona `market` em ordem alfabética: `[bakery (0), cafe (1), market (2), restaurant (3)]`.
3. **Mês 4:** O app atualiza pela Play Store. O app lê o valor **`2`** do banco. O Dart converte `values[2]` para **`market`**!
4. **Resultado:** **O Café Aconchego virou um Mercado** da noite para o dia, sem erro de compilação ou aviso de log.

> **Regra de Ouro:** Nunca persista enums como `.index`. Persista sempre a representação explícita com `.name`!

---

## Slide 4 — O Crash Fatal do `double` no Dart (`TypeError`)

### Por que notas cheias como `5.0` derrubam o aplicativo?

Observe o que acontece quando fazemos a leitura direta e ingênua:

```dart
// ❌ CRASH EM POTENCIAL:
final rating = row['rating'] as double;
```

### A armadilha da Afinidade de Tipos (*Type Affinity*) do SQLite:
- Quando salvamos uma nota decimal como `4.8`, o SQLite armazena como `REAL` (8 bytes). O cast `as double` funciona.
- Mas quando o usuário salva uma nota cheia **`5.0`** ou distância **`2.0`**, o SQLite otimiza o disco e grava o valor como **`INTEGER`**!
- O driver `sqflite` lê um inteiro e instancia um objeto **`int`** do Dart (`5`).
- No Dart, **`int` não é subclasse de `double`** (ambas herdam de `num`).

```text
Unhandled Exception: type 'int' is not a subtype of type 'double' in type cast
```
A tela vermelha de erro (*Red Screen*) aparece no celular do usuário por causa de um cast rígido!

---

## Slide 5 — O Antipadrão da Poluição da Entidade de Domínio

### Onde deve morar o código de conversão para o banco de dados?

A tentação comum é abrir a entidade `Establishment` e colocar:

```dart
// ❌ POLUIÇÃO DA CAMADA DE DOMÍNIO:
class Establishment {
  // ... atributos de negócio ...

  Map<String, dynamic> toMap() => { ... };     // Conhece colunas do SQLite!
  factory Establishment.fromMap(...) => ...;   // Acoplado a detalhes de banco!
}
```

### Por que isso viola a Arquitetura Limpa e o SRP?
1. **Vazamento de Infraestrutura:** o Domínio passa a conhecer nomes de colunas SQL (`saved_at`, `distance_in_km`) e tipos do SQLite.
2. **Múltiplos Mappers Futuros:** se amanhã o app consumir uma API REST com chaves *camelCase*, teremos que colocar `toJson`, `fromJson`, `toSqlite`, `toFirebase` na mesma classe de negócio.
3. **A Solução:** Isolar a tradução na camada de **Dados (`data/`)** através do padrão **Data Mapper** e extensões Dart!

---

## Slide 6 — As 5 Classes de Armazenamento do SQLite

### Como o SQLite realmente organiza os dados em disco

| Classe de Armazenamento | O que representa | Mapeamento no Dart | Cuidados de Engenharia |
|---|---|---|---|
| **`NULL`** | Ausência de valor | `null` | Campos opcionais como `logoSource`. |
| **`INTEGER`** | Inteiro com sinal (1 a 8 bytes) | `int` | Usado para IDs numéricos e `DateTime` em Epoch. |
| **`REAL`** | Ponto flutuante IEEE 754 (8 bytes) | `double` | **Atenção:** valores com `.0` podem virar `INTEGER` no SQLite! |
| **`TEXT`** | String em UTF-8 / UTF-16 | `String` | Usado para enums (`.name`), strings e listas em CSV. |
| **`BLOB`** | Dados binários brutos | `Uint8List` | Reservado para imagens binárias ou chaves criptográficas. |

---

## Slide 7 — Persistindo Datas: `INTEGER` (Epoch ms) vs. `TEXT` (ISO-8601)

### Por que milissegundos desde a época Unix é a melhor escolha?

Podemos salvar datas como texto (`'2026-11-05T18:30:00Z'`) ou como número inteiro de 64 bits (`1793910600000`).

| Critério de Comparação | ISO-8601 (`TEXT`) | Epoch em Milissegundos (`INTEGER`) |
|---|---|---|
| **Espaço ocupado no disco** | 24 a 30 bytes por linha | **Apenas 8 bytes** |
| **Desempenho de ordenação (`ORDER BY saved_at DESC`)** | Comparação textual de strings na CPU | **Comparação numérica binária ultrarrápida** |
| **Conversão no Dart** | `DateTime.parse()` com expressões regulares pesadas | `DateTime.fromMillisecondsSinceEpoch()` instantâneo |
| **Legibilidade no SELECT direto** | Excelente para humanos | Exige conversão manual para leitura humana |

> **Decisão de Arquitetura no CeliLac:** Adotamos `INTEGER` com `millisecondsSinceEpoch` para garantir máxima fluidez de rolagem (60/120 fps) na aba de Favoritos.

---

## Slide 8 — Persistência Segura de Enums: `.name` e `asNameMap()`

### Como garantir velocidade $O(1)$ e tolerância a valores desconhecidos

#### 1. Na Gravação (Escrita):
```dart
'category': establishment.category.name, // Grava: 'restaurant', 'bakery', 'cafe' ou 'market'
```

#### 2. Na Leitura (Desserialização com tolerância):
Em vez de fazer buscas lentas com `.firstWhere()`, utilizamos o mapa estático pré-computado nativo do Dart:

```dart
final categories = EstablishmentCategory.values.asNameMap();

// Leitura em O(1) com fallback seguro:
category: categories[row['category']] ?? EstablishmentCategory.restaurant,
```

- **Tempo Constante $O(1)$:** A busca por nome é instantânea via tabela *hash*.
- **Resiliência a Falhas:** Se o banco contiver uma categoria descontinuada ou vinda de versão antiga, o fallback `??` garante que a tela abra normalmente em vez de travar!

---

## Slide 9 — Persistindo Coleções: `Set<DietaryOption>` em CSV Inline

### Como salvar múltiplos selos alimentares sem criar tabelas intermediárias complexas

Como o SQLite não possui suporte a coleções ou arrays, serializamos o conjunto como uma `String` compacta delimitada por vírgula:

```dart
// Escrita:
'dietary_options': [
  for (final option in dietaryOptions) option.name,
].join(','),
```

- Se o estabelecimento tiver `{DietaryOption.glutenFree, DietaryOption.lactoseFree}`, o campo no banco armazena:
  `'glutenFree,lactoseFree'`
- Se não tiver nenhuma restrição cadastrada, armazena:
  `''` (string vazia).
- **Vantagem:** Zero sobrecarga de junções SQL (*JOINs*), leitura imediata e pegada mínima de armazenamento no SQLite.

---

## Slide 10 — Desserialização com Recursos Modernos do Dart 3

### Pattern Matching, Guards e Operador Null-Aware em Coleções

Para ler a string CSV de volta em `Set<DietaryOption>`, aplicamos a sintaxe expressiva do Dart 3:

```dart
final options = DietaryOption.values.asNameMap();

dietaryOptions: {
  if (row['dietary_options'] case final String raw when raw.isNotEmpty)
    for (final name in raw.split(','))
      ?options[name],
},
```

### Por que essa construção é uma aula de elegância e robustez?
1. **`case final String raw when raw.isNotEmpty`:** Valida tipo e descarta nulos e strings vazias antes de tentar quebrar o texto.
2. **`for (final name in raw.split(','))`:** Itera token a token do CSV.
3. **`?options[name]` (*Null-Aware Element*):** Se `name` for válido, insere o enum correspondente. Se for um selo desconhecido ou inválido (retornou `null`), o elemento é descartado silenciosamente sem quebrar o conjunto!

---

## Slide 11 — A Defesa Universal Numérica: `(raw as num).toDouble()`

### Eliminando de vez o risco de `TypeError` entre inteiros e decimais

Para resolver a flutuação do SQLite (que armazena `5.0` como `int` e `4.8` como `double`), exploramos a hierarquia nativa do Dart:

```text
            ┌─────────────────┐
            │   abstract num  │
            └────────┬────────┘
                     │
          ┌──────────┴──────────┐
          ▼                     ▼
┌──────────────────┐  ┌──────────────────┐
│      int         │  │     double       │
│  (ex.: 5)        │  │  (ex.: 5.0, 4.8) │
└──────────────────┘  └──────────────────┘
```

```dart
// ✅ DEFESA UNIVERSAL COMPLETA:
distanceInKm: (row['distance_in_km'] as num).toDouble(),
rating: (row['rating'] as num).toDouble(),
```

- Qualquer número devolvido pelo SQLite satisfaz `as num`.
- O método `.toDouble()` converte `5` em `5.0` ou mantém `4.8` intacto, com custo computacional desprezível e segurança absoluta de tipos.

---

## Slide 12 — O Padrão *Data Mapper* com Dart `extension`

### O isolamento ideal entre Domínio e Infraestrutura

Criamos o arquivo `favorite_establishment_row.dart` na camada `data/`:

```dart
// Extensão para serialização (Domínio -> SQL):
extension FavoriteEstablishmentRow on Establishment {
  Map<String, Object?> toRow({required DateTime savedAt}) => {
    'id': id,
    'name': name,
    'category': category.name,
    'neighborhood': neighborhood,
    'distance_in_km': distanceInKm,
    'rating': rating,
    'dietary_options': [for (final o in dietaryOptions) o.name].join(','),
    'logo_source': logoSource,
    'saved_at': savedAt.millisecondsSinceEpoch,
  };
}

// Função pura para desserialização (SQL -> Domínio):
Establishment establishmentFromRow(Map<String, Object?> row) { ... }
```

- `Establishment` (Domínio) não conhece SQLite.
- `SqliteFavoritesRepository` (Dados) apenas importa a extensão e ganha a capacidade de converter linhas.

---

## Slide 13 — Prática: Criando os Enums de Domínio

### `establishment_category.dart` e `dietary_option.dart`

Criamos os novos tipos puros em `lib/features/establishments/domain/entities/`:

```dart
// establishment_category.dart
enum EstablishmentCategory {
  restaurant('Restaurante'),
  bakery('Padaria'),
  cafe('Café'),
  market('Mercado');

  const EstablishmentCategory(this.label);
  final String label;
}
```

```dart
// dietary_option.dart
enum DietaryOption {
  glutenFree('Sem glúten'),
  lactoseFree('Sem lactose');

  const DietaryOption(this.label);
  final String label;
}
```

- Enums enriquecidos com atributo `label` para exibição direta e elegante na interface.

---

## Slide 14 — Prática: Entidade `Establishment` Enriquecida

### Atualizando o modelo com tipos expressivos em `domain/entities/`

```dart
class Establishment {
  const Establishment({
    required this.id,
    required this.name,
    required this.category,
    required this.neighborhood,
    required this.distanceInKm,
    required this.rating,
    required this.dietaryOptions,
    this.logoSource,
  });

  final String id;
  final String name;
  final EstablishmentCategory category;
  final String neighborhood;
  final double distanceInKm;
  final double rating;
  final Set<DietaryOption> dietaryOptions;
  final String? logoSource;
}
```

- **Imutabilidade mantida:** construtor `const` com todos os atributos `final`.
- **Zero referências a bancos de dados:** pura regra de negócio.

---

## Slide 15 — Prática: DDL Completo e Repositório SQLite

### `sqlite_favorites_repository.dart` delegando a conversão ao Mapper

```sql
CREATE TABLE favorites (
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
```

No repositório, o código fica limpo e declarativo:

```dart
// Leitura:
final rows = await db.query(tableName, orderBy: 'saved_at DESC');
return [for (final row in rows) establishmentFromRow(row)];

// Escrita:
await db.insert(
  tableName,
  establishment.toRow(savedAt: savedAt ?? DateTime.now()),
  conflictAlgorithm: ConflictAlgorithm.replace,
);
```

---

## Slide 16 — Prática: Cartão Enriquecido com Tags Visuais

### Exibindo chips de restrição e distância em `establishment_card.dart`

```dart
// Exibição de categoria formatada e distância:
Text('${establishment.category.label} · ${establishment.neighborhood} · ${establishment.distanceInKm.toStringAsFixed(1)} km')

// Chips de opções alimentares com Wrap:
if (establishment.dietaryOptions.isNotEmpty)
  Wrap(
    spacing: 6,
    children: [
      for (final option in establishment.dietaryOptions)
        Chip(label: Text(option.label)),
    ],
  )
```

- O cartão agora reflete a riqueza dos dados gravados e recuperados do SQLite.

---

## Slide 17 — Verificação Prática 1: O Teste da Persistência Completa

### Validando a sobrevivência dos tipos ricos após o fechamento do app

```text
ROTEIRO DE VALIDAÇÃO AO VIVO:
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. Favoritar o "Café Aconchego" (nota 5.0, tags: Sem glúten, Sem lactose)   │
│ 2. Favoritar o "Mercado Naturalis" (distância 2.0 km, tag: Sem lactose)     │
│ 3. Conferir na aba Favoritos: tags renderizadas e categorias formatadas     │
│ 4. Encerrar o app totalmente no terminal com 'q'                            │
│ 5. Reabrir com 'flutter run' e voltar aos Favoritos                         │
│ 6. SUCESSO: todos os tipos ricos foram reconstituídos perfeitamente!        │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Slide 18 — Verificação Prática 2: Provocando o Crash do `double`

### Experimento didático de falha controlada em sala de aula

1. No arquivo `favorite_establishment_row.dart`, comente temporariamente a defesa:
   ```dart
   // ❌ EXPERIMENTO DIDÁTICO:
   rating: row['rating'] as double,
   ```
2. Abra a aba Favoritos: como o Café Aconchego possui nota `5.0` (armazenada como `INTEGER` pelo SQLite), a tela explode com:
   `type 'int' is not a subtype of type 'double' in type cast`
3. Restaure a defesa:
   ```dart
   // ✅ RESTAURADO:
   rating: (row['rating'] as num).toDouble(),
   ```
4. A tela volta a carregar perfeitamente. Os estudantes nunca mais esquecerão essa regra!

---

## Slide 19 — Verificação Prática 3: Provocando Enum Desconhecido

### Testando a resiliência contra dados legados ou corrompidos

No terminal do emulador via `adb shell sqlite3`:

```sql
INSERT INTO favorites (id, name, category, neighborhood, distance_in_km, rating, dietary_options, saved_at)
VALUES ('99', 'Farmácia Viva', 'pharmacy', 'Centro', 0.5, 4.5, 'glutenFree,vegan', 9999999999999);
```

- O valor `'pharmacy'` não existe no enum `EstablishmentCategory`.
- O valor `'vegan'` não existe no enum `DietaryOption`.
- **Comportamento do App:**
  - `categories['pharmacy'] ?? restaurant` → exibe como **Restaurante** (sem crash).
  - `?options['vegan']` → descarta `'vegan'` silenciosamente e mantém apenas **Sem glúten**.
  - **O aplicativo permanece 100% resiliente!**

---

## Slide 20 — Ponte Direta com o CeliLac

### Onde exatamente cada peça desta aula se encontra no projeto real

| No Laboratório (Etapa 4) | No Projeto Real **CeliLac** | Papel na Arquitetura |
|---|---|---|
| `favorite_establishment_row.dart` | `lib/features/favorites/data/favorite_establishment_row.dart` | Data Mapper central: extensão `toRow` e função `establishmentFromRow`. |
| `EstablishmentCategory` | `lib/features/establishments/domain/entities/establishment_category.dart` | Enum com rótulos `label` para exibição na UI. |
| `DietaryOption` | `lib/features/establishments/domain/entities/dietary_option.dart` | Enum de selos alimentares serializado como CSV. |
| `Establishment` puro | `lib/features/establishments/domain/entities/establishment.dart` | Entidade pura de domínio sem dependência de banco. |
| `SqliteFavoritesRepository` | `lib/features/favorites/data/sqlite_favorites_repository.dart` | Repositório que delega o mapeamento SQL exclusivamente ao mapper. |

---

## Slide 21 — Conclusão e Gancho para a Etapa 5

### O que conquistamos hoje e para onde vamos na próxima aula?

```text
PROGRESSÃO DO APRENDIZADO:
Etapa 1: Estado Compartilhado em Memória (ChangeNotifier + provider)
Etapa 2: Contrato FavoritesRepository e Assincronia
Etapa 3: SQLite CRUD Seguro e Imunidade a SQL Injection
Etapa 4: Tradução de Tipos Ricos com Data Mapper e Resiliência (Concluída!)
   ▼
Etapa 5: O que fazer quando o app já está na loja e precisamos mudar o banco?
```

- **A provocação da Etapa 5:** Hoje tivemos que apagar o banco para recriar a tabela com as novas colunas. Mas em produção com 100.000 usuários ativos, **você não pode apagar o banco!**
- **O desafio:** Como usar `schemaVersion = 2`, `onUpgrade` e `ALTER TABLE` para evoluir o banco sem perder nenhum dado já salvo?
- **Até a Etapa 5!**

