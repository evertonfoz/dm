# Etapa 3 — Persistência Relacional com SQLite (`sqflite`), Tabela v1 e CRUD Seguro

## Introdução: O que este documento propõe e resolve?

### 1. O Problema Real que Estamos Enfrentando
Ao final da **Etapa 2**, estruturamos uma arquitetura robusta e desacoplada:
- A camada de **Domínio (`domain`)** estabeleceu o contrato abstrato `FavoritesRepository`.
- A camada de **Apresentação (`presentation`)** foi adaptada para um fluxo assíncrono (`Future`), exibindo feedback de carregamento (`isLoaded` com `CircularProgressIndicator`), garantindo que o estado visual só seja atualizado após a confirmação da gravação e tratando falhas com `try / catch` e `SnackBar`.
- O aplicativo já estava protegido contra falhas graças aos testes com o `MemoryFavoritesRepository`.

No entanto, o aplicativo ainda utiliza um repositório baseado exclusivamente em **memória volátil (RAM)**. Ao fechar o app, reiniciar o smartphone ou disparar um *Hot Restart*, todos os favoritos salvos pelo usuário continuam desaparecendo.

A primeira alternativa que muitos desenvolvedores cogitam para resolver a persistência no Flutter é recorrer ao pacote `shared_preferences`. Porém, tentar gerenciar uma coleção dinâmica de entidades com `shared_preferences` impõe graves gargalos de Engenharia de Software:
1. **Sobrecarga de I/O e Custo Computacional Desnecessário:** `shared_preferences` grava dados no formato chave-valor (`XML` no Android, `plist` no iOS). Para salvar uma lista de favoritos, é necessário serializar a lista inteira em uma única `String` JSON. Se o usuário tiver 50 lugares salvos e tocar no coração para adicionar mais um, o aplicativo é obrigado a decodificar o arquivo inteiro, desserializar 50 objetos, adicionar o 51º elemento, serializar os 51 objetos novamente e regravar o arquivo monobloco no disco do celular.
2. **Ausência de Mecanismo de Consulta e Ordenação:** Não é possível pedir ao `shared_preferences` que traga *"apenas os favoritos da categoria Restaurante"* ou *"ordene os itens do mais recente para o mais antigo"*. Toda a carga de filtragem e ordenação precisa ser feita na CPU do aplicativo após carregar tudo na memória.
3. **Risco de Corrupção em Falhas Concorrentes:** Se o aplicativo for finalizado pelo sistema operacional exatamente no instante em que o arquivo de preferências estiver sendo regravado por inteiro, todos os favoritos salvos podem ser corrompidos simultaneamente.

Além disso, ao migrar para um banco de dados relacional embutido (**SQLite**), surge outro risco crítico: **a segurança e a robustez contra erros de sintaxe SQL**. Desenvolvedores novatos frequentemente montam consultas concatenando texto (`'DELETE FROM favorites WHERE id = ' + id`). Fazer isso abre as portas para falhas grotescas ao encontrar nomes de estabelecimentos com apóstrofo (como `"D'Angelo Bistrô"`) e expõe o aplicativo a ataques de **Injeção de SQL (*SQL Injection*)**.

---

### 2. O que esta Etapa 3 Propõe e Resolve
Este documento propõe a implementação da persistência definitiva no disco utilizando o motor relacional **SQLite** através do pacote oficial **`sqflite`**, resolvendo quatro desafios fundamentais de engenharia e segurança:

1. **Persistência Relacional Granular e Eficiente:** Gravamos, consultamos e removemos cada estabelecimento como uma **linha isolada (*row*)** em uma tabela relacional, delegando a ordenação cronológica decrescente (`ORDER BY saved_at DESC`) diretamente ao motor altamente otimizado do SQLite em C.
2. **Gerenciamento do Ciclo de Vida da Conexão com Inicialização Preguiçosa (*Lazy Initialization*):** Implementamos a abertura única e reaproveitada da conexão com o arquivo `.db` através do operador `??=` (`Future<Database> get _db => _database ??= _openDatabase();`), encapsulando a descoberta do diretório do sistema operacional com `getDatabasesPath()` e `path.join()`.
3. **Modelagem Relacional de Domínio e *Snapshot* Offline:** Em vez de guardar apenas o `id` do estabelecimento (o que obrigaria o app a fazer requisições de rede para carregar o cartão quando o usuário estivesse sem internet), gravamos um **instantâneo (*snapshot*)** dos dados visuais do estabelecimento na tabela `favorites` (`id`, `name`, `category`, `neighborhood`, `rating`, `saved_at`), garantindo funcionamento **100% offline**.
4. **CRUD Seguro e Imunidade a *SQL Injection*:**
   - Inserção com **`ConflictAlgorithm.replace`**, garantindo idempotência e evitando que toques repetidos causem exceção de chave primária duplicada.
   - Verificação e deleção utilizando **parâmetros posicionais (`where: 'id = ?'` e `whereArgs: [id]`)**, eliminando de forma definitiva qualquer brecha de *SQL Injection* ou quebra de sintaxe com apóstrofos/aspas.
5. **O Triunfo da Inversão de Dependência:** Como preparamos o contrato `FavoritesRepository` e o fluxo assíncrono na Etapa 2, criaremos a classe `SqliteFavoritesRepository` e a plugaremos no `LabApp` sem alterar **nenhuma linha** do `FavoritesController`, da `HomePage`, da `FavoritesPage` ou da `EstablishmentDetailsPage`!

---

### 3. Por que Focar no CRUD e Segurança Básica Antes de Tipos Complexos (Etapa 4) e Migração (Etapa 5)?
No aplicativo real do **CeliLac**, a entidade `Establishment` possui campos ricos e complexos: `enum EstablishmentCategory`, conjuntos de restrições alimentares `Set<DietaryOption>`, notas em ponto flutuante `double` e logotipo opcional `logoSource`. Além disso, o aplicativo precisa evoluir de versão no celular dos usuários através do método `onUpgrade` da versão 1 para a versão 2.

Se tentássemos ensinar simultaneamente:
- O que é o arquivo SQLite e como abrir a conexão;
- Como escrever `CREATE TABLE`, `INSERT`, `QUERY` e `DELETE`;
- Como prevenir *SQL Injection* com `whereArgs`;
- Como serializar `Set<Enum>` com `.join(',')` e mapear `double` com `(row['x'] as num).toDouble()`;
- E como migrar colunas com `onUpgrade` sem perder dados;

A carga cognitiva seria excessiva e o estudante se perderia entre sintaxe SQL, regras de conversão do Dart e migração de schema.

Por isso, nesta **Etapa 3**, trabalhamos com o modelo relacional na **Versão 1 do esquema**, focando com precisão cirúrgica na conexão, na tabela relacional, nas operações CRUD e na segurança com `whereArgs`. Uma vez consolidado esse fundamento, a **Etapa 4** cuidará das traduções avançadas de tipos compostos e a **Etapa 5** abordará a migração de versões com `onUpgrade`.

---

## Visão Geral do Roteiro de Aula

| Momento | Tempo estimado | O que acontece na aula |
|---|---|---|
| **0. Dependências e Evolução Arquitetural** | 10 min | Adicionamos `sqflite` e `path` no `pubspec.yaml` e mostramos a árvore de arquivos, evidenciando que apenas a camada `data` receberá um novo arquivo. |
| **1. O Problema (A Dor ao Vivo)** | 10 min | Comparamos no quadro a perda de eficiência do `SharedPreferences` para listas e demonstramos o perigo de quebra e *SQL Injection* ao usar interpolação de strings no SQL. |
| **2. O Conceito (Fundamentação Teórica e Técnica)** | 25 min | Fundamentamos a escolha do SQLite, a arquitetura do motor em C, o ciclo de vida da conexão, a abertura preguiçosa (`??=`), o DDL da tabela `v1`, o `ConflictAlgorithm.replace` e a prevenção de injeção com `whereArgs`. |
| **3. A Prática (Implementação Passo a Passo)** | 25 min | Criamos o arquivo `sqlite_favorites_repository.dart` implementando o contrato `FavoritesRepository` e substituímos o repositório em memória no `lab_app.dart`. |
| **4. Verificação, Inspeção do Banco e Ponte com o CeliLac** | 20 min | Validamos a persistência real fechando o app, inspecionamos o arquivo `.db` real no dispositivo/emulador e mapeamos o código com o projeto **CeliLac**. |

---

## 0. Arquitetura de Pastas e Evolução da Etapa 2 para a Etapa 3

Na **Etapa 2**, deixamos o contrato `FavoritesRepository` definido na camada de domínio e o `FavoritesController` pronto para receber qualquer implementação assíncrona.

Agora, na **Etapa 3**, adicionamos a implementação real de banco de dados na camada **`data/`**, sem tocar em nada que já foi construído nas outras camadas.

### 0.1 Fundamentação: O que muda na árvore de arquivos?

1. **Intocados da Etapa 2 (100% preservados):**
   - `main.dart`
   - `app_shell.dart`
   - `establishment.dart`
   - `sample_establishments.dart`
   - `establishment_card.dart`
   - `favorite_button.dart`
   - `home_page.dart`
   - `establishment_details_page.dart`
   - `favorites_page.dart`
   - `favorites_repository.dart`
   - `favorites_controller.dart`
   - `memory_favorites_repository.dart` (continua existindo para nossos testes unitários e de widget!).
2. **Novo na Etapa 3:**
   - `lib/features/favorites/data/sqlite_favorites_repository.dart`: implementação concreta de `FavoritesRepository` que gerencia a tabela `favorites` no SQLite.
3. **Atualizado na Etapa 3:**
   - `pubspec.yaml`: adição dos pacotes `sqflite` e `path`.
   - `lib/app/lab_app.dart`: substituição do `MemoryFavoritesRepository()` padrão por `SqliteFavoritesRepository()`.

### 0.2 Árvore de arquivos ao final desta Etapa 3

```text
lab_favoritos/
├── pubspec.yaml                                                      ← ATUALIZADO (sqflite e path)
├── lib/
│   ├── main.dart                                                     ← (Intocado)
│   ├── app/
│   │   ├── lab_app.dart                                              ← ATUALIZADO (Injeta SqliteFavoritesRepository)
│   │   └── shell/
│   │       └── app_shell.dart                                        ← (Intocado)
│   └── features/
│       ├── establishments/
│       │   ├── domain/
│       │   │   └── entities/
│       │   │       └── establishment.dart                            ← (Intocado)
│       │   ├── data/
│       │   │   └── sample_establishments.dart                        ← (Intocado)
│       │   └── presentation/
│       │       ├── pages/
│       │       │   └── establishment_details_page.dart               ← (Intocado)
│       │       └── widgets/
│       │           ├── establishment_card.dart                       ← (Intocado)
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
│           │   ├── memory_favorites_repository.dart                  ← (Intocado - preservado para testes)
│           │   └── sqlite_favorites_repository.dart                  ← NOVO (Persistência real no SQLite)
│           └── presentation/
│               ├── favorites_controller.dart                         ← (Intocado)
│               └── pages/
│                   └── favorites_page.dart                           ← (Intocado)
```

> [!IMPORTANT]
> **Observe a força do Princípio da Inversão de Dependência (DIP):**
> O `FavoritesController` e toda a camada de interface gráfica (`presentation/`) continuam rigorosamente idênticos. Eles não sabem — e não precisam saber — se os dados vêm de uma lista em memória, de um arquivo SQLite local ou de um servidor na nuvem.

---

## 1. O Problema (A Dor Provocada ao Vivo)

Antes de escrever qualquer linha de SQL, conduza com os estudantes uma discussão pedagógica comparando duas alternativas frequentemente mal compreendidas: usar `SharedPreferences` versus usar um banco relacional como o `SQLite`.

### 1.1 A Armadilha de Usar `SharedPreferences` para Coleções

Desenhe no quadro o que acontece no hardware do celular se tentarmos salvar favoritos com `SharedPreferences`:

```text
CENÁRIO: Salvar o 20º favorito do usuário usando SharedPreferences
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. Ler uma String gigante com 19 JSONs do disco                             │
│ 2. Fazer jsonDecode() criando 19 Maps na memória RAM                        │
│ 3. Converter Maps em instâncias de objetos                                  │
│ 4. Adicionar o 20º objeto                                                   │
│ 5. Fazer jsonEncode() da lista completa gerando nova String gigante         │
│ 6. Reescrever o arquivo XML / plist INTEIRO no disco de armazenamento flash │
└─────────────────────────────────────────────────────────────────────────────┘
```

**As três dores técnicas desse modelo:**
1. **Desperdício de Ciclos de CPU e I/O de Disco:** O esforço computacional cresce linearmente com a quantidade de dados. Em dispositivos de baixo custo, isso pode causar pequenos travamentos (*jank*) na interface.
2. **Falta de Recursos do Motor de Banco:** Se precisarmos dos dados ordenados por data de salvamento ou filtrados por categoria, temos que trazer tudo para a memória e processar manualmente via código Dart.
3. **Impossibilidade de Consultas Pontuais:** Para responder a uma simples pergunta — *"O estabelecimento com id '3' é favorito?"* — o app precisa carregar e decodificar a coleção inteira.

### 1.2 O Perigo da Concatenação de SQL e *SQL Injection*

Apresente no projetor a seguinte linha de código, muito comum em projetos de alunos:

```dart
// ❌ CÓDIGO INSEGURO E FRÁGIL:
await db.rawDelete("DELETE FROM favorites WHERE id = '$establishmentId'");
```

Pergunte para a turma:
*"O que acontece se o id for uma string comum contendo um apóstrofo ou se o usuário buscar por um nome com aspas simples, como `D'Angelo`?"*

A consulta executada pelo motor será:
```sql
DELETE FROM favorites WHERE id = 'D'Angelo'
```
O SQLite interpretará o apóstrofo em `D'` como o fechamento do literal de texto. O restante (`Angelo'`) será interpretado como comando SQL inválido, gerando um erro de execução (*syntax error*) e quebrando a tela com uma `DatabaseException`!

Pior ainda: se o parâmetro viesse de um campo de busca ou entrada do usuário contendo `' OR '1'='1`, o comando se tornaria:
```sql
DELETE FROM favorites WHERE id = '' OR '1'='1'
```
O SQLite avaliaria `'1'='1'` como verdadeiro para todas as linhas e **apagaria toda a tabela de favoritos do usuário**!

Isso demonstra por que o uso de **parâmetros posicionais (`?`) com `whereArgs`** não é mero preciosismo: é uma exigência essencial de robustez e segurança de software.

---

## 2. O Conceito (Fundamentação Teórica e Técnica)

Esta seção traz a fundamentação teórica que justifica cada decisão técnica adotada na implementação do `SqliteFavoritesRepository`.

---

### 2.1 Comparativo Arquitetural: Onde Persistir os Dados?

Para que o estudante saiba tomar decisões maduras de arquitetura no futuro, apresente a matriz de decisão entre as opções de persistência mais comuns no ecossistema mobile:

| Mecanismo de Persistência | Formato / Tecnologia | Quando Usar | Quando NÃO Usar |
|---|---|---|---|
| **`SharedPreferences`** | Chave-Valor (`XML` no Android, `plist` no iOS) | Preferências simples de usuário (tema escuro/claro, id do último usuário logado, flag de *onboarding* concluído). | Coleções de dados, listas com mais de 5 itens, dados relacionais ou dados que exigem busca e ordenação. |
| **`SQLite` (`sqflite`)** | Banco de dados relacional embutido em arquivo local (`.db`) | Coleções estruturadas, catálogos offline, favoritos, histórico de ações, dados que exigem filtros (`WHERE`), ordenação (`ORDER BY`) e integridade referencial. | Dados voláteis de curta duração ou dados compartilhados em tempo real entre múltiplos aparelhos distintos. |
| **Banco em Nuvem (REST / GraphQL / Supabase / Firebase)** | Servidor remoto acessado via rede | Dados centralizados compartilhados entre usuários, autenticação corporativa, sincronização multi-dispositivo. | Dados que precisam estar acessíveis instantaneamente mesmo quando o usuário estiver no metrô ou sem sinal de internet (offline-first). |

---

### 2.2 Modelagem de Dados: Por que Salvar um *Snapshot* dos Dados do Cartão?

Quando modelamos uma tabela de favoritos em um banco local, deparamo-nos com duas alternativas de modelagem:

```text
OPÇÃO A (Apenas o ID):                    OPÇÃO B (Snapshot do Cartão - Adotada no CeliLac):
┌───────────────────────────┐             ┌─────────────────────────────────────────────────┐
│ favorites                 │             │ favorites                                       │
├───────────────────────────┤             ├─────────────────────────────────────────────────┤
│ id: TEXT PRIMARY KEY      │             │ id: TEXT PRIMARY KEY                            │
│ saved_at: INTEGER NOT NULL│             │ name: TEXT NOT NULL                             │
└───────────────────────────┘             │ category: TEXT NOT NULL                         │
                                          │ neighborhood: TEXT NOT NULL                     │
                                          │ rating: REAL NOT NULL                           │
                                          │ saved_at: INTEGER NOT NULL                      │
                                          └─────────────────────────────────────────────────┘
```

#### Por que a Opção B é superior para o aplicativo móvel?
Se guardássemos apenas o `id` (Opção A):
- Ao abrir a aba **Favoritos**, o aplicativo precisaria fazer chamadas de rede ou consultar um catálogo global para buscar nome, bairro e nota de cada `id`.
- Se o usuário estivesse sem internet, a aba de favoritos ficaria completamente em branco ou cheia de erros de rede!
- Guardando o **instantâneo (*snapshot*)** dos dados no momento em que o item foi favoritado (Opção B), o aplicativo garante **experiência offline imediata**: os favoritos são desenhados instantaneamente a partir do disco local sem depender de sinal de internet.

---

### 2.3 O Ciclo de Vida da Conexão SQLite no Flutter e Abertura Preguiçosa (*Lazy Initialization*)

O pacote `sqflite` se comunica com as bibliotecas nativas de SQLite do sistema operacional (Android C API e iOS libsqlite3).

#### 1. Localização do Arquivo de Banco no Sistema de Arquivos
Cada plataforma possui uma pasta protegida e isolada para os dados do aplicativo (*sandbox* do app). Jamais devemos escrever caminhos manuais como `"/data/data/com.exemplo/..."`.
Em vez disso:
- A função **`getDatabasesPath()`** do `sqflite` interroga o sistema operacional e retorna o caminho absoluto e seguro da pasta de bancos de dados daquele app.
- O pacote **`path`** (usado como `p.join(directory, databaseFileName)`) combina o diretório e o nome do arquivo utilizando o separador correto de diretórios do sistema operacional (`/` no Linux/Android/iOS e `\` no Windows), evitando bugs com barras duplicadas ou invertidas.

#### 2. Abertura Preguiçosa com Memoização (`??=`)
Criar uma conexão com o banco de dados envolve I/O de disco e alocação de memória no processo do SO. Seria um desperdício abrir o banco de dados logo no `main()` se o usuário puder abrir o app apenas para ver outra tela.
Por isso, utilizamos uma propriedade com **inicialização preguiçosa (*lazy getter*)**:

```dart
Future<Database>? _database;

Future<Database> get _db => _database ??= _openDatabase();
```

- Na primeira vez em que qualquer método (`loadAll`, `isFavorite`, `add`, `remove`) solicitar `_db`, `_database` será nulo. O operador `??=` executará `_openDatabase()` e guardará o `Future<Database>` na variável.
- Em todas as chamadas seguintes, `_database` já terá a referência do `Future` em memória, retornando instantaneamente a mesma conexão sem reabrir o arquivo no disco.

#### 3. Injeção da Função de Abertura para Testabilidade
Repare no construtor do repositório:
```dart
SqliteFavoritesRepository({Future<Database> Function()? openDatabase})
    : _openDatabase = openDatabase ?? _openDefaultDatabase;
```
Esse padrão permite que, em testes de unidade ou integração avançados, possamos injetar uma função que abre um banco de dados em memória (`openDatabase(inMemoryDatabasePath, ...)`) sem nunca tocar no disco real do aparelho.

---

### 2.4 DDL (Data Definition Language) do Esquema v1

O método `openDatabase` recebe o parâmetro de callback `onCreate`. O Flutter só executa esse callback **uma única vez**, quando o arquivo `.db` ainda **não existe** no disco.

Abaixo está o comando DDL que define a tabela `favorites` na versão 1:

```sql
CREATE TABLE favorites (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  neighborhood TEXT NOT NULL,
  rating REAL NOT NULL,
  saved_at INTEGER NOT NULL
)
```

#### Fundamentação das Regras e Tipos Relacionais:
1. **`id TEXT PRIMARY KEY`:** O identificador exclusivo do estabelecimento. Ao ser declarado como `PRIMARY KEY`, o SQLite cria automaticamente um índice em árvore B (*B-Tree*) que permite localizar qualquer registro pelo `id` em tempo logarítmico extremamente rápido ($O(\log N)$). Além disso, impede que o mesmo `id` seja cadastrado em duplicidade.
2. **`NOT NULL` em todas as colunas:** Garante a integridade dos dados na camada do banco. Se por algum erro um campo obrigatório for omitido, o banco rejeita a operação em vez de gravar dados corrompidos ou inconsistentes.
3. **`rating REAL NOT NULL`:** No SQLite, números de ponto flutuante utilizam o tipo `REAL` (equivalente ao `double` de 64 bits do Dart).
4. **`saved_at INTEGER NOT NULL`:** O momento exato em que o usuário tocou no coração.
   - *Por que não usar tipo `DATETIME` ou texto `TEXT`?* O SQLite não possui um tipo `DATETIME` nativo dedicado. Armazenar a data como um número inteiro de 64 bits (`INTEGER`), representando os milissegundos desde a época Unix (`millisecondsSinceEpoch`), consome menos espaço em disco e torna a ordenação numérica (`ORDER BY saved_at DESC`) muito mais rápida do que comparações de strings!

---

### 2.5 Operações CRUD Seguras e Idempotentes no `sqflite`

O `sqflite` fornece métodos de alto nível que abstraem o SQL cru e garantem segurança nativa contra vulnerabilidades:

#### 1. Inserção com `ConflictAlgorithm.replace`
```dart
await db.insert(
  tableName,
  row,
  conflictAlgorithm: ConflictAlgorithm.replace,
);
```
- **O que acontece se o usuário tocar rapidamente duas vezes no botão de favoritar?**
- Sem o `conflictAlgorithm`, o segundo toque tentaria inserir um registro com a mesma chave primária (`id`), lançando uma exceção de `DatabaseException: UNIQUE constraint failed`.
- Com **`ConflictAlgorithm.replace`**, o SQLite detecta o conflito de chave primária e, de forma transparente e atômica, executa um `UPDATE` da linha existente com os novos dados e o novo `saved_at`, garantindo **idempotência**.

#### 2. Leitura com `ORDER BY saved_at DESC`
```dart
final rows = await db.query(tableName, orderBy: 'saved_at DESC');
```
- O método `query` retorna uma lista de mapas: `List<Map<String, Object?>>`.
- O parâmetro `orderBy: 'saved_at DESC'` instrui o motor do SQLite a ordenar os registros do maior milissegundo para o menor, garantindo que o favorito mais recente apareça sempre no topo da lista na aba **Favoritos**.

#### 3. Verificação de Existência Otimizada (`isFavorite`)
```dart
final rows = await db.query(
  tableName,
  columns: ['id'],
  where: 'id = ?',
  whereArgs: [establishmentId],
  limit: 1,
);
return rows.isNotEmpty;
```
- **Otimização de memória:** Solicitamos apenas a coluna `columns: ['id']` e limitamos a busca a `limit: 1`. Não há necessidade de carregar nome, bairro e nota apenas para saber se o item existe!
- **Parâmetro posicional `?` com `whereArgs`:** O motor do SQLite substitui com segurança o marcador `?` pelo valor de `establishmentId` de forma parametrizada. O valor é tratado estritamente como dado, tornando qualquer tentativa de injeção de SQL ou problema com apóstrofo totalmente inofensiva.

#### 4. Remoção Segura (`remove`)
```dart
await db.delete(
  tableName,
  where: 'id = ?',
  whereArgs: [establishmentId],
);
```
- Da mesma forma que na consulta, a deleção utiliza `where: 'id = ?'` e `whereArgs: [establishmentId]`, garantindo que apenas a linha com aquele identificador exato seja excluída.

---

## 3. A Prática (Implementação Passo a Passo)

Agora que toda a fundamentação teórica foi estabelecida, vamos implementar a persistência real no projeto do laboratório.

---

### 3.1 Adicionando as Dependências no `pubspec.yaml`

Abra o arquivo `pubspec.yaml` do projeto `lab_favoritos` e adicione os pacotes `sqflite` e `path` na seção `dependencies`:

```yaml
name: lab_favoritos
description: "Laboratório de Favoritos com SQLite e Provider"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
  sqflite: ^2.3.3+1
  path: ^1.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
```

Após editar, execute no terminal do projeto:
```bash
flutter pub get
```

---

### 3.2 Criando `lib/features/favorites/data/sqlite_favorites_repository.dart`

**O que este arquivo propõe e resolve:**
Propõe a implementação concreta do contrato `FavoritesRepository` baseada em banco de dados relacional SQLite no disco. Ele resolve de forma definitiva a persistência dos favoritos entre reinicializações do app, garantindo integridade relacional, ordenação cronológica delegada ao banco e imunidade a injeções de SQL com consultas parametrizadas.

**Papel Arquitetural (`features/favorites/data`):**
Pertence à camada de **Dados (`data`)**. Ele assina o contrato abstrato `FavoritesRepository` da camada de domínio (`domain`) e encapsula todos os detalhes de baixo nível do `sqflite` (`openDatabase`, `getDatabasesPath`, `Database`, mapas de colunas SQL). Nenhuma outra camada do app precisa saber que o SQLite existe.

**Fundamentação dos recursos utilizados no código:**
- **`implements FavoritesRepository`:** Garante em tempo de compilação que todos os métodos exigidos pelo domínio (`loadAll`, `isFavorite`, `add`, `remove`) serão implementados com os mesmos tipos e assinaturas.
- **`static const int schemaVersion = 1`:** Define a versão inicial do banco de dados. (Na Etapa 5, evoluiremos para a versão 2 com `onUpgrade`).
- **`p.join` do pacote `path`:** Garante concatenação de caminhos compatível com qualquer sistema operacional móvel.
- **Conversão de Mapas para Entidades:** O método privado `_fromRow` converte cada linha retornada pelo SQLite (`Map<String, Object?>`) de volta em uma instância pura de `Establishment`.
- **`close()`:** Fornece um método para liberar a conexão com o banco de dados quando necessário.

Crie o arquivo em `lib/features/favorites/data/sqlite_favorites_repository.dart`:

```dart
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../establishments/domain/entities/establishment.dart';
import '../domain/repositories/favorites_repository.dart';

/// Implementação de [FavoritesRepository] que persiste favoritos no SQLite.
class SqliteFavoritesRepository implements FavoritesRepository {
  SqliteFavoritesRepository({Future<Database> Function()? openDatabase})
      : _openDatabase = openDatabase ?? _openDefaultDatabase;

  static const String tableName = 'favorites';
  static const String databaseFileName = 'lab_favorites.db';
  static const int schemaVersion = 1;

  final Future<Database> Function() _openDatabase;
  Future<Database>? _database;

  /// Acesso preguiçoso e reaproveitado à conexão do banco de dados.
  Future<Database> get _db => _database ??= _openDatabase();

  /// Abre a conexão local no diretório protegido do aplicativo.
  static Future<Database> _openDefaultDatabase() async {
    final directory = await getDatabasesPath();
    final path = p.join(directory, databaseFileName);

    return openDatabase(
      path,
      version: schemaVersion,
      onCreate: createSchema,
    );
  }

  /// Criação da tabela relacional na Versão 1 do banco de dados.
  static Future<void> createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        neighborhood TEXT NOT NULL,
        rating REAL NOT NULL,
        saved_at INTEGER NOT NULL
      )
    ''');
  }

  @override
  Future<List<Establishment>> loadAll() async {
    final db = await _db;
    final rows = await db.query(tableName, orderBy: 'saved_at DESC');

    return [
      for (final row in rows) _fromRow(row),
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
    final timestamp = (savedAt ?? DateTime.now()).millisecondsSinceEpoch;

    await db.insert(
      tableName,
      {
        'id': establishment.id,
        'name': establishment.name,
        'category': establishment.category,
        'neighborhood': establishment.neighborhood,
        'rating': establishment.rating,
        'saved_at': timestamp,
      },
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

  /// Fecha a conexão com o banco de dados, liberando recursos do SO.
  Future<void> close() async {
    final db = _database;
    _database = null;
    if (db != null) {
      await (await db).close();
    }
  }

  /// Converte uma linha retornada pelo SQLite no modelo de domínio [Establishment].
  static Establishment _fromRow(Map<String, Object?> row) {
    return Establishment(
      id: row['id']! as String,
      name: row['name']! as String,
      category: row['category']! as String,
      neighborhood: row['neighborhood']! as String,
      rating: (row['rating']! as num).toDouble(),
    );
  }
}
```

---

### 3.3 Atualizando `lib/app/lab_app.dart`

**O que este arquivo propõe e resolve:**
Agora conectamos a nova implementação SQLite ao restante do aplicativo. Como o `FavoritesController` depende apenas da abstração `FavoritesRepository`, basta instanciar `SqliteFavoritesRepository()` como repositório padrão!

Abra `lib/app/lab_app.dart` e atualize o código:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/favorites/data/sqlite_favorites_repository.dart';
import '../features/favorites/domain/repositories/favorites_repository.dart';
import '../features/favorites/presentation/favorites_controller.dart';
import 'shell/app_shell.dart';

class LabApp extends StatelessWidget {
  const LabApp({
    super.key,
    this.favoritesRepository,
  });

  final FavoritesRepository? favoritesRepository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FavoritesController(
        favoritesRepository ?? SqliteFavoritesRepository(),
      )..load(),
      child: MaterialApp(
        title: 'Lab Favoritos',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        home: const AppShell(),
      ),
    );
  }
}
```

---

### 3.4 O Testemunho do Desacoplamento Limpo

Neste exato momento, chame a atenção da turma para um fato notável:
- Alteramos o `FavoritesController`? **Não.**
- Alteramos a `HomePage`? **Não.**
- Alteramos a `FavoritesPage`? **Não.**
- Alteramos a `EstablishmentDetailsPage`? **Não.**
- Alteramos o `EstablishmentCard` ou o `FavoriteButton`? **Não.**

Trocamos toda a infraestrutura de armazenamento do aplicativo — saindo de uma lista na memória RAM e migrando para um banco de dados relacional completo no disco — alterando apenas a linha de injeção no `LabApp`! Esse é o maior benefício prático de respeitar as camadas de arquitetura e o Princípio da Inversão de Dependência.

---

## 4. Verificação, Inspeção do Banco Real e Ponte com o CeliLac

Chegou a hora de validar na prática que o banco SQLite está funcionando e inspecionar os dados reais persistidos no aparelho.

---

### 4.1 Roteiro de Verificação ao Vivo (O Teste Definitivo da Persistência)

Execute o aplicativo no emulador ou aparelho físico (`flutter run`):

1. **Passo 1 (Favoritar estabelecimentos):**
   - Na aba **Início**, toque no coração do **Café Aconchego** (nota 4.8).
   - Toque no coração da **Padaria Trigo Zero** (nota 4.9).
   - Abra a aba **Favoritos**: ambos estão listados, com a **Padaria Trigo Zero** no topo (pois foi favoritada por último e a query usa `ORDER BY saved_at DESC`).
2. **Passo 2 (O Teste do Fechamento Completo do App):**
   - No terminal do Flutter, pare totalmente a execução pressionando **`q`** (ou encerre o processo do app no gerenciador de tarefas do Android/iOS).
   - Inicie o aplicativo novamente do zero com `flutter run`.
3. **Passo 3 (A Comprovação):**
   - Assim que o aplicativo abre, navegue para a aba **Favoritos**: **todos os itens favoritados continuam intactos e ordenados!**
   - Na aba **Início**, os corações do Café Aconchego e da Padaria Trigo Zero continuam vermelhos e preenchidos.
4. **Passo 4 (Remoção no Banco):**
   - Abra os detalhes do **Café Aconchego** e toque no coração da `AppBar` para desfavoritar.
   - Volte para a aba **Favoritos**: restou apenas a Padaria Trigo Zero.
   - Feche o app novamente (`q`) e reabra: apenas a Padaria Trigo Zero permanece salva. A remoção atômica com `delete` funcionou perfeitamente.

---

### 4.2 Inspecionando o Arquivo SQLite no Emulador / Dispositivo

Para que os alunos vejam que não há "mágica", mostre como inspecionar o arquivo real `.db` gerado pelo SQLite.

#### Opção A: Pelo Terminal via ADB (Android)
No terminal, com o emulador Android rodando:

```bash
# Entrar no shell do emulador como root/debug
adb shell

# Acessar a pasta de bancos de dados do app (substitua pelo seu package name)
cd /data/data/com.example.lab_favoritos/databases/
ls -la
```

Você verá o arquivo:
```text
lab_favorites.db
lab_favorites.db-journal (ou -wal)
```

Abra o cliente SQLite do terminal:
```bash
sqlite3 lab_favorites.db
```

E execute comandos SQL ao vivo na frente dos alunos:
```sql
.tables
-- Retorna: favorites

.schema favorites
-- Exibe o CREATE TABLE que escrevemos no createSchema!

SELECT id, name, category, rating, saved_at FROM favorites;
-- Exibe as linhas reais gravadas pelo aplicativo!

.exit
```

#### Opção B: Pelo App Inspection do Android Studio ou SQLite Viewer no VS Code
- No **Android Studio**: com o app rodando em modo debug, abra a aba inferior **App Inspection** → selecione **Database Inspector**. Você verá a tabela `favorites` renderizada em grade visual, atualizando a cada toque no coração!
- No **VS Code**: instale a extensão **SQLite Viewer**, copie o arquivo `lab_favorites.db` do emulador com `adb pull` e abra o arquivo diretamente no editor.

---

### 4.3 Ponte Direta com o CeliLac

Veja como cada conceito e arquivo desta **Etapa 3** corresponde exatamente ao código em produção no **CeliLac**:

| Artefato no `lab_favoritos` (Etapa 3) | Artefato correspondente no **CeliLac** | Papel na Arquitetura |
|---|---|---|
| `lib/features/favorites/data/sqlite_favorites_repository.dart` | [`lib/features/favorites/data/sqlite_favorites_repository.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/favorites/data/sqlite_favorites_repository.dart) | Implementação concreta de `FavoritesRepository` com SQLite, gerenciamento de conexão `_db` preguiçosa e métodos CRUD seguros. |
| `createSchema` com DDL v1 | `createSchema` em [`sqlite_favorites_repository.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/favorites/data/sqlite_favorites_repository.dart#L32-L46) | Criação da tabela relacional com tipos nativos, chave primária e timestamp de ordenação. |
| `ConflictAlgorithm.replace` | `ConflictAlgorithm.replace` em [`sqlite_favorites_repository.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/favorites/data/sqlite_favorites_repository.dart#L87) | Prevenção de exceção de duplicidade na inserção. |
| `where: 'id = ?'` e `whereArgs: [id]` | `whereArgs` em [`sqlite_favorites_repository.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/favorites/data/sqlite_favorites_repository.dart#L74-L96) | Parâmetros posicionais seguros prevenindo *SQL Injection* e erros de sintaxe com apóstrofo em consultas e deleções. |
| `lib/app/lab_app.dart` | [`lib/app/celilac_app.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/app/celilac_app.dart) | Ponto de composição que injeta o `SqliteFavoritesRepository` no `FavoritesController`. |

---

### 4.4 Gancho para a Etapa 4: Tradução de Tipos Ricos (`Dart` ↔ `SQLite`)

Feche a aula com a seguinte provocação aos alunos:

*"Hoje persistimos dados simples: textos (`TEXT`), inteiros (`INTEGER`) e números decimais (`REAL`).*
*Mas e se o nosso modelo de domínio não tiver apenas strings e números primitivos?*
*E se a categoria for um `enum EstablishmentCategory`?*
*E se o estabelecimento tiver um conjunto de restrições alimentares `Set<DietaryOption>`?*
*E se a nota vier do banco como um número inteiro `5` em vez de `5.0`, causando um crash de cast de tipo no Dart?*
*E o que acontece se alguém cadastrar no banco uma categoria que não existe mais no nosso código Dart?"*

Na **Etapa 4**, aprenderemos como criar uma camada de tradução dedicada (`toRow` e `fromRow`) com classes auxiliares, serialização de enums, manipulação determinística de coleções e defesas numéricas rigorosas, mantendo nossa entidade de domínio pura e protegida!

