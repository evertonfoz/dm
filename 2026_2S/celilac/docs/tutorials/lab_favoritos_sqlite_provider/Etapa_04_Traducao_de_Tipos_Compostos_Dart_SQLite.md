# Etapa 4 — Tradução de Tipos Ricos e Compostos (`Dart` ↔ `SQLite`)

## Introdução: O que este documento propõe e resolve?

### 1. O Problema Real que Estamos Enfrentando
Ao final da **Etapa 3**, alcançamos uma grande vitória arquitetural:
- O aplicativo finalmente grava dados no disco físico através do banco embutido **SQLite (`sqflite`)**.
- A persistência sobrevive ao encerramento do processo do app e a reinicializações do dispositivo.
- As consultas e deleções estão protegidas contra ataques de *SQL Injection* graças ao uso de parâmetros posicionais (`where: 'id = ?'` e `whereArgs: [id]`).
- O `FavoritesController` e toda a camada de interface (`presentation`) continuam completamente desacoplados da infraestrutura.

No entanto, o modelo de dados utilizado na Etapa 3 foi propositalmente simplificado: a categoria era uma simples `String` ('Café', 'Padaria'), não existiam restrições alimentares compostas e a data de salvamento era gerada diretamente no método `add` do repositório.

Em um aplicativo real de engenharia — como o **CeliLac** — as entidades do mundo real não são compostas apenas por primitivos planos. No **CeliLac**, a entidade `Establishment` possui:
1. **Tipos Enumerados Fortemente Tipados (`enum EstablishmentCategory`):** `restaurant`, `bakery`, `cafe`, `market`.
2. **Coleções e Conjuntos Compostos (`Set<DietaryOption>`):** como `{DietaryOption.glutenFree, DietaryOption.lactoseFree}`, representando os selos de segurança alimentar que o local atende.
3. **Números Decimais em Ponto Flutuante (`double`):** como a nota de avaliação `rating` (ex.: `4.8`) e a distância geográfica `distanceInKm` (ex.: `2.5`).
4. **Instantes Temporais Precisos (`DateTime`):** o momento exato em que o usuário salvou aquele favorito, permitindo a ordenação cronológica do mais recente ao mais antigo.
5. **Propriedades Opcionais / Nulas (`String? logoSource`):** o caminho ou URL do logotipo do estabelecimento, que pode ou não estar presente.

Aqui surge o grande abismo de engenharia entre a linguagem de programação e o banco de dados:
> **O SQLite não é orientado a objetos.** Ele é um motor de banco relacional embutido escrito em C na década de 2000 e possui **apenas 5 classes de armazenamento primitivas**: `NULL`, `INTEGER`, `REAL`, `TEXT` e `BLOB`. Ele **não possui** tipo `ENUM`, **não possui** tipo `DATETIME`, **não possui** suporte nativo para listas ou conjuntos (`SET`), e lida com números de ponto flutuante de uma maneira dinâmica que pode derrubar o aplicativo em produção.

Quando desenvolvedores tentam realizar essa ponte de forma amadora, três desastres técnicos costumam acontecer:
1. **A Armadilha do `.index` do Enum:** salvar o enum no banco como um número inteiro (`category.index`). Se amanhã um novo desenvolvedor adicionar uma nova categoria no início do enum ou reordenar seus valores em ordem alfabética no código Dart, **todos os dados já gravados no celular dos usuários mudarão silenciosamente de categoria!** Uma padaria se transformará em farmácia ou restaurante sem que nenhum erro de compilação ocorra.
2. **O Crash Fatal do `double` no Dart (`TypeError`):** no SQLite, colunas declaradas como `REAL` sofrem da chamada *Afinidade de Tipos Numéricos*. Se você salvar uma nota `5.0`, o SQLite pode otimizar o armazenamento em disco e guardar o valor `5` como um `INTEGER`. Na hora de ler, o Dart recebe um `int`. Se o desenvolvedor fizer `row['rating'] as double`, o Dart lançará imediatamente uma exceção fatal irrecuperável em tempo de execução:
   `TypeError: 5 is not a subtype of type double in type cast`.
3. **Poluição da Camada de Domínio:** para fazer a conversão, muitos programadores colocam métodos `toMap()` e `fromMap()` cheios de SQL diretamente dentro da classe `Establishment`. Isso destrói a Arquitetura Limpa: a regra de negócio central do aplicativo passa a depender de detalhes de implementação do SQLite.

---

### 2. O que esta Etapa 4 Propõe e Resolve
Este documento propõe a criação de uma **camada de tradução bidirecional isolada (*Data Mapper Pattern*)**, resolvendo cinco desafios cruciais de integridade de dados e arquitetura:

1. **Separação Arquitetural com o Padrão *Data Mapper* e Extensões Dart:** Isolamos toda a lógica de serialização (`toRow`) e desserialização (`establishmentFromRow`) em um arquivo dedicado da camada de dados (`lib/features/favorites/data/favorite_establishment_row.dart`). A entidade `Establishment` (em `domain/`) permanece 100% pura, imutável e livre de qualquer referência a banco de dados.
2. **Mapeamento Seguro e Resiliente de Enums (`TEXT` vs. `.index`):**
   - Na escrita, gravamos sempre o identificador textual legível: `category.name` (`'cafe'`, `'bakery'`).
   - Na leitura, utilizamos um mapa estático $O(1)$ gerado com `EstablishmentCategory.values.asNameMap()`, acompanhado de um valor padrão de contingência (*fallback*): `categories[row['category']] ?? EstablishmentCategory.restaurant`. Se no futuro uma categoria for removida ou renomeada, o app do usuário continua abrindo com elegância em vez de quebrar a tela.
3. **Serialização Determinística de Coleções (`Set<DietaryOption>` ↔ `TEXT`):**
   - Como o SQLite não possui tipo *array* ou *set*, serializamos o conjunto de enums em uma `String` compacta separada por vírgula (`'glutenFree,lactoseFree'`).
   - Na desserialização, usamos os recursos modernos do Dart 3 (*Pattern Matching* com `case final String raw when raw.isNotEmpty`, *collection-for* e o operador *null-aware* em coleções `?options[name]`) para reconstruir o `Set<DietaryOption>` com segurança total contra textos vazios ou opções corrompidas.
4. **Defesa Universal contra Incompatibilidade Numérica no SQLite:**
   - Erradicamos o cast direto `as double`. Em seu lugar, aplicamos a técnica defensiva: `(row['rating'] as num).toDouble()` e `(row['distance_in_km'] as num).toDouble()`. Como `num` é a superclasse abstrata de `int` e `double` no Dart, essa expressão funciona perfeitamente receba ela `5`, `5.0` ou `4.85`.
5. **Persistência Eficiente de Datas (`DateTime` ↔ `INTEGER`):**
   - Convertemos `DateTime` para `INTEGER` usando milissegundos desde a época Unix (`millisecondsSinceEpoch`). Isso permite que o SQLite ordene os favoritos (`ORDER BY saved_at DESC`) usando comparações numéricas ultrarrápidas na CPU, consumindo apenas 8 bytes por registro.

---

### 3. Por que Dominar a Tradução de Tipos Antes da Migração de Esquema (Etapa 5)?
No ciclo de vida de qualquer aplicativo móvel, a evolução da estrutura do banco de dados (**migração de esquema com `onUpgrade`**) é um momento delicado: se o aplicativo tentar migrar o banco mas falhar na conversão dos tipos em memória, os dados do usuário correm risco de corrupção.

Ao isolarmos e dominarmos a **Etapa 4**, garantimos que:
- Nosso código possui conversores à prova de balas para qualquer tipo composto que o aplicativo venha a utilizar.
- Sabemos exatamente como cada tipo de dado se comporta ao transitar entre a memória RAM e as páginas binárias do SQLite.

Com essa base sólida e testada, avançaremos na **Etapa 5** para a evolução do banco de dados (`version: 2`, `onUpgrade`, `ALTER TABLE`) com absoluta confiança de que o mapeador de dados já está pronto para receber novos campos!

---

## Visão Geral do Roteiro de Aula

| Momento | Tempo estimado | O que acontece na aula |
|---|---|---|
| **0. Evolução Arquitetural e Novas Entidades** | 10 min | Apresentamos a árvore de arquivos, criamos os enums `EstablishmentCategory` e `DietaryOption` e enriquecemos a entidade de domínio `Establishment`. |
| **1. O Problema (A Dor Provocada ao Vivo)** | 15 min | Provocamos ao vivo no projetor: o erro silencioso de reordenar um enum salvo com `.index` e o crash fatal de `TypeError: int is not a subtype of double`. |
| **2. O Conceito (Fundamentação Teórica e Técnica)** | 25 min | Fundamentamos as 5 classes de armazenamento do SQLite, afinidade de tipos (*type affinity*), o padrão *Data Mapper*, serialização determinística de coleções e os recursos modernos do Dart 3. |
| **3. A Prática (Implementação Passo a Passo)** | 30 min | Criamos `favorite_establishment_row.dart`, atualizamos o DDL e as operações em `sqlite_favorites_repository.dart` e enriquecemos os cartões visuais com tags alimentares e distância. |
| **4. Verificação, Provocação de Falhas e Ponte com o CeliLac** | 20 min | Validamos a persistência completa com tipos ricos, provocamos falhas controladas para provar a robustez das defesas e mapeamos o código com o projeto **CeliLac**. |

---

## 0. Arquitetura de Pastas e Evolução da Etapa 3 para a Etapa 4

Nesta etapa, nosso modelo de domínio ganha a riqueza necessária para atender a um aplicativo profissional de segurança alimentar.

### 0.1 Fundamentação: O que muda na árvore de arquivos?

1. **Novos Arquivos na Camada de Domínio (`features/establishments/domain/entities/`):**
   - `establishment_category.dart`: enum fortemente tipado com as categorias de estabelecimentos (`restaurant`, `bakery`, `cafe`, `market`) e seus rótulos visuais.
   - `dietary_option.dart`: enum fortemente tipado com as opções de segurança alimentar (`glutenFree`, `lactoseFree`).
2. **Atualizado na Camada de Domínio:**
   - `establishment.dart`: a classe passa a utilizar os enums recém-criados, além de receber `distanceInKm` (`double`), `dietaryOptions` (`Set<DietaryOption>`) e `logoSource` (`String?`).
3. **Novo Arquivo na Camada de Dados (`features/favorites/data/`):**
   - `favorite_establishment_row.dart`: o **Data Mapper** que isola a conversão entre o mundo Dart e as linhas do SQLite (`toRow` e `establishmentFromRow`).
4. **Atualizado na Camada de Dados:**
   - `sqlite_favorites_repository.dart`: atualizamos a instrução `CREATE TABLE` para incluir as novas colunas e delegamos a conversão das linhas inteiramente ao `favorite_establishment_row.dart`.
   - `sample_establishments.dart`: atualizamos o catálogo em memória com as novas categorias, distâncias e conjuntos de opções alimentares.
5. **Atualizado na Camada de Apresentação:**
   - `establishment_card.dart`: passa a exibir os chips das opções alimentares e a distância em km.

### 0.2 Árvore de arquivos ao final desta Etapa 4

```text
lab_favoritos/
├── pubspec.yaml                                                      ← (Intocado - sqflite e path já adicionados)
├── lib/
│   ├── main.dart                                                     ← (Intocado)
│   ├── app/
│   │   ├── lab_app.dart                                              ← (Intocado)
│   │   └── shell/
│   │       └── app_shell.dart                                        ← (Intocado)
│   └── features/
│       ├── establishments/
│       │   ├── domain/
│       │   │   └── entities/
│       │   │       ├── establishment.dart                            ← ATUALIZADO (Tipos ricos: enums, Set, double)
│       │   │       ├── establishment_category.dart                   ← NOVO (Enum de categorias)
│       │   │       └── dietary_option.dart                           ← NOVO (Enum de opções alimentares)
│       │   ├── data/
│       │   │   └── sample_establishments.dart                        ← ATUALIZADO (Dados com tags e distâncias)
│       │   └── presentation/
│       │       ├── pages/
│       │       │   └── establishment_details_page.dart               ← ATUALIZADO (Exibe opções e detalhes ricos)
│       │       └── widgets/
│       │           ├── establishment_card.dart                       ← ATUALIZADO (Chips visuais de restrições)
│       │           └── favorite_button.dart                          ← (Intocado)
│       ├── home/
│       │   └── presentation/
│       │       └── pages/
│       │           └── home_page.dart                                ← (Intocado)
│       └── favorites/
│           ├── domain/
│           │   └── repositories/
│           │       └── favorites_repository.dart                     ← (Intocado)
│           ├── data/
│           │   ├── memory_favorites_repository.dart                  ← (Intocado - compatível com novos tipos)
│           │   ├── sqlite_favorites_repository.dart                  ← ATUALIZADO (Usa mapper e tabela completa)
│           │   └── favorite_establishment_row.dart                   ← NOVO (Data Mapper isolado Dart ↔ SQLite)
│           └── presentation/
│               ├── favorites_controller.dart                         ← (Intocado)
│               └── pages/
│                   └── favorites_page.dart                           ← (Intocado)
```

> [!NOTE]
> Observe novamente o respeito estrito aos princípios da arquitetura:
> `FavoritesController`, `FavoritesRepository`, `AppShell` e a estrutura de injeção no `LabApp` continuam **100% inalterados**. Apenas refinamos os tipos da entidade de domínio e criamos a camada especializada de mapeamento relacional.

---

## 1. O Problema (A Dor Provocada ao Vivo)

Antes de escrever a solução elegante, apresente para a turma os três problemas reais que acontecem quando misturamos objetos ricos de linguagens modernas com bancos relacionais simples.

---

### 1.1 O Abismo entre Sistemas de Tipos: O Objeto Rico vs. As 5 Classes do SQLite

Desenhe no quadro a comparação entre os tipos da nossa entidade `Establishment` em Dart e o que o SQLite é capaz de guardar:

```text
SISTEMA DE TIPOS DO DART                        CLASSES DE ARMAZENAMENTO DO SQLITE
┌──────────────────────────────────────┐        ┌──────────────────────────────────┐
│ id: String                           │───────►│ TEXT                             │
│ name: String                         │───────►│ TEXT                             │
│ category: EstablishmentCategory      │───?───►│ ? (SQLite NÃO possui tipo ENUM)  │
│ neighborhood: String                 │───────►│ TEXT                             │
│ distanceInKm: double                 │───────►│ REAL                             │
│ rating: double                       │───────►│ REAL                             │
│ dietaryOptions: Set<DietaryOption>   │───?───►│ ? (SQLite NÃO possui tipo SET)   │
│ logoSource: String?                  │───────►│ TEXT ou NULL                     │
│ savedAt: DateTime                    │───?───►│ ? (SQLite NÃO possui DATETIME)   │
└──────────────────────────────────────┘        └──────────────────────────────────┘
```

Pergunte para os estudantes:
*"Como guardar um conjunto `Set<DietaryOption>` ou um `enum` em um banco que só entende números, textos e bytes binários?"*

---

### 1.2 A Bomba-Relógio do `.index` em Enums

Muitos tutoriais rápidos na internet ensinam a salvar enums pegando sua posição inteira na declaração:

```dart
// ❌ CÓDIGO PERIGOSO E FRÁGIL:
final map = {
  'category': establishment.category.index, // Salva um número: 0, 1, 2, 3...
};
```

Mostre para os alunos o que acontece na evolução do projeto:
1. No início do ano, o enum foi declarado assim:
   ```dart
   enum EstablishmentCategory {
     restaurant, // index 0
     bakery,     // index 1
     cafe,       // index 2
   }
   ```
   O usuário salvou o "Café Aconchego". No banco SQLite do celular dele, foi gravado o número **`2`**.
2. Três meses depois, a equipe de produto pede para adicionar `"market"` em ordem alfabética ou no topo da lista:
   ```dart
   enum EstablishmentCategory {
     bakery,     // index 0
     cafe,       // index 1 (ERA 2!)
     market,     // index 2 (NOVO!)
     restaurant, // index 3 (ERA 0!)
   }
   ```
3. O app do usuário atualiza pela Play Store/App Store. Ao abrir a lista de favoritos:
   O código lê o valor **`2`** do banco. O `EstablishmentCategory.values[2]` agora aponta para **`market`**!
   **O "Café Aconchego" virou um Mercado da noite para o dia**, sem disparar nenhum erro de compilação ou log de alerta.

> [!WARNING]
> **Regra de Ouro:**
> Nunca persista enums utilizando `.index` em armazenamentos de longa duração (bancos de dados, arquivos locais ou APIs). Sempre persista a representação textual única e explícita (`.name`).

---

### 1.3 O Crash Fatal do `double` no Dart (`TypeError`)

Mostre no código a leitura ingênua que quase todo desenvolvedor iniciante faz:

```dart
// ❌ CRASH EM POTENCIAL:
final rating = row['rating'] as double;
```

Explique o que o SQLite faz nos bastidores:
- No SQLite, os tipos de colunas possuem *Afinidade de Tipos* (*Type Affinity*), e não verificação estrita em tempo de gravação.
- Se você insere o número `4.8`, o SQLite armazena o valor em ponto flutuante IEEE 754 de 8 bytes (`REAL`). O `row['rating'] as double` funciona perfeitamente.
- Mas se você insere uma nota cheia, como `5.0` (ou o usuário salva uma distância exata de `2.0` km), o motor C do SQLite percebe que a parte fracionária é zero e, para economizar espaço em disco, compacta o valor como um número inteiro (`INTEGER`) de 1 ou 2 bytes!
- Quando o driver `sqflite` lê esse registro do disco, ele vê um inteiro e instancia um objeto `int` do Dart (ex.: `5`).
- No Dart, com sistema de tipos forte e são (*Sound Type System*), **`int` não herda de `double`**. Ambas são classes irmãs que herdam da classe abstrata `num`:

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

Ao executar `5 as double`, a máquina virtual do Dart interrompe a execução com:
```text
Unhandled Exception: type 'int' is not a subtype of type 'double' in type cast
```
A tela trava em uma tela vermelha de erro (*Red Screen of Death*) simplesmente porque o estabelecimento recebeu nota máxima 5!

---

### 1.4 A Poluição da Entidade de Domínio (O Antipadrão do `toMap` no Domínio)

Pergunte para a turma:
*"Onde devemos colocar a lógica para converter a entidade em mapa do SQLite? Podemos colocar `Map<String, dynamic> toMap()` dentro de `Establishment`?"*

Mostre por que isso viola os princípios fundamentais da Arquitetura de Software:
1. Uma **Entidade de Domínio** (`lib/features/establishments/domain/entities/establishment.dart`) representa uma regra de negócio que deveria durar anos, independentemente de estarmos usando SQLite, PostgreSQL na nuvem, Firebase, GraphQL ou arquivos JSON locais.
2. Se colocarmos nomes de colunas SQL (`'saved_at'`, `'distance_in_km'`, `millisecondsSinceEpoch`) dentro de `Establishment`, estamos **vazando detalhes de infraestrutura para o coração do sistema**.
3. Se amanhã o CeliLac passar a buscar os dados de uma API REST que usa chaves em formato *camelCase* (`"distanceInKm"`) ou *ISO-8601* para datas, a classe de domínio ficaria poluída com múltiplos métodos misturados: `toSqliteRow()`, `fromSqliteRow()`, `toJson()`, `fromJson()`, `toFirebaseMap()`.

**A Solução de Engenharia:**
Aplicar o padrão **Data Mapper** através de uma **Extensão Dart (`extension`)** e funções de mapeamento isoladas na camada de **Dados (`data/`)**, mantendo o Domínio 100% limpo!

---

## 2. O Conceito (Fundamentação Teórica e Técnica)

Esta seção traz o alicerce teórico de ciência da computação e de recursos avançados do Dart 3 para você fundamentar no quadro antes da codificação.

---

### 2.1 As 5 Classes de Armazenamento do SQLite e a *Afinidade de Tipos*

Diferentemente dos bancos SQL tradicionais de grande porte (como PostgreSQL ou Oracle), onde o tipo de uma coluna é estrito e imutável para qualquer valor inserido, o SQLite adota a **Tipagem Dinâmica Manifesta (*Manifest Typing*)**.

No SQLite, o tipo de dado está associado ao **valor em si**, e não à coluna onde ele reside. Existem apenas 5 classes primitivas de armazenamento:

| Classe de Armazenamento | O que representa | Como mapeia no Dart |
|---|---|---|
| **`NULL`** | Valor nulo / ausência de dado | `null` |
| **`INTEGER`** | Número inteiro com sinal (1, 2, 3, 4, 6 ou 8 bytes) | `int` |
| **`REAL`** | Número de ponto flutuante IEEE 754 de 8 bytes | `double` (ou `int` se a parte fracionária for zero!) |
| **`TEXT`** | Cadeia de caracteres codificada em UTF-8 ou UTF-16 | `String` |
| **`BLOB`** | Bloco binário de dados gravado exatamente como recebido | `Uint8List` |

Cada coluna declarada em uma tabela possui uma **Afinidade de Tipo (*Type Affinity*)**, que serve apenas como uma recomendação de conversão automática. Se você insere um dado em uma coluna `REAL`, mas o valor cabe perfeitamente em um inteiro sem perda de precisão, o SQLite o gravará fisicamente como `INTEGER`.

---

### 2.2 Estratégias de Persistência de `DateTime`: `INTEGER` (Epoch) vs. `TEXT` (ISO-8601)

Existem duas formas comuns de persistir datas e horas no SQLite:

1. **Formato Textual ISO-8601 (`TEXT`):** ex.: `'2026-11-05T18:30:00.000Z'`.
   - *Vantagem:* Legível por humanos ao inspecionar o banco diretamente com `SELECT`.
   - *Desvantagens:* Ocupa entre 24 e 30 bytes por linha. A ordenação exige comparação de strings caractere por caractere e a conversão com `DateTime.parse()` exige processamento pesado de expressões regulares na CPU do celular.
2. **Formato Numérico Unix Epoch em Milissegundos (`INTEGER`):**
   - Obtido em Dart via: `dateTime.millisecondsSinceEpoch`.
   - *Vantagens:*
     - Ocupa apenas **8 bytes** no disco.
     - A cláusula `ORDER BY saved_at DESC` é executada na velocidade máxima da CPU através de uma simples comparação binária de inteiros de 64 bits.
     - A reconstrução em Dart é instantânea e direta: `DateTime.fromMillisecondsSinceEpoch(timestamp)`.

No **CeliLac**, onde a aba de Favoritos precisa listar centenas de itens ordenados cronologicamente com máxima fluidez de rolagem (60/120 fps), a escolha por **`INTEGER` com milissegundos** é a melhor decisão de engenharia.

---

### 2.3 Estratégias de Persistência de `enum`: `.name` e o Poder de `asNameMap()`

Para salvar enums de forma imune a reordenações, utilizamos a propriedade nativa `.name` introduzida no Dart 2.15:

```dart
// Escrita:
'category': establishment.category.name, // Grava: 'restaurant', 'bakery', 'cafe' ou 'market'
```

E para a leitura? A abordagem ingênua seria iterar sobre todos os valores com `.firstWhere(...)`:

```dart
// ⚠️ BUSCA LINEAR O(N) A CADA LINHA:
final category = EstablishmentCategory.values.firstWhere(
  (c) => c.name == row['category'],
  orElse: () => EstablishmentCategory.restaurant,
);
```

No Dart moderno, existe um método estático nativo altamente otimizado: **`EnumByName.asNameMap()`**:

```dart
final categories = EstablishmentCategory.values.asNameMap();
// Gera uma tabela hash em memória:
// {
//   'restaurant': EstablishmentCategory.restaurant,
//   'bakery': EstablishmentCategory.bakery,
//   'cafe': EstablishmentCategory.cafe,
//   'market': EstablishmentCategory.market,
// }
```

**Benefícios técnicos do `asNameMap()`:**
1. **Busca em Tempo Constante $O(1)$:** A conversão `categories[row['category']]` é resolvida instantaneamente por *hashing*.
2. **Tolerância a Nulos e Valores Legados:** Se o valor retornado do banco não existir no mapa (por exemplo, se uma categoria antiga foi descontinuada na versão nova do app), o operador indexador `[]` simplesmente retorna `null`. Podemos então combinar o operador de coalescência nula (`??`) para fornecer uma categoria segura padrão:
   ```dart
   category: categories[row['category']] ?? EstablishmentCategory.restaurant,
   ```
   O aplicativo jamais quebra, garantindo a continuidade da experiência do usuário!

---

### 2.4 Estratégias de Persistência de `Set<DietaryOption>`: Serialização Determinística e Dart 3

Um estabelecimento pode atender a múltiplas opções alimentares:
`{DietaryOption.glutenFree, DietaryOption.lactoseFree}`.

#### 1. Como Serializar para o SQLite (`toRow`):
Como não há tipo *Array* no SQLite, compactamos a coleção em uma única `String` com valores separados por vírgula (`CSV` inline):

```dart
'dietary_options': [
  for (final option in dietaryOptions) option.name,
].join(','),
```
Se o conjunto tiver ambas as opções, o campo grava: `'glutenFree,lactoseFree'`. Se estiver vazio, grava uma string vazia `''`.

#### 2. Como Desserializar com Segurança Máxima no Dart 3 (`fromRow`):
Para ler essa string e transformá-la de volta em `Set<DietaryOption>`, precisamos nos proteger contra:
- Colunas nulas ou vazias.
- Nomes desconhecidos ou inválidos no texto.

Utilizamos a sintaxe expressiva do Dart 3:

```dart
final options = DietaryOption.values.asNameMap();

dietaryOptions: {
  if (row['dietary_options'] case final String raw when raw.isNotEmpty)
    for (final name in raw.split(','))
      ?options[name],
},
```

Analise cada detalhe dessa construção:
- **`case final String raw when raw.isNotEmpty`:** Usa *Pattern Matching* e *Guards* (`when`). Só entra no bloco se o valor for de fato uma `String` não vazia. Se for `null` ou `''`, o conjunto resultante já nasce vazio `{}` sem lançar erro de split.
- **`for (final name in raw.split(','))`:** Percorre cada token separado por vírgula.
- **`?options[name]` (*Null-aware Collection Element*):** Se `name` for válido, `options[name]` retorna a constante do enum correspondente. Se `name` for desconhecido (ex.: `'vegan'` gravado por engano ou vindo de uma base de testes), `options[name]` resulta em `null`. O prefixo `?` diz ao compilador do Dart: *"Se o valor for nulo, ignore e não adicione ao conjunto!"*.

---

### 2.5 A Técnica Universal do `(raw as num).toDouble()`

Para resolver de forma definitiva o problema do SQLite retornar ora `int` ora `double` em colunas numéricas decimais (`REAL`), exploramos a hierarquia de tipos do Dart:

```dart
// ✅ DEFESA UNIVERSAL COMPLETA:
distanceInKm: (row['distance_in_km'] as num).toDouble(),
rating: (row['rating'] as num).toDouble(),
```

**Por que isso nunca quebra?**
1. Tanto a classe `int` quanto a classe `double` estendem a classe abstrata `num`.
2. Portanto, qualquer número retornado pelo SQLite satisfaz a asserção `as num`.
3. A classe `num` declara o método abstrato `double toDouble()`.
   - Se o objeto em tempo de execução for um `int` (`5`), o método `5.toDouble()` retorna `5.0`.
   - Se o objeto já for um `double` (`4.8`), o método `4.8.toDouble()` retorna `4.8` diretamente.

Essa única linha de código elimina uma das fontes mais comuns de erros em produção em aplicativos Flutter com SQLite.

---

### 2.6 O Padrão de Arquitetura *Data Mapper* com Dart `extension`

Para garantir que a camada de domínio permaneça pura, implementamos o padrão **Data Mapper** (Fowler, *Patterns of Enterprise Application Architecture*).

No Dart, podemos criar mappers sem precisar instanciar classes pesadas de serviço, utilizando **Extensões de Tipo (`extension`)**:

```dart
// Em lib/features/favorites/data/favorite_establishment_row.dart:
extension FavoriteEstablishmentRow on Establishment {
  Map<String, Object?> toRow({required DateTime savedAt}) => {
    'id': id,
    'name': name,
    'category': category.name,
    'neighborhood': neighborhood,
    'distance_in_km': distanceInKm,
    'rating': rating,
    'dietary_options': [
      for (final option in dietaryOptions) option.name,
    ].join(','),
    'logo_source': logoSource,
    'saved_at': savedAt.millisecondsSinceEpoch,
  };
}
```

E a função pura top-level de conversão reversa:

```dart
Establishment establishmentFromRow(Map<String, Object?> row) {
  // Converte a linha do banco de volta em Establishment
}
```

**Por que essa arquitetura é superior?**
- Quem estiver na camada de domínio só enxerga `Establishment`.
- Quem estiver na camada de dados (`SqliteFavoritesRepository`) faz o `import 'favorite_establishment_row.dart'` e ganha o método `.toRow()` como se fosse nativo da classe, além da função `establishmentFromRow(row)`.
- Se amanhã criarmos um repositório HTTP (`HttpFavoritesRepository`), criaremos outro arquivo isolado (`favorite_establishment_dto.dart`) com `toJson()` e `fromJson()`, sem tocar em nenhuma linha das entidades existentes!

---

## 3. A Prática (Implementação Passo a Passo)

Vamos agora implementar as alterações cirúrgicas no projeto-laboratório. Siga a ordem dos arquivos abaixo.

---

### 3.1 Criando os Enums de Domínio

#### Arquivo 1: `lib/features/establishments/domain/entities/establishment_category.dart`

**O que este arquivo propõe e resolve:**
Define o conjunto fechado e fortemente tipado de categorias válidas de estabelecimentos aceitas pela regra de negócio, associando cada categoria ao seu respectivo rótulo de exibição textual para a interface.

**Papel Arquitetural (`domain/entities`):**
Pertence à camada de **Domínio**. É um tipo puro de negócio que não depende de nenhum pacote externo nem de Flutter.

**Fundamentação dos recursos utilizados no código:**
- **Enum aprimorado (*Enhanced Enum* do Dart):** O enum possui um construtor constante `const EstablishmentCategory(this.label)` e um atributo `final String label`. Isso permite associar o nome de negócio legível à constante de código de forma encapsulada.

Crie o arquivo:

```dart
/// Categorias de estabelecimentos seguras para o catálogo do app.
enum EstablishmentCategory {
  restaurant('Restaurante'),
  bakery('Padaria'),
  cafe('Café'),
  market('Mercado');

  const EstablishmentCategory(this.label);

  final String label;
}
```

---

#### Arquivo 2: `lib/features/establishments/domain/entities/dietary_option.dart`

**O que este arquivo propõe e resolve:**
Define os selos ou opções de conformidade alimentar e controle de contaminação cruzada atendidos por um estabelecimento (sem glúten e sem lactose).

**Papel Arquitetural (`domain/entities`):**
Entidade de valor do **Domínio**.

Crie o arquivo:

```dart
/// Opções de segurança alimentar oferecidas por estabelecimentos cadastrados.
enum DietaryOption {
  glutenFree('Sem glúten'),
  lactoseFree('Sem lactose');

  const DietaryOption(this.label);

  final String label;
}
```

---

### 3.2 Atualizando a Entidade de Domínio `Establishment`

#### Arquivo 3: `lib/features/establishments/domain/entities/establishment.dart`

**O que este arquivo propõe e resolve:**
Atualiza o modelo de domínio para incorporar os novos enums tipados, a distância em km (`distanceInKm`), o conjunto de restrições atendidas (`dietaryOptions`) e o logotipo opcional (`logoSource`).

**Papel Arquitetural (`domain/entities`):**
Continua sendo a entidade central e imutável do sistema. Repare que ela **não possui métodos de banco de dados** (`toRow`/`fromRow`). Ela permanece pura.

Substitua o conteúdo de `lib/features/establishments/domain/entities/establishment.dart`:

```dart
import 'dietary_option.dart';
import 'establishment_category.dart';

/// Entidade de domínio central que representa um estabelecimento no sistema.
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

---

### 3.3 Criando o Data Mapper Especializado

#### Arquivo 4: `lib/features/favorites/data/favorite_establishment_row.dart`

**O que este arquivo propõe e resolve:**
Propõe a camada de conversão e tradução de tipos entre o modelo de domínio rico `Establishment` e as linhas relacionais primitivas do SQLite (`Map<String, Object?>`). Resolve todas as armadilhas de serialização de enums com `.name`, desempacotamento de conjuntos com `join(',')` e `asNameMap()`, e proteção contra crash numérico com `(raw as num).toDouble()`.

**Papel Arquitetural (`features/favorites/data`):**
Fica na camada de **Dados (`data`)**. Ele é o tradutor oficial do SQLite para a funcionalidade de favoritos.

**Fundamentação dos recursos utilizados no código:**
- **`extension FavoriteEstablishmentRow on Establishment`:** Permite que qualquer código na camada de dados invoque `establishment.toRow(savedAt: ...)` com sintaxe limpa e elegante, sem poluir a classe original de domínio.
- **`EstablishmentCategory.values.asNameMap()` e `DietaryOption.values.asNameMap()`:** Mapeamentos em memória com busca em $O(1)$.
- **`switch (row['logo_source'])`:** Sintaxe moderna de *pattern matching* do Dart para normalizar strings nulas ou compostas apenas por espaços em branco para `null`.
- **`?options[name]`:** Null-aware collection element que descarta silenciosamente opções desconhecidas sem lançar exceções.

Crie o arquivo `lib/features/favorites/data/favorite_establishment_row.dart`:

```dart
import '../../establishments/domain/entities/dietary_option.dart';
import '../../establishments/domain/entities/establishment.dart';
import '../../establishments/domain/entities/establishment_category.dart';

/// Extensão de dados que serializa uma entidade [Establishment] em uma linha SQL.
extension FavoriteEstablishmentRow on Establishment {
  Map<String, Object?> toRow({required DateTime savedAt}) => {
    'id': id,
    'name': name,
    'category': category.name,
    'neighborhood': neighborhood,
    'distance_in_km': distanceInKm,
    'rating': rating,
    'dietary_options': [
      for (final option in dietaryOptions) option.name,
    ].join(','),
    'logo_source': logoSource,
    'saved_at': savedAt.millisecondsSinceEpoch,
  };
}

/// Reconstrói uma entidade [Establishment] a partir de uma linha retornada pelo SQLite.
Establishment establishmentFromRow(Map<String, Object?> row) {
  final categories = EstablishmentCategory.values.asNameMap();
  final options = DietaryOption.values.asNameMap();

  return Establishment(
    id: row['id'] as String,
    name: row['name'] as String,
    category: categories[row['category']] ?? EstablishmentCategory.restaurant,
    neighborhood: row['neighborhood'] as String,
    // Defesa essencial contra a afinidade de tipos do SQLite:
    // Um número REAL sem casas decimais (ex.: 5.0 ou 2.0) pode voltar como int do banco.
    distanceInKm: (row['distance_in_km'] as num).toDouble(),
    rating: (row['rating'] as num).toDouble(),
    dietaryOptions: {
      if (row['dietary_options'] case final String raw when raw.isNotEmpty)
        for (final name in raw.split(',')) ?options[name],
    },
    logoSource: switch (row['logo_source']) {
      final String source when source.trim().isNotEmpty => source,
      _ => null,
    },
  );
}
```

---

### 3.4 Atualizando o Repositório SQLite para Usar o Data Mapper

#### Arquivo 5: `lib/features/favorites/data/sqlite_favorites_repository.dart`

**O que este arquivo propõe e resolve:**
Atualiza o repositório SQLite para:
1. Definir o DDL da tabela com a estrutura de colunas completa (`distance_in_km`, `dietary_options`, `logo_source`).
2. Eliminar métodos privados rudimentares de conversão e passar a utilizar o mapper `favorite_establishment_row.dart`.

Substitua o conteúdo de `lib/features/favorites/data/sqlite_favorites_repository.dart`:

```dart
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../establishments/domain/entities/establishment.dart';
import '../domain/repositories/favorites_repository.dart';
import 'favorite_establishment_row.dart';

/// Implementação de [FavoritesRepository] que persiste favoritos no SQLite com tipos ricos.
class SqliteFavoritesRepository implements FavoritesRepository {
  SqliteFavoritesRepository({Future<Database> Function()? openDatabase})
      : _openDatabase = openDatabase ?? _openDefaultDatabase;

  static const String tableName = 'favorites';
  static const String databaseFileName = 'lab_favorites.db';
  static const int schemaVersion = 1;

  final Future<Database> Function() _openDatabase;
  Future<Database>? _database;

  Future<Database> get _db => _database ??= _openDatabase();

  static Future<Database> _openDefaultDatabase() async {
    final directory = await getDatabasesPath();
    final path = p.join(directory, databaseFileName);

    return openDatabase(
      path,
      version: schemaVersion,
      onCreate: createSchema,
    );
  }

  /// Criação da tabela com suporte aos tipos ricos serializados.
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

  @override
  Future<List<Establishment>> loadAll() async {
    final db = await _db;
    final rows = await db.query(tableName, orderBy: 'saved_at DESC');

    return [
      for (final row in rows) establishmentFromRow(row),
    ];
  }

  @override
  Future<bool> isFavorite(String establishmentId) async {
    final db = await _db;
    final rows = await db.query(
      tableName,
      columns: ['id'],
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

  Future<void> close() async {
    final db = _database;
    _database = null;
    if (db != null) {
      await (await db).close();
    }
  }
}
```

---

### 3.5 Atualizando os Dados de Exemplo e a Apresentação

#### Arquivo 6: `lib/features/establishments/data/sample_establishments.dart`

Substitua o conteúdo de `lib/features/establishments/data/sample_establishments.dart`:

```dart
import '../domain/entities/dietary_option.dart';
import '../domain/entities/establishment.dart';
import '../domain/entities/establishment_category.dart';

const sampleEstablishments = <Establishment>[
  Establishment(
    id: '1',
    name: 'Café Aconchego',
    category: EstablishmentCategory.cafe,
    neighborhood: 'Centro',
    distanceInKm: 1.2,
    rating: 5.0, // Nota cheia proposital para testar a defesa do double!
    dietaryOptions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
  ),
  Establishment(
    id: '2',
    name: 'Padaria Trigo Zero',
    category: EstablishmentCategory.bakery,
    neighborhood: 'Jardim América',
    distanceInKm: 3.5,
    rating: 4.9,
    dietaryOptions: {DietaryOption.glutenFree},
  ),
  Establishment(
    id: '3',
    name: 'Bistrô Sem Traço',
    category: EstablishmentCategory.restaurant,
    neighborhood: 'Bela Vista',
    distanceInKm: 0.8,
    rating: 4.7,
    dietaryOptions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
  ),
  Establishment(
    id: '4',
    name: 'Mercado Naturalis',
    category: EstablishmentCategory.market,
    neighborhood: 'Vila Nova',
    distanceInKm: 2.0, // Distância cheia proposital para testar a defesa do double!
    rating: 4.6,
    dietaryOptions: {DietaryOption.lactoseFree},
  ),
];
```

---

#### Arquivo 7: `lib/features/establishments/presentation/widgets/establishment_card.dart`

Atualize o cartão para exibir visualmente a categoria formatada, a distância em km e pequenos chips para as opções alimentares atendidas:

```dart
import 'package:flutter/material.dart';

import '../../domain/entities/establishment.dart';
import '../pages/establishment_details_page.dart';
import 'favorite_button.dart';

class EstablishmentCard extends StatelessWidget {
  const EstablishmentCard({
    super.key,
    required this.establishment,
  });

  final Establishment establishment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EstablishmentDetailsPage(establishment: establishment),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          establishment.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${establishment.category.label} · ${establishment.neighborhood} · ${establishment.distanceInKm.toStringAsFixed(1)} km',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 20, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text(
                        establishment.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      FavoriteButton(establishment: establishment),
                    ],
                  ),
                ],
              ),
              if (establishment.dietaryOptions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final option in establishment.dietaryOptions)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

---

#### Arquivo 8: `lib/features/establishments/presentation/pages/establishment_details_page.dart`

Atualize a tela de detalhes para exibir a lista completa de tags e informações ricas:

```dart
import 'package:flutter/material.dart';

import '../../domain/entities/establishment.dart';
import '../widgets/favorite_button.dart';

class EstablishmentDetailsPage extends StatelessWidget {
  const EstablishmentDetailsPage({
    super.key,
    required this.establishment,
  });

  final Establishment establishment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(establishment.name),
        actions: [
          FavoriteButton(establishment: establishment),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              establishment.name,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${establishment.category.label} · ${establishment.neighborhood}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(height: 4),
                        Text(
                          '${establishment.rating.toStringAsFixed(1)} / 5.0',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text('Avaliação', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Column(
                      children: [
                        const Icon(Icons.directions_walk, color: Colors.blue),
                        const SizedBox(height: 4),
                        Text(
                          '${establishment.distanceInKm.toStringAsFixed(1)} km',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text('Distância', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Segurança Alimentar',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in establishment.dietaryOptions)
                  Chip(
                    avatar: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(option.label),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 4. Verificação, Provocação de Falhas e Ponte com o CeliLac

Chegou o momento de comprovar a resiliência das conversões de tipos na prática e provocar erros didáticos ao vivo com a turma.

> [!IMPORTANT]
> **Atenção:** Como alteramos o comando `CREATE TABLE` para incluir novas colunas na versão 1 do esquema, se você já tinha o arquivo `lab_favorites.db` criado no celular/emulador da aula anterior, o SQLite **não executará** o `onCreate` novamente.
> **Para esta aula:** desinstale o app do emulador/aparelho (`adb uninstall com.example.lab_favoritos`) ou limpe os dados do aplicativo para que o banco seja criado com a nova estrutura. (Na **Etapa 5**, aprenderemos a resolver exatamente isso sem desinstalar o app através de `onUpgrade`!).

---

### 4.1 Roteiro de Verificação ao Vivo da Persistência de Tipos Ricos

Execute o aplicativo com `flutter run`:

1. **Passo 1 (Favoritar estabelecimentos com tipos diversos):**
   - Na lista, note que o **Café Aconchego** possui nota `5.0` (número inteiro no SQLite) e duas tags: *Sem glúten* e *Sem lactose*. Toque no coração.
   - Toque no coração do **Mercado Naturalis** (distância `2.0` km, nota `4.6`, apenas *Sem lactose*).
2. **Passo 2 (Verificação na Aba de Favoritos):**
   - Acesse a aba **Favoritos**.
   - Note que ambos os itens aparecem perfeitamente renderizados com suas respectivas categorias em texto (`Café`, `Mercado`), suas distâncias formatadas e seus chips de opções alimentares!
3. **Passo 3 (Fechamento e Reabertura do App):**
   - Encerre o aplicativo completamente no terminal (`q`).
   - Execute novamente `flutter run`.
   - Ao abrir a aba Favoritos: **todos os dados ricos foram reconstituídos com integridade absoluta a partir do SQLite!**

---

### 4.2 Experimento de Falha Controlada 1: Provocando o Crash do `double`

Para que os estudantes nunca mais esqueçam a importância da defesa `(raw as num).toDouble()`, faça a seguinte alteração temporária em `favorite_establishment_row.dart`:

```dart
// ❌ EXPERIMENTO DE FALHA: troque a defesa por um cast ingênuo:
rating: row['rating'] as double,
```

1. Reinicie o aplicativo.
2. Como o **Café Aconchego** possui nota `5.0`, o SQLite salvou o valor fisicamente como o inteiro `5`.
3. Ao tentar ler a lista de favoritos, a tela explode no emulador com a mensagem:
   ```text
   ════════ Exception caught by widgets library ═══════════════════════════════════
   type 'int' is not a subtype of type 'double' in type cast
   favorite_establishment_row.dart:36
   ════════════════════════════════════════════════════════════════════════════════
   ```
4. Mostre aos estudantes que a nota `4.9` da Padaria Trigo Zero funcionaria, mas a nota `5.0` derrubou o aplicativo.
5. Reverta a alteração para a defesa oficial: `(row['rating'] as num).toDouble()` e veja o erro desaparecer instantaneamente.

---

### 4.3 Experimento de Falha Controlada 2: Provocando Valores Desconhecidos no Enum

Mostre como o sistema se comporta caso uma categoria desconhecida ou corrompida surja no banco de dados.

Abra o terminal do emulador via `adb shell`:

```bash
adb shell
cd /data/data/com.example.lab_favoritos/databases/
sqlite3 lab_favorites.db
```

Insira manualmente um registro com uma categoria que não existe no nosso enum do Dart (ex.: `'pharmacy'`):

```sql
INSERT INTO favorites (id, name, category, neighborhood, distance_in_km, rating, dietary_options, saved_at)
VALUES ('99', 'Farmácia Viva Bem', 'pharmacy', 'Centro', 0.5, 4.5, 'glutenFree,vegan', 9999999999999);
.exit
```

Abra a aba Favoritos no aplicativo e faça um *Hot Restart* (`R`):
- O aplicativo **não quebrou**!
- A Farmácia Viva Bem foi renderizada com sucesso:
  - Sua categoria desconhecida (`pharmacy`) sofreu *fallback* seguro para `EstablishmentCategory.restaurant` graças ao operador `categories[row['category']] ?? EstablishmentCategory.restaurant`.
  - Sua opção desconhecida (`vegan`) foi ignorada silenciosamente graças ao null-aware `?options[name]`, mantendo apenas o selo reconhecido (*Sem glúten*).

---

### 4.4 Ponte Direta com o CeliLac

Veja a correspondência exata entre o que construímos no laboratório e os arquivos em produção no **CeliLac**:

| Artefato no `lab_favoritos` (Etapa 4) | Artefato correspondente no **CeliLac** | Papel na Engenharia do CeliLac |
|---|---|---|
| `lib/features/favorites/data/favorite_establishment_row.dart` | [`lib/features/favorites/data/favorite_establishment_row.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/favorites/data/favorite_establishment_row.dart) | Data Mapper central: extensão `toRow` e função pura `establishmentFromRow`. |
| `EstablishmentCategory` | [`lib/features/establishments/domain/entities/establishment_category.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/establishments/domain/entities/establishment_category.dart) | Enum fortemente tipado com rótulos de apresentação (`label`). |
| `DietaryOption` | [`lib/features/establishments/domain/entities/dietary_option.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/establishments/domain/entities/dietary_option.dart) | Enum das restrições alimentares com serialização em CSV compacta. |
| `Establishment` enriquecido | [`lib/features/establishments/domain/entities/establishment.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/establishments/domain/entities/establishment.dart) | Entidade de domínio pura, sem acoplamento com SQLite ou serializadores de banco. |
| `SqliteFavoritesRepository` | [`lib/features/favorites/data/sqlite_favorites_repository.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/favorites/data/sqlite_favorites_repository.dart) | Repositório que delega mapeamento relacional exclusivamente ao `favorite_establishment_row.dart`. |

---

### 4.5 Gancho para a Etapa 5: Evolução do Banco e Migração de Esquema (`version` e `onUpgrade`)

Encerre a aula com a provocação que abre as portas para a **Etapa 5**:

*"Hoje percebemos que, ao alterar o `CREATE TABLE` para adicionar novas colunas (`distance_in_km`, `dietary_options`), fomos obrigados a apagar o banco ou desinstalar o app para que a tabela fosse recriada.*
*Mas em produção, você **nunca** pode pedir para 100.000 usuários desinstalarem o aplicativo e perderem seus favoritos salvos!*
*O que acontece quando o seu app já está na loja com a versão 1 do banco e na versão 2 surge uma nova coluna, como o `logo_source`?*
*Por que o SQLite simplesmente ignora o `CREATE TABLE` em celulares que já possuem o banco criado?*
*E como escrever migrações incrementais com `ALTER TABLE` e `onUpgrade` sem perder um único dado do usuário?"*

Na **Etapa 5**, responderemos a essas perguntas dominando o ciclo de vida de versões do SQLite com `version: 2` e `onUpgrade`!

