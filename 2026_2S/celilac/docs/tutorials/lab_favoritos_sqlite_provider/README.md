# Laboratório Sequencial: Favoritos, SQLite e Provider (Teoria e Prática Etapa a Etapa)

## 1. Motivação e Diagnóstico Pedagógico

Os materiais principais da Etapa 5 do CeliLac — [CeliLac_Favoritos_SQLite_e_Provider.md](../CeliLac_Favoritos_SQLite_e_Provider.md) e [CeliLac_Favoritos_SQLite_e_Provider_Slides.md](../CeliLac_Favoritos_SQLite_e_Provider_Slides.md) — apresentam uma solução completa de engenharia integrada a um aplicativo real que já possui `SplashPage`, `AppShell` com `IndexedStack`, `Hero`, `ProfileController`, arquitetura em 3 camadas (`domain`, `data`, `presentation`) e diretrizes estritas de acessibilidade.

Embora esse material seja excelente como **ponto de chegada**, aplicá-lo de uma só vez em sala de aula impõe uma **carga cognitiva elevada**: o estudante precisa lidar ao mesmo tempo com modelagem relacional, tipos do SQLite, segurança contra *SQL Injection*, migração de versão (`onUpgrade`), substituição de `InheritedNotifier` pelo pacote `provider`, sincronização entre abas, colisão de tags de `Hero` e acessibilidade em cartões com múltiplas ações.

### A Solução Pedagógica: Um Projeto-Laboratório Sequencial

Esta pasta organiza uma **abordagem incremental em degraus**, na qual trabalhamos **um único conceito importante por vez**, dentro de um projeto específico e enxuto de laboratório, antes de consolidar tudo no CeliLac e nos projetos dos alunos.

Em cada etapa sequencial, seguimos sempre o mesmo ciclo didático de 4 passos:

1. **O Problema (A Dor):** o que não funciona, o que se perde ou o que fica difícil de manter no código da etapa anterior? (Muitas vezes provocando o problema ao vivo com os alunos).
2. **O Conceito (Teoria Focada):** qual é o fundamento técnico que resolve exatamente esse problema, quais são as alternativas e por que escolhemos esta abordagem?
3. **A Prática (Mão na Massa Isolada):** alteração cirúrgica no código do projeto-laboratório, tocando apenas no conceito da vez.
4. **Verificação e Ponte com o CeliLac:** como validar o comportamento na tela e onde exatamente essa peça se encaixa no código do CeliLac.

---

## 2. Mapa Geral dos 8 Degraus Conceituais

A tabela abaixo resume a progressão completa que será construída etapa por etapa:

| Etapa | Conceito Central | O Problema Motivador | Teoria Trabalhada | Entrega Prática e Verificação |
|---|---|---|---|---|
| **Etapa 1** | **Estado Compartilhado com `ChangeNotifier` e `provider`** | Duas telas (Listagem e Detalhe) e uma aba de Favoritos precisam enxergar e alterar a mesma coleção sem repassar callbacks por vários construtores. | Estado efêmero vs. compartilhado; `ChangeNotifier`; `notifyListeners()`; `ChangeNotifierProvider`; diferença entre `context.watch<T>()` (no `build`) e `context.read<T>()` (em ações/cliques); `List` (ordem) + `Set` (busca `O(1)`). | App funcionando 100% em memória: favoritar no cartão ou no detalhe atualiza todas as telas instantaneamente. |
| **Etapa 2** | **Contrato de Persistência (`Repository`) e Assincronia** | Ao fechar o app, os favoritos em memória desaparecem. Mas o `Controller` não deve conhecer detalhes de banco de dados ou pacotes externos. | Separação entre `domain`, `data` e `presentation`; inversão de dependência com `abstract interface class`; métodos assíncronos (`Future`); atualizar persistência antes de notificar a UI; tratamento de falha com `SnackBar`. | Extração da interface `FavoritesRepository`, implementação de um `MemoryFavoritesRepository` assíncrono e estados de carregamento (`isLoaded`) e erro no controlador. |
| **Etapa 3** | **Primeiros Passos no SQLite (`sqflite`) — CRUD e Segurança** | `SharedPreferences` exige ler e regravar a lista inteira a cada toque. Precisamos gravar, remover e ordenar item a item no disco. | Quando usar `SharedPreferences` vs. `SQLite` vs. Nuvem; abertura preguiçosa (`??=`); `CREATE TABLE` (`PRIMARY KEY`, `NOT NULL`); `INSERT` com `ConflictAlgorithm.replace`; `SELECT` com `ORDER BY saved_at DESC`; `DELETE` seguro com marcador `?` e `whereArgs` (prevenção de *SQL Injection*). | `SqliteFavoritesRepository` na versão 1 do esquema, persistindo dados reais no arquivo `.db` do aparelho/emulador. |
| **Etapa 4** | **Tradução de Tipos Ricos (`Dart` ↔ `SQLite`)** | A entidade de domínio usa `enum`, `Set<Enum>`, `DateTime` e `double`, mas o SQLite só possui 5 classes de armazenamento (`NULL`, `INTEGER`, `REAL`, `TEXT`, `BLOB`). | Mapeamento de tipos: `DateTime` → `INTEGER` (`millisecondsSinceEpoch`); `enum` → `TEXT` (`.name` vs `.index`); `Set<Enum>` → `TEXT` ordenado separado por vírgula; defesa `(row['...'] as num).toDouble()`; tolerância a valores desconhecidos na leitura. | Camada isolada de conversão (`toRow` e `fromRow`) mantendo a entidade de domínio pura. |
| **Etapa 5** | **Evolução de Esquema sem Perda de Dados (`onUpgrade`)** | O app já está instalado no celular do usuário (banco na `v1`) e o cartão passa a exigir uma nova coluna (`logo_source` na `v2`). | Ciclo de vida do arquivo `.db`; por que `onCreate` não roda de novo para usuários antigos; o perigo do `DROP TABLE`; migração incremental com `version: 2`, `onUpgrade` e `ALTER TABLE ... ADD COLUMN` usando blocos `if (oldVersion < X)`. | Provocação controlada do erro `no such column`, incremento para `schemaVersion = 2` e migração preservando os favoritos já cadastrados na `v1`. |
| **Etapa 6** | **Múltiplos Estados Globais (`MultiProvider`) e Carga Paralela** | O app passa a ter um segundo estado compartilhado (ex.: Perfil/Filtro do usuário) que precisa ser combinado com os Favoritos na mesma tela. | O problema da "pirâmide" de escopos aninhados; `MultiProvider`; cruzamento de dois `context.watch` na mesma tela; inicialização paralela de múltiplos carregamentos assíncronos com `(loadA, loadB).wait`. | Segundo controlador integrado via `MultiProvider` no topo do app, exibindo selo de compatibilidade nos cartões da Home e dos Favoritos. |
| **Etapa 7** | **`Hero` sem Colisão em `IndexedStack` e Acessibilidade em Cartões de Ação Dupla** | Como evitar colisão de `Hero` e perda de acessibilidade quando o mesmo cartão ganha 2 botões de toque e aparece ao mesmo tempo em 2 abas do `IndexedStack`? | Prefixo de origem na tag do `Hero` (`'$origin-establishment-icon-$id'`); remoção de `MergeSemantics` global em cartões com duas ações de toque independentes (`>= 48×48 dp`) e `tooltip` contextualizado. | Navegação fluida com animação `Hero` a partir de ambas as abas e cartões acessíveis para leitores de tela. |
| **Etapa 8** | **Testes Automatizados com SQLite em Memória (FFI), Dublês e Migração** | Testes apenas com mocks escondem erros de sintaxe SQL, e testes em emulador são lentos demais para o fluxo diário de desenvolvimento. | Dart FFI com `sqflite_common_ffi` e `inMemoryDatabasePath`; isolamento com `singleInstance: false`; testes determinísticos de migração de esquema (`v1` ➔ `v2`); dublê `MemoryFavoritesRepository` para widgets e acessibilidade (`labeledTapTargetGuideline`). | Suíte de testes completa executando no terminal em milissegundos sem abrir emulador. |

---

## 3. Detalhamento Pedagógico de Cada Etapa

Abaixo está o plano detalhado do que será trabalhado em cada documento e passo de código quando avançarmos.

### [Etapa 1 — Estado Compartilhado em Memória com `ChangeNotifier` e `provider`](./Etapa_01_Estado_Compartilhado_Provider.md)
- **Guia passo a passo de aula:** [`Etapa_01_Estado_Compartilhado_Provider.md`](./Etapa_01_Estado_Compartilhado_Provider.md)
- **Roteiro para Slides (Gamma):** [`Etapa_01_Estado_Compartilhado_Provider_Slides.md`](./Etapa_01_Estado_Compartilhado_Provider_Slides.md)
- **Cenário inicial:** um app simples com uma lista de itens (cartões com botão de coração), uma tela de detalhes (com botão de coração na `AppBar`) e uma aba "Favoritos".
- **Dor demonstrada:** se cada cartão ou tela tiver um `bool isFavorite` local em um `StatefulWidget`, favoritar na tela de detalhes não atualiza o cartão da lista nem a aba de Favoritos.
- **Conceitos trabalhados:**
  - Por que elevar o estado para um ancestral comum;
  - Criação do `FavoritesController extends ChangeNotifier`;
  - Estrutura dupla em memória: `List<Item>` (para manter a ordem de exibição) + `Set<String> _favoriteIds` (para responder `isFavorite(id)` em tempo constante `O(1)`);
  - Exposição na árvore com `ChangeNotifierProvider` acima do `MaterialApp` (para que rotas empilhadas com `Navigator.push` também enxerguem o estado);
  - Regra de ouro: `context.watch<FavoritesController>()` apenas dentro do `build`; `context.read<FavoritesController>()` dentro de callbacks (`onPressed`, `onTap`).
- **Ponte com o CeliLac:** `FavoritesController`, `FavoriteButton`, `CeliLacApp`, `HomePage`, `EstablishmentDetailsPage` e `FavoritesPage`.

---

### [Etapa 2 — Desacoplamento com `FavoritesRepository` e Fluxo Assíncrono](./Etapa_02_Contrato_Repository_e_Assincronia.md)
- **Guia passo a passo de aula:** [`Etapa_02_Contrato_Repository_e_Assincronia.md`](./Etapa_02_Contrato_Repository_e_Assincronia.md)
- **Roteiro para Slides (Gamma):** [`Etapa_02_Contrato_Repository_e_Assincronia_Slides.md`](./Etapa_02_Contrato_Repository_e_Assincronia_Slides.md)
- **Dor demonstrada:** fechar e reabrir o aplicativo apaga todos os favoritos marcados na Etapa 1. Além disso, se colocarmos comandos de banco diretamente dentro do `FavoritesController`, misturaremos regras de apresentação com detalhes de infraestrutura.
- **Conceitos trabalhados:**
  - Contrato no domínio: `abstract interface class FavoritesRepository` (`loadAll`, `isFavorite`, `add`, `remove`);
  - Implementação de um `MemoryFavoritesRepository` para validar o contrato e simular atrasos ou falhas (`failOnChange`);
  - Ordem segura de atualização no `toggle`: **primeiro** aguardar a gravação (`await _repository.add(...)`), **depois** atualizar a memória e chamar `notifyListeners()` — garantindo que a interface nunca minta caso a gravação falhe;
  - Tratamento de erro na UI com `try / catch`, verificação de `mounted` e exibição de `SnackBar`.
- **Ponte com o CeliLac:** `lib/features/favorites/domain/repositories/favorites_repository.dart`.

---

### [Etapa 3 — Persistência Relacional com SQLite (`sqflite`) — Tabela v1 e CRUD Seguro](./Etapa_03_Sqlite_Crud_e_Seguranca.md)
- **Guia passo a passo de aula:** [`Etapa_03_Sqlite_Crud_e_Seguranca.md`](./Etapa_03_Sqlite_Crud_e_Seguranca.md)
- **Roteiro para Slides (Gamma):** [`Etapa_03_Sqlite_Crud_e_Seguranca_Slides.md`](./Etapa_03_Sqlite_Crud_e_Seguranca_Slides.md)
- **Dor demonstrada:** precisamos gravar no disco do aparelho, mas usar `SharedPreferences` para uma coleção exigiria ler, decodificar, alterar e regravar a lista inteira a cada toque no coração.
- **Conceitos trabalhados:**
  - Comparativo prático: `SharedPreferences` (1 valor / 1 documento pequeno) vs. `SQLite` (coleção de linhas independentes consultáveis e ordenáveis);
  - Modelagem: guardar apenas o `id` vs. guardar um **instantâneo (*snapshot*) dos dados do cartão** para funcionar 100% *offline*;
  - Abertura preguiçosa e única da conexão: `Future<Database> get _db => _database ??= _openDatabase();`;
  - DDL inicial (`CREATE TABLE favorites` na versão 1);
  - Operações CRUD:
    - `db.insert(..., conflictAlgorithm: ConflictAlgorithm.replace)` para evitar erro de chave primária duplicada;
    - `db.query(tableName, orderBy: 'saved_at DESC')` delegando a ordenação ao motor do banco;
    - `db.query` e `db.delete` usando sempre `where: 'id = ?'` e `whereArgs: [id]` para impedir *SQL Injection* e bugs com aspas no texto.
- **Ponte com o CeliLac:** `lib/features/favorites/data/sqlite_favorites_repository.dart`.

---

### [Etapa 4 — Tradução de Tipos Compostos (`Dart` ↔ `SQLite`)](./Etapa_04_Traducao_de_Tipos_Compostos_Dart_SQLite.md)
- **Guia passo a passo de aula:** [`Etapa_04_Traducao_de_Tipos_Compostos_Dart_SQLite.md`](./Etapa_04_Traducao_de_Tipos_Compostos_Dart_SQLite.md)
- **Roteiro para Slides (Gamma):** [`Etapa_04_Traducao_de_Tipos_Compostos_Dart_SQLite_Slides.md`](./Etapa_04_Traducao_de_Tipos_Compostos_Dart_SQLite_Slides.md)
- **Dor demonstrada:** como salvar no SQLite campos que são `enum` (categoria), `Set<Enum>` (opções alimentares/tags), `DateTime` (momento em que foi salvo) e `double` (nota/distância)?
- **Conceitos trabalhados:**
  - As 5 classes de armazenamento do SQLite (`NULL`, `INTEGER`, `REAL`, `TEXT`, `BLOB`);
  - Por que salvar `DateTime` como `INTEGER` (`millisecondsSinceEpoch`) facilita e acelera o `ORDER BY saved_at DESC`;
  - Por que salvar `enum` como `TEXT` (`.name`) é mais seguro do que `.index` caso o `enum` ganhe novos itens ou mude de ordem no código;
  - Serialização determinística de `Set<Enum>` com `..sort()` e `join(',')`;
  - Duas defesas críticas na leitura (`fromRow`):
    1. `(row['rating']! as num).toDouble()` (evitando crash quando o SQLite devolve `5` como `int` em coluna `REAL`);
    2. `.where((item) => item.name == raw).firstOrNull` (tolerância caso um valor antigo do banco deixe de existir no `enum`).
- **Ponte com o CeliLac:** `lib/features/favorites/data/favorite_establishment_row.dart`.

---

### [Etapa 5 — Evolução do Banco e Migração de Esquema (`version` e `onUpgrade`)](./Etapa_05_Evolucao_do_Banco_e_Migracao_de_Esquema.md)
- **Guia passo a passo de aula:** [`Etapa_05_Evolucao_do_Banco_e_Migracao_de_Esquema.md`](./Etapa_05_Evolucao_do_Banco_e_Migracao_de_Esquema.md)
- **Roteiro para Slides (Gamma):** [`Etapa_05_Evolucao_do_Banco_e_Migracao_de_Esquema_Slides.md`](./Etapa_05_Evolucao_do_Banco_e_Migracao_de_Esquema_Slides.md)
- **Dor demonstrada (experimento prático em aula):** com o app já tendo favoritos salvos no banco `v1`, adicionamos o campo opcional `logoSource` (`logo_source`) no modelo e no `CREATE TABLE`, sem mudar a versão. Ao favoritar um item, o app quebra com `DatabaseException(no such column: logo_source)`.
- **Conceitos trabalhados:**
  - Entender quando o SQLite executa `onCreate` (apenas quando o arquivo `.db` **não existe**) e quando executa `onUpgrade` (quando o arquivo já existe com `oldVersion < newVersion`);
  - Por que nunca devemos resolver evolução de esquema com `DROP TABLE` em produção;
  - Implementação de `schemaVersion = 2` e `upgradeSchema(db, oldVersion, newVersion)` usando `if (oldVersion < 2) { await db.execute('ALTER TABLE favorites ADD COLUMN logo_source TEXT'); }`;
  - Por que usar `if (oldVersion < 2)` sequenciais em vez de `switch` (permitindo saltar da `v1` para uma futura `v3` aplicando todas as migrações em cadeia).
- **Ponte com o CeliLac:** métodos `createSchema` e `upgradeSchema` em `SqliteFavoritesRepository`.

---

### [Etapa 6 — Escala de Estado com `MultiProvider` e Inicialização Paralela](./Etapa_06_MultiProvider_e_Inicializacao_Paralela.md)
- **Guia passo a passo de aula:** [`Etapa_06_MultiProvider_e_Inicializacao_Paralela.md`](./Etapa_06_MultiProvider_e_Inicializacao_Paralela.md)
- **Roteiro para Slides (Gamma):** [`Etapa_06_MultiProvider_e_Inicializacao_Paralela_Slides.md`](./Etapa_06_MultiProvider_e_Inicializacao_Paralela_Slides.md)
- **Dor demonstrada:** o aplicativo agora tem dois estados globais independentes (ex.: `ProfileController` e `FavoritesController`). Aninhar escopos manualmente cria código repetitivo, e carregar um banco depois do outro atrasa a abertura do app.
- **Conceitos trabalhados:**
  - Evolução do `InheritedNotifier` manual (ou de um único `ChangeNotifierProvider`) para o `MultiProvider`;
  - Como uma mesma tela (`HomePage` e `FavoritesPage`) consome múltiplos controladores (`context.watch<ProfileController>()` + `context.watch<FavoritesController>()`) para cruzar informações (ex.: destacar nos favoritos quais lugares atendem ao perfil atual);
  - Disparo concorrente na abertura do app usando *records* e `.wait`: `await (profileLoad, favoritesLoad).wait`.
- **Ponte com o CeliLac:** `lib/app/celilac_app.dart`, `lib/features/startup/presentation/splash_page.dart` e `lib/features/favorites/presentation/pages/favorites_page.dart`.

---

### [Etapa 7 — `Hero` sem Colisão em `IndexedStack` e Acessibilidade em Cartões de Ação Dupla](./Etapa_07_Hero_sem_Colisao_e_Acessibilidade.md)
- **Guia passo a passo de aula:** [`Etapa_07_Hero_sem_Colisao_e_Acessibilidade.md`](./Etapa_07_Hero_sem_Colisao_e_Acessibilidade.md)
- **Roteiro para Slides (Gamma):** [`Etapa_07_Hero_sem_Colisao_e_Acessibilidade_Slides.md`](./Etapa_07_Hero_sem_Colisao_e_Acessibilidade_Slides.md)
- **Dor demonstrada:**
  1. Ter o mesmo cartão montado na aba Início e na aba Favoritos dentro de um `IndexedStack` quebra a navegação com `Hero` (`multiple heroes that share the same tag`);
  2. Ter um botão de favoritar dentro de um `Card` clicável com `MergeSemantics` impede que leitores de tela acionem o botão de coração.
- **Conceitos trabalhados:**
  - Desambiguação de `Hero` por contexto de origem (`'$origin-establishment-icon-$id'`);
  - Acessibilidade em cartões de ação dupla: áreas mínimas de `48×48 dp`, separação de nós semânticos e `tooltip` nominal (`'Salvar Café Aconchego nos favoritos'`).
- **Ponte com o CeliLac:** `lib/features/establishments/presentation/establishment_hero_tag.dart` e `lib/features/establishments/presentation/widgets/establishment_card.dart`.

---

### [Etapa 8 — Testes Automatizados com SQLite em Memória (FFI), Dublês e Migração](./Etapa_08_Testes_Automatizados_SQLite_em_Memoria.md)
- **Guia passo a passo de aula:** [`Etapa_08_Testes_Automatizados_SQLite_em_Memoria.md`](./Etapa_08_Testes_Automatizados_SQLite_em_Memoria.md)
- **Roteiro para Slides (Gamma):** [`Etapa_08_Testes_Automatizados_SQLite_em_Memoria_Slides.md`](./Etapa_08_Testes_Automatizados_SQLite_em_Memoria_Slides.md)
- **Dor demonstrada:**
  1. Testar apenas com mocks em memória esconde erros de sintaxe SQL (`CREATE TABLE`, `ALTER TABLE`) e tipos incompatíveis de colunas;
  2. Testes instrumentados em emulador são lentos demais para o fluxo diário de desenvolvimento e pipelines de CI.
- **Conceitos trabalhados:**
  - Execução do motor C do SQLite diretamente no computador hospedeiro via Dart FFI (`sqflite_common_ffi` e `inMemoryDatabasePath`);
  - Isolamento rigoroso entre testes com `singleInstance: false`;
  - Teste determinístico de migração de esquema da versão 1 para a versão 2 sem perda de dados;
  - Dublê controlado `MemoryFavoritesRepository` para testes de UI (`FavoritesPage`) e verificação automatizada de acessibilidade (`labeledTapTargetGuideline`).
- **Ponte com o CeliLac:** pasta `test/features/favorites/` e `test/support/`.

---

## 4. Como Trabalharemos a Partir Daqui

Esta pasta (`docs/tutorials/lab_favoritos_sqlite_provider/`) serve como nossa central para os materiais e roteiros de cada etapa. Todos os 8 degraus conceituais estão devidamente documentados com seus respectivos guias completos e roteiros de slides no padrão Gamma.

---

## 5. Próximas Fases Planejadas para o CeliLac (Roadmap de Pendências)

Com a consolidação da camada de persistência local, estado compartilhado e acessibilidade, as seguintes funcionalidades de produto estão registradas como **próximos passos planejados** para a evolução do aplicativo CeliLac:

1. **Consumo de APIs REST Remotas:**
   - Substituição do catálogo estático de estabelecimentos (`sample_establishments.dart`) por chamadas HTTP assíncronas reais (`http` ou `dio`).
   - Gerenciamento de conectividade (modo online/offline com sincronização de favoritos no banco local SQLite via *Cache-First* ou *Repository Pattern*).
2. **Autenticação e Sessão de Usuário:**
   - Fluxo completo de cadastro, login social/e-mail e recuperação de senha.
   - Armazenamento seguro de tokens JWT no dispositivo com `flutter_secure_storage`.
   - Vínculo dos favoritos à conta do usuário autenticado no backend.
3. **Geolocalização Real e Mapas Interativos:**
   - Obtenção da localização GPS do dispositivo com o pacote `geolocator`.
   - Cálculo e ordenação dinâmica dos estabelecimentos pela distância real até o usuário.
   - Visualização dos estabelecimentos seguros em um mapa interativo com marcadores customizados usando `google_maps_flutter`.

