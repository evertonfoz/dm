# Etapa 2 — Desacoplamento com `FavoritesRepository`, Inversão de Dependência e Fluxo Assíncrono

## Introdução: O que este documento propõe e resolve?

### 1. O Problema Real que Estamos Enfrentando
Ao final da **Etapa 1**, conquistamos a sincronização instantânea entre a aba **Início (`HomePage`)**, a **Tela de Detalhes (`EstablishmentDetailsPage`)** e a aba **Favoritos (`FavoritesPage`)** usando um `FavoritesController` baseado em `ChangeNotifier` e `provider`.

Contudo, bastou fechar e reabrir o aplicativo (ou executar um *Hot Restart*) para encontrarmos duas limitações críticas:

1. **Volatilidade da Memória RAM:** Como `_favorites` e `_favoriteIds` vivem apenas na memória volátil do processo, toda a curadoria feita pelo usuário desaparece assim que o sistema operacional encerra o app.
2. **O Risco do Acoplamento Direto com a Infraestrutura:** A reação imediata de muitos desenvolvedores ao perceber que precisam salvar dados no disco é abrir o `FavoritesController` (que pertence à camada de **Apresentação**) e escrever comandos de banco de dados (`sqflite`, `SharedPreferences` ou chamadas HTTP) diretamente dentro do método `toggle()`. Fazer isso viola a separação arquitetural em camadas, torna o controlador impossível de testar sem um banco real, mistura lógica de estado visual com SQL e ignora o fato de que operações de Entrada/Saída (*I/O*) no disco ou na rede **são assíncronas (`Future`) e podem falhar**.

### 2. O que esta Etapa 2 Propõe e Resolve
Este documento propõe a preparação arquitetural completa para a persistência de dados através da **Inversão de Dependência** e da **Programação Assíncrona**, resolvendo quatro problemas essenciais de Engenharia de Software no Flutter:

1. **Contrato de Persistência no Domínio (`FavoritesRepository`):** Definimos na camada `domain` uma interface pura (`abstract interface class FavoritesRepository`) que estabelece **o que** o aplicativo precisa fazer com os favoritos (`loadAll`, `isFavorite`, `add`, `remove`), sem revelar **como** ou **onde** esses dados serão gravados.
2. **Inversão de Dependência (Princípio *DIP* do SOLID) e Repositório em Memória Simulado (`MemoryFavoritesRepository`):** Fazemos o `FavoritesController` depender apenas da abstração `FavoritesRepository` recebida via construtor (*Injeção de Dependência*). Criamos na camada `data` uma implementação assíncrona em memória capaz de simular estado inicial, latência de leitura e **falhas de gravação (`failOnChange`)**.
3. **Fluxo Assíncrono Idempotente e Ordem Segura de Mutação (`await` antes de `notifyListeners()`):** Transformamos a carga inicial (`load()`) e a alternância (`toggle()`) do controlador em operações assíncronas (`Future`), garantindo que a memória RAM e a interface gráfica **só sejam atualizadas depois que a persistência confirmar o sucesso da gravação** — impedindo que a UI "minta" para o usuário.
4. **Resiliência na Interface (`isLoaded`, `try/catch`, `context.mounted` e `SnackBar`):** Preparamos as páginas para exibir um indicador de progresso (`CircularProgressIndicator`) enquanto os dados são carregados e para capturar exceções de gravação com `try / catch`, verificando com segurança se o widget ainda está montado na árvore (`context.mounted`) antes de exibir um aviso amigável (`SnackBar`).

### 3. Por que Criar o Contrato e o Repositório Assíncrono Antes do SQLite (Etapa 3)?
Se tentássemos transformar o controlador síncrono da Etapa 1 em assíncrono **ao mesmo tempo** em que instalamos o `sqflite`, criamos tabelas SQL e convertemos tipos de dados, o aluno não saberia distinguir o que é código de **arquitetura/assincronia do Flutter** e o que é código de **banco de dados SQLite**.

Além disso, um banco SQLite local funcionando normalmente no celular raramente falha ao gravar 1 linha — o que tornaria muito difícil demonstrar ao vivo em sala de aula **por que** precisamos de `try / catch`, `await` antes do `notifyListeners()` e `SnackBar`! Com o `MemoryFavoritesRepository(failOnChange: true)` desta Etapa 2, podemos provocar falhas controladas de gravação com um único booleano, provar a robustez da nossa camada de apresentação e deixar a **Etapa 3** 100% livre para focar exclusivamente em SQLite (`CREATE TABLE`, `INSERT`, `SELECT`, `DELETE` e prevenção de *SQL Injection*), sem precisar alterar **nenhuma linha** do `FavoritesController` nem das telas!

---

## Visão Geral do Roteiro de Aula

| Momento | Tempo estimado | O que acontece na aula |
|---|---|---|
| **0. Arquitetura de Pastas da Etapa 2** | 5 min | Visualizamos a evolução da árvore de arquivos com a chegada das pastas `domain/repositories/` e `data/` dentro da feature `favorites`. |
| **1. O Problema (A Dor ao Vivo)** | 10 min | Provocamos a perda dos favoritos no *Hot Restart* e demonstramos no quadro o desastre arquitetural que seria colocar comandos SQL diretamente dentro do `FavoritesController`. |
| **2. O Conceito (Fundamentação Teórica e Técnica)** | 25 min | Fundamentamos o Padrão *Repository*, o Princípio da Inversão de Dependência (DIP), `abstract interface class` no Dart 3, memoização de `Future` (`_loading ??= _load()`), atualização pessimista vs. otimista e segurança de `BuildContext` após `await` (`context.mounted`). |
| **3. A Prática (Refatoração Passo a Passo)** | 30 min | Criamos `FavoritesRepository` e `MemoryFavoritesRepository`, evoluímos o `FavoritesController` para assíncrono e adicionamos estado de carregamento e tratamento de erro com `SnackBar` nas 3 telas. |
| **4. Verificação, Experimentos de Falha e Ponte com o CeliLac** | 15 min | Realizamos 3 experimentos ao vivo (carga inicial, atraso simulado e falha forçada com `failOnChange: true`) e mapeamos cada peça com o código do **CeliLac**. |

---

## 0. Arquitetura de Pastas e Evolução da Etapa 1 para a Etapa 2

Na **Etapa 1**, a funcionalidade `favorites` possuía apenas a camada `presentation/` (pois tudo acontecia de forma síncrona dentro do `FavoritesController`).

Agora, na **Etapa 2**, a feature `favorites` ganha suas três camadas completas (**`domain`**, **`data`** e **`presentation`**), preparando o terreno definitivo para que, na **Etapa 3**, possamos plugar o SQLite sem tocar na interface nem no controlador.

### 0.1 Fundamentação: O que muda na árvore de arquivos?

1. **Intocados da Etapa 1:** `main.dart`, `app_shell.dart`, `establishment.dart`, `sample_establishments.dart`, `favorite_button.dart` e `establishment_card.dart` **não sofrem nenhuma alteração**. Isso prova na prática para a turma o valor do bom desacoplamento feito na aula anterior.
2. **Novos na Etapa 2:**
   - `lib/features/favorites/domain/repositories/favorites_repository.dart` (o contrato abstrato no domínio).
   - `lib/features/favorites/data/memory_favorites_repository.dart` (a implementação assíncrona inicial na camada de dados).
3. **Atualizados na Etapa 2:**
   - `favorites_controller.dart` (passa a receber `FavoritesRepository` e ter métodos `Future`).
   - `lab_app.dart` (injeta o repositório e dispara a carga inicial com `..load()`).
   - `favorites_page.dart`, `home_page.dart` e `establishment_details_page.dart` (tratam o `Future` do `toggle` com `try / catch`, `context.mounted` e `SnackBar`).

### 0.2 Árvore de arquivos ao final desta Etapa 2

```text
lab_favoritos/
├── pubspec.yaml
├── lib/
│   ├── main.dart                                                     ← (Intocado)
│   ├── app/
│   │   ├── lab_app.dart                                              ← ATUALIZADO (Injeta FavoritesRepository + ..load())
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
│       │       │   └── establishment_details_page.dart               ← ATUALIZADO (await toggle + try/catch + SnackBar)
│       │       └── widgets/
│       │           ├── establishment_card.dart                       ← (Intocado)
│       │           └── favorite_button.dart                          ← (Intocado)
│       ├── home/
│       │   └── presentation/
│       │       └── pages/
│       │           └── home_page.dart                                ← ATUALIZADO (await toggle + try/catch + SnackBar)
│       └── favorites/
│           ├── domain/
│           │   └── repositories/
│           │       └── favorites_repository.dart                     ← NOVO (Contrato abstract interface class)
│           ├── data/
│           │   └── memory_favorites_repository.dart                  ← NOVO (Implementação assíncrona + simulador de falhas)
│           └── presentation/
│               ├── favorites_controller.dart                         ← ATUALIZADO (Recebe Repository, load() e toggle() async)
│               └── pages/
│                   └── favorites_page.dart                           ← ATUALIZADO (Exibe loading !isLoaded + try/catch + SnackBar)
```

---

## 1. O Problema (A Dor Provocada ao Vivo)

### 1.1 O Experimento do *Hot Restart* (A Memória Volátil)

Com o projeto exatamente como terminou na Etapa 1:

1. Favorite **Café Aconchego** e **Padaria Trigo Zero** na aba **Início**.
2. Mostre na aba **Favoritos** que os 2 lugares estão salvos e ordenados.
3. No terminal do `flutter run`, pressione **`R`** (maiúsculo, para *Hot Restart*) — ou pare e rode o aplicativo novamente.
4. Volte à aba **Favoritos**: **a lista está completamente vazia!**

*Pergunta para a turma:* "Por que nossos favoritos sumiram?"
Porque as variáveis `_favorites` e `_favoriteIds` do `FavoritesController` estão alocadas na **memória RAM**. Quando o processo do aplicativo reinicia, toda a memória RAM é limpa e o controlador nasce de novo com `const []`.

### 1.2 A Tentação Perigosa: Por que NÃO colocar o código de banco direto no `FavoritesController`?

Neste momento, um aluno inevitavelmente perguntará:
*"Professor, por que não importamos logo o banco de dados dentro do `FavoritesController` e colocamos um `db.insert(...)` dentro do método `toggle`?"*

Desenhe no quadro o que aconteceria se fizéssemos isso:

```text
❌ ACOPLAMENTO DIRETO (Violação de Camadas e do DIP):
┌───────────────────────────────────────────────────────────┐
│ FavoritesController (Camada Presentation)                 │
│  ├── Cuida de notificar a UI (notifyListeners)            │
│  ├── Cuida da estrutura em memória (List + Set)           │
│  └── ❌ Abre arquivo .db, escreve SQL, converte colunas!  │
└───────────────────────────────────────────────────────────┘
```

Isso cria **quatro problemas graves de engenharia**:
1. **Violação do Princípio da Responsabilidade Única (SRP):** O controlador passa a ter dois motivos para mudar — se a regra de atualização da tela mudar **ou** se o nome de uma coluna SQL mudar.
2. **Acoplamento Rígido à Tecnologia:** Se no próximo semestre o produto decidir salvar os favoritos no Supabase (na nuvem) ou no Hive em vez do SQLite, você terá de reescrever o controlador da interface gráfica!
3. **Impossibilidade de Testes Rápidos e Simulação de Erros:** Como testar se a `HomePage` mostra um aviso de erro quando a gravação falha se o `FavoritesController` está soldado a um banco SQLite real?
4. **Mudança de Natureza (Síncrono → Assíncrono):** Na Etapa 1, `toggle()` devolvia `bool` no mesmo microssegundo porque mexia só na RAM. Ler ou gravar em disco ou rede **demora milissegundos** — o processador não pode travar o desenho da tela (*UI Thread*) esperando o disco responder. Portanto, toda operação de persistência no Dart é **assíncrona (`Future`)**.

---

## 2. O Conceito (Fundamentação Teórica e Técnica)

Esta seção fundamenta os cinco pilares teóricos que sustentam a refatoração desta aula.

---

### 2.1 O Padrão de Projeto *Repository* (Domain-Driven Design)

Catalogado por Martin Fowler (*Patterns of Enterprise Application Architecture*, 2002) e popularizado por Eric Evans (*Domain-Driven Design*, 2003), o padrão **Repository (Repositório)** atua como um mediador entre o **Domínio/Apresentação** e a **Camada de Mapeamento de Dados**:

> *"Um Repository medeia entre o domínio e as camadas de mapeamento de dados, agindo como uma coleção de objetos de domínio em memória."* — Martin Fowler

Em termos práticos:
- O `FavoritesController` **não quer saber** o que é uma tabela SQL, um arquivo JSON ou um *endpoint* REST.
- Ele só quer conversar com um objeto que entenda a linguagem do domínio: *"Me dê a `List<Establishment>` salva"*, *"Adicione este `Establishment`"*, *"Remova o favorito de `id` X"*.
- Quem traduz esses pedidos de alto nível para comandos de armazenamento é o **Repositório**.

---

### 2.2 O Princípio da Inversão de Dependência (*DIP* — SOLID) e `abstract interface class` no Dart 3

Se o `FavoritesController` (camada `presentation`) importasse diretamente a classe concreta `SqliteFavoritesRepository` (camada `data`), a camada de apresentação ainda dependeria da camada de dados.

Para cortar esse acoplamento, aplicamos o **Princípio da Inversão de Dependência (*Dependency Inversion Principle* — DIP)**, o **"D"** do acrônimo **SOLID** formulado por Robert C. Martin (*Uncle Bob*):

1. *Módulos de alto nível não devem depender de módulos de baixo nível. Ambos devem depender de abstrações (interfaces).*
2. *Abstrações não devem depender de detalhes. Detalhes (implementações concretas) devem depender de abstrações.*

Veja como as setas de dependência (`import`) se invertem na nossa arquitetura:

```text
Camada PRESENTATION             Camada DOMAIN (Pura)                Camada DATA (Detalhes)
┌──────────────────────┐       ┌───────────────────────────┐       ┌─────────────────────────────┐
│ FavoritesController  │──────►│   «abstract interface»    │◄──────│  MemoryFavoritesRepository  │
│ (ChangeNotifier)     │  usa  │    FavoritesRepository    │ imple-│  (Etapa 2: RAM + Simulação) │
└──────────────────────┘       ├───────────────────────────┤ menta ├─────────────────────────────┤
                               │ + loadAll()               │       │  SqliteFavoritesRepository  │
                               │ + isFavorite(id)          │◄──────│  (Etapa 3: Banco SQLite)    │
                               │ + add(establishment)      │ imple-└─────────────────────────────┘
                               │ + remove(id)              │ menta
                               └───────────────────────────┘
```

- Repare na direção das setas apontando para o centro (**`domain`**):
  - O `FavoritesController` importa **apenas** `favorites_repository.dart`. Ele nem sabe que `MemoryFavoritesRepository` ou `SqliteFavoritesRepository` existem!
  - As classes da camada `data` importam `favorites_repository.dart` e assinam o contrato usando a palavra-chave **`implements`**.

#### Por que usamos `abstract interface class` no Dart 3?

No Dart moderno (a partir do Dart 3.0), os **modificadores de classe** permitem expressar com precisão matemática a intenção arquitetural de um tipo:

| Declaração no Dart 3 | Pode ser instanciada (`new`)? | Outra biblioteca pode dar `extends` (herdar)? | Outra biblioteca pode dar `implements` (assinar contrato)? |
|---|---|---|---|
| `class A` | Sim | Sim | Sim |
| `abstract class A` | **Não** | Sim | Sim |
| **`abstract interface class A`** | **Não** | **Não** | **Sim (Apenas contrato puro!)** |

Ao declararmos `abstract interface class FavoritesRepository`, o compilador do Dart garante que ninguém conseguirá instanciar `FavoritesRepository()` diretamente nem usar herança de implementação (`extends`) — obrigando qualquer repositório concreto a usar **`implements FavoritesRepository`** e implementar obrigatoriamente todos os 4 métodos do contrato!

---

### 2.3 Programação Assíncrona no Dart: `Future<T>`, `async`/`await` e Idempotência de Carga (`_loading ??= _load()`)

#### 1. Por que `Future<List<Establishment>>` e `Future<void>`?
O Flutter desenha a tela em uma única *thread* de execução (*UI Isolate*), atualizando os quadros a 60 Hz (a cada $16{,}6\text{ ms}$) ou 120 Hz ($8{,}3\text{ ms}$). Se uma leitura de disco demorar $50\text{ ms}$ e o código ficar parado esperando de forma síncrona, o aplicativo perderá 3 quadros seguidos, causando travamentos visuais (*jank* / congelamento da tela).

Por isso, todo método do `FavoritesRepository` devolve um **`Future<T>`** (uma "promessa" de um valor que ficará pronto no futuro):
- Enquanto o sistema operacional busca os dados no armazenamento em segundo plano, o *Event Loop* do Dart continua livre para processar toques e animações na tela.
- Quando os dados chegam, a execução retoma exatamente após a palavra-chave **`await`**.

#### 2. O Padrão de Memoização da Carga Inicial: `Future<void> load() => _loading ??= _load();`

Dentro do `FavoritesController`, precisamos de um método `load()` para buscar os favoritos salvos assim que o aplicativo abre. Veja como o implementamos no CeliLac:

```dart
bool _isLoaded = false;
Future<void>? _loading;

bool get isLoaded => _isLoaded;

Future<void> load() => _loading ??= _load();
```

**Por que guardar o `Future<void>? _loading` e usar o operador `??=` (*null-aware assignment*)?**
- Imagine que dois lugares do aplicativo (por exemplo, a inicialização do app e uma aba) chamem `controller.load()` quase no mesmo instante.
- Se `load()` simplesmente chamasse `_load()` toda vez, dispararíamos **duas leituras concorrentes e desnecessárias no banco de dados**!
- Com `_loading ??= _load()`:
  1. Na **primeira chamada**, `_loading` é `null`. O operador `??=` executa `_load()`, guarda o `Future` criado dentro de `_loading` e o devolve.
  2. Se uma **segunda chamada** a `load()` acontecer antes ou depois, `_loading` **não é mais `null`**! O operador `??=` não executa `_load()` de novo — ele simplesmente devolve o **mesmo `Future`** da primeira chamada (tornando o método **idempotente**).

#### 3. Por que `load()` captura erros internamente e sempre marca `_isLoaded = true`?

Observe o corpo de `_load()`:

```dart
Future<void> _load() async {
  try {
    final loaded = await _repository.loadAll();
    _setFavorites(loaded);
  } on Object catch (error) {
    // Os favoritos não podem impedir que o app abra.
    debugPrint('Não foi possível carregar os favoritos: $error');
  }
  _isLoaded = true;
  notifyListeners();
}
```

Esta é uma decisão de **Degradação Graciosa (*Graceful Degradation*)**:
- Se o carregamento dos favoritos falhar na abertura do aplicativo, **o aplicativo não pode travar em uma tela de carregamento infinita nem fechar na cara do usuário**.
- Capturamos o erro no `catch`, registramos no console de desenvolvimento (`debugPrint`), mantemos a lista vazia (`const []`), marcamos `_isLoaded = true` e chamamos `notifyListeners()`. Assim, a tela sai do `CircularProgressIndicator` e o usuário continua podendo usar o catálogo normalmente!

---

### 2.4 Atualização Pessimista vs. Otimista: Por que gravar no Repositório ANTES de atualizar a memória e chamar `notifyListeners()`?

Ao implementar o método `Future<bool> toggle(Establishment establishment) async` no `FavoritesController`, surge uma dúvida fundamental sobre a **ordem das linhas**:

**Devemos atualizar a lista em memória antes ou depois do `await _repository.add(...)`?**

Compare os dois cenários quando ocorre uma falha na gravação:

```text
❌ ABORDAGEM INGÊNUA (Atualiza a memória ANTES do await):
Usuário toca no ♡ ──► 1. Adiciona na _favorites e chama notifyListeners()
                      2. Tela pinta o coração de VERMELHO (salvo!)
                      3. await _repository.add(...) ──► 💥 LANÇA EXCEÇÃO!
                      Resultado: O banco NÃO salvou, mas a tela está MENTINDO
                      com o coração vermelho! (Estado corrompido)

✅ NOSSA ABORDAGEM SEGURA (Aguarda o repositório ANTES de mudar a memória):
Usuário toca no ♡ ──► 1. await _repository.add(...)
                         ├── Se der CERTO:
                         │     2. Atualiza _favorites e _favoriteIds
                         │     3. Chama notifyListeners() (Coração fica vermelho!)
                         └── Se LANÇAR EXCEÇÃO:
                               2. Pula direto para o catch da tela!
                               3. _favorites e _favoriteIds continuam INTOCADOS!
                               4. Tela mostra SnackBar de erro e coração continua vazio!
```

Ao executarmos **`await _repository.add(establishment)`** (ou `remove`) **na primeira linha** antes de tocar em `_favorites` e `_favoriteIds`:
1. Se a persistência falhar, a execução do `toggle` é interrompida imediatamente na linha do `await` e lança a exceção para quem chamou (a página).
2. As variáveis em memória `_favorites` e `_favoriteIds` **não são alteradas** e `notifyListeners()` **não é chamado**.
3. A interface gráfica **nunca mente para o usuário**: o coração na tela reflete com 100% de fidelidade o que está efetivamente persistido!

---

### 2.5 Tratamento de Erros na UI: `try / catch`, o perigo do `BuildContext` após `await` (`context.mounted`) e `SnackBar`

Quando o usuário toca no coração e o `await controller.toggle(establishment)` lança uma exceção, quem deve avisar o usuário?
- **Não é o `FavoritesController`!** Lembre-se de que o controlador só importa `flutter/foundation.dart`; ele não conhece `ScaffoldMessenger` nem `SnackBar`.
- Quem captura a exceção e exibe o feedback visual é a **Página (`HomePage`, `FavoritesPage`, `EstablishmentDetailsPage`)**!

Veja o padrão seguro utilizado nas nossas páginas:

```dart
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
```

Vamos dissecar **quatro detalhes técnicos** presentes nessas poucas linhas:

1. **Por que `on Object` em vez de `catch (_)` solto?**
   - Em Dart, todas as classes (tanto `Exception` quanto `Error`) herdam de `Object`. Usar `on Object` (ou `on Object catch (error)`) é a prática recomendada pelo linter oficial do Dart para deixar explícito que queremos capturar qualquer falha lançada pela camada inferior.
2. **Por que `if (!context.mounted) return;` (ou `if (!mounted) return;` em `StatefulWidget`) é obrigatório após um `await`?**
   - Enquanto o aplicativo está parado na linha `await ...toggle(establishment)` esperando o banco responder, o usuário pode tocar no botão "Voltar" e **fechar aquela tela**!
   - Se a tela foi fechada durante o `await`, o `Element` (`context`) daquela página foi **desmontado da árvore** (`mounted == false`).
   - Tentar chamar `ScaffoldMessenger.of(context)` usando um `context` desmontado causa um erro fatal no Flutter (*"Looking up a deactivated widget's ancestor is unsafe"*).
   - A guarda `if (!context.mounted) return;` verifica se o widget ainda está vivo na tela antes de usar o `context` após qualquer lacuna assíncrona (*async gap*).
3. **Por que usar `..hideCurrentSnackBar()..showSnackBar(...)` (*Cascade Notation*)?**
   - O `ScaffoldMessenger` gerencia uma **fila** de `SnackBar`s. Se o usuário tocar 5 vezes seguidas no botão de coração enquanto a gravação está falhando, chamar apenas `.showSnackBar(...)` enfileiraria 5 avisos de 4 segundos cada (o app ficaria 20 segundos mostrando barras de erro depois que o usuário já parou de clicar!).
   - Ao encadear `..hideCurrentSnackBar()` antes de `..showSnackBar(...)`, descartamos imediatamente qualquer aviso anterior e exibimos apenas o mais recente.

---

## 3. A Prática (Refatoração Passo a Passo por Arquivo)

Vamos evoluir o projeto `lab_favoritos` da Etapa 1 para a Etapa 2. Não precisamos instalar nenhum pacote novo no `pubspec.yaml` nesta etapa — usaremos apenas recursos nativos do Dart e o `provider` já instalado na Etapa 1.

---

### Passo 3.1 — Criar o contrato `FavoritesRepository` (`lib/features/favorites/domain/repositories/favorites_repository.dart`)

**O que este arquivo propõe e resolve:**
Propõe o contrato formal de persistência de favoritos na camada de domínio (`domain`). Ele resolve o acoplamento entre o controlador de estado (`FavoritesController`) e a tecnologia de armazenamento: ao definir apenas as assinaturas assíncronas (`loadAll`, `isFavorite`, `add`, `remove`), permite que o aplicativo funcione hoje com um repositório em memória e, na Etapa 3, com um banco SQLite real sem alterar uma única linha da camada de apresentação.

**Papel Arquitetural (`features/favorites/domain/repositories`):**
Fica na camada **`domain`** da funcionalidade `favorites`. Repare que seu único `import` é a entidade `Establishment` (que também pertence ao `domain`). Ele não importa `flutter`, `provider` nem `sqflite`. É uma fronteira arquitetural pura.

**Fundamentação dos recursos utilizados no código:**
- **`abstract interface class`:** Modificador do Dart 3 que define um contrato puro. Classes externas não podem instanciá-lo nem herdá-lo com `extends`, apenas implementá-lo com `implements`.
- **Assinaturas baseadas em `Future<T>`:** Mesmo que uma implementação de teste em memória pudesse responder instantaneamente, o contrato declara `Future<List<Establishment>>`, `Future<bool>` e `Future<void>` porque implementações reais de E/S (SQLite, arquivos, API REST) são intrinsecamente assíncronas.
- **Parâmetro nomeado opcional `{DateTime? savedAt}` no método `add`:** Em produção, a interface chama apenas `repository.add(establishment)`, deixando o repositório registrar `DateTime.now()`. Porém, expor `{DateTime? savedAt}` no contrato permite que testes automatizados (e as etapas futuras de ordenação no SQLite) injetem carimbos de tempo exatos e determinísticos sem depender do relógio físico da máquina!

Crie o arquivo `lib/features/favorites/domain/repositories/favorites_repository.dart`:

```dart
import '../../../establishments/domain/entities/establishment.dart';

abstract interface class FavoritesRepository {
  Future<List<Establishment>> loadAll();

  Future<bool> isFavorite(String establishmentId);

  Future<void> add(Establishment establishment, {DateTime? savedAt});

  Future<void> remove(String establishmentId);
}
```

---

### Passo 3.2 — Criar o `MemoryFavoritesRepository` (`lib/features/favorites/data/memory_favorites_repository.dart`)

**O que este arquivo propõe e resolve:**
Propõe uma implementação concreta e assíncrona do contrato `FavoritesRepository` que armazena os dados em memória e permite simular cenários de mundo real (dados pré-cadastrados, atraso de leitura/gravação e falhas de I/O). Ele resolve dois problemas pedagógicos e de engenharia: permite validar todo o fluxo assíncrono do controlador antes de introduzir o SQLite e oferece chaves de simulação (`failOnLoad`, `failOnChange`, `simulatedDelay`) para testarmos visualmente na aula o indicador de carregamento e a barra de erro (`SnackBar`).

**Papel Arquitetural (`features/favorites/data`):**
Pertence à camada **`data`** (no CeliLac final, quando o `SqliteFavoritesRepository` assume a produção na Etapa 3, esta mesma classe passa a morar em `test/support/memory_favorites_repository.dart` para alimentar toda a suíte de testes automatizados sem depender de disco!).

**Fundamentação dos recursos utilizados no código:**
- **`implements FavoritesRepository`:** Obriga a classe a fornecer implementações concretas para os 4 métodos definidos na interface do domínio.
- **Cópia defensiva na entrada e na saída (`List.of(_stored)` e `List.unmodifiable`):**
  - No construtor, `: _stored = List.of(stored)` cria uma lista mutável interna própria a partir da lista inicial recebida.
  - No método `loadAll()`, devolvemos `List.of(_stored)` (uma cópia fresca) para que nenhuma mutação externa afete o armazenamento interno do repositório.
- **Contadores de inspeção (`loadCalls`, `addCalls`, `removeCalls`):** Permitem verificar (em testes ou no *debugger*) quantas vezes exatamente o controlador acionou o repositório — por exemplo, provando que `load()` só consulta o repositório uma única vez mesmo se for chamado repetidamente.
- **Simuladores de falha (`failOnLoad` e `failOnChange`) e latência (`simulatedDelay`):**
  - Se `simulatedDelay > Duration.zero`, aguardamos `await Future<void>.delayed(simulatedDelay)` antes de responder, simulando um disco lento ou uma rede móvel.
  - Se `failOnChange == true`, os métodos `add` e `remove` lançam `Exception('falha ao salvar/remover favorito')`, simulando um disco cheio ou banco corrompido.

Crie o arquivo `lib/features/favorites/data/memory_favorites_repository.dart`:

```dart
import '../../establishments/domain/entities/establishment.dart';
import '../domain/repositories/favorites_repository.dart';

class MemoryFavoritesRepository implements FavoritesRepository {
  MemoryFavoritesRepository({
    List<Establishment> stored = const [],
    this.failOnLoad = false,
    this.failOnChange = false,
    this.simulatedDelay = Duration.zero,
  }) : _stored = List.of(stored);

  final List<Establishment> _stored;
  bool failOnLoad;
  bool failOnChange;
  final Duration simulatedDelay;

  int loadCalls = 0;
  int addCalls = 0;
  int removeCalls = 0;

  List<Establishment> get stored => List.unmodifiable(_stored);

  @override
  Future<List<Establishment>> loadAll() async {
    loadCalls++;
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    if (failOnLoad) {
      throw Exception('falha ao ler favoritos');
    }
    return List.of(_stored);
  }

  @override
  Future<bool> isFavorite(String establishmentId) async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    return _stored.any((item) => item.id == establishmentId);
  }

  @override
  Future<void> add(Establishment establishment, {DateTime? savedAt}) async {
    addCalls++;
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    if (failOnChange) {
      throw Exception('falha ao salvar favorito');
    }
    _stored.removeWhere((item) => item.id == establishment.id);
    _stored.insert(0, establishment);
  }

  @override
  Future<void> remove(String establishmentId) async {
    removeCalls++;
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    if (failOnChange) {
      throw Exception('falha ao remover favorito');
    }
    _stored.removeWhere((item) => item.id == establishmentId);
  }
}
```

---

### Passo 3.3 — Evoluir o `FavoritesController` para operar com `FavoritesRepository` (`lib/features/favorites/presentation/favorites_controller.dart`)

**O que este arquivo propõe e resolve:**
Propõe a evolução do `FavoritesController` para uma arquitetura assíncrona desacoplada por Injeção de Dependência. Ele resolve três necessidades críticas:
1. Recebe qualquer implementação de `FavoritesRepository` pelo construtor;
2. Gerencia o ciclo de carregamento inicial (`load()` e `isLoaded`) com proteção contra chamadas duplicadas (`_loading ??= _load()`);
3. Garante integridade transacional na UI ao aguardar (`await`) a confirmação do repositório **antes** de atualizar a lista em memória e disparar `notifyListeners()`.

**Papel Arquitetural (`features/favorites/presentation`):**
Continua sendo o único `ChangeNotifier` da funcionalidade `favorites`, mas agora delega toda a persistência ao contrato `FavoritesRepository` (camada `domain`), mantendo em memória RAM (`_favorites` e `_favoriteIds`) um espelho rápido para que o método `build` das telas continue consultando `isFavorite(id)` de forma síncrona e em tempo constante $O(1)$!

> **Destaque Pedagógico Importante:** Pergunte aos alunos: *"Se o repositório tem `Future<bool> isFavorite(id)` assíncrono, por que o `FavoritesController.isFavorite(id)` continua sendo `bool` síncrono?"*
> Porque o método `build` do Flutter é síncrono e roda a até 120 quadros por segundo! Seria inviável colocar um `FutureBuilder` dentro de cada botão de coração da lista. Por isso, o controlador carrega a lista uma vez no `load()`, sincroniza o `Set<String> _favoriteIds` em memória e responde `isFavorite(id)` instantaneamente em $O(1)$ durante o `build`!

**Fundamentação dos recursos utilizados no código:**
- **Injeção de Dependência via Construtor (`FavoritesController(this._repository)`):** O controlador não faz `FavoritesRepository()` nem `MemoryFavoritesRepository()`. Ele exige que quem o cria entregue um `FavoritesRepository` pronto.
- **Método auxiliar privado `_setFavorites(List<Establishment> items)`:** Centraliza a atualização simultânea da `List.unmodifiable(items)` e do `Set` `{for (final item in items) item.id}`, garantindo que as duas estruturas jamais fiquem dessincronizadas entre si.
- **Ordem estrita no `toggle`:** Primeiro `await _repository.remove(...)` (ou `add`), depois `_setFavorites(...)`, depois `notifyListeners()`.

Atualize o arquivo `lib/features/favorites/presentation/favorites_controller.dart`:

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

  /// Inicia o carregamento dos favoritos a partir do repositório.
  /// Se já houver um carregamento em andamento ou concluído, devolve o mesmo Future.
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final loaded = await _repository.loadAll();
      _setFavorites(loaded);
    } on Object catch (error) {
      // Os favoritos não podem impedir que o app abra.
      debugPrint('Não foi possível carregar os favoritos: $error');
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Alterna o estado de favorito de [establishment].
  ///
  /// Aguarda a persistência no [_repository] ANTES de atualizar a memória e
  /// notificar os ouvintes. Devolve `true` se foi salvo, ou `false` se removido.
  Future<bool> toggle(Establishment establishment) async {
    if (isFavorite(establishment.id)) {
      // 1. Primeiro persiste no repositório (se falhar, lança exceção aqui!):
      await _repository.remove(establishment.id);

      // 2. Só depois do sucesso atualiza a memória e avisa as telas:
      _setFavorites([
        for (final item in _favorites)
          if (item.id != establishment.id) item,
      ]);
      _isLoaded = true;
      notifyListeners();
      return false;
    } else {
      // 1. Primeiro persiste no repositório (se falhar, lança exceção aqui!):
      await _repository.add(establishment);

      // 2. Só depois do sucesso atualiza a memória e avisa as telas:
      _setFavorites([
        establishment,
        for (final item in _favorites)
          if (item.id != establishment.id) item,
      ]);
      _isLoaded = true;
      notifyListeners();
      return true;
    }
  }

  void _setFavorites(List<Establishment> items) {
    _favorites = List.unmodifiable(items);
    _favoriteIds = {for (final item in items) item.id};
  }
}
```

---

### Passo 3.4 — Injetar o `FavoritesRepository` e disparar `..load()` em `LabApp` (`lib/app/lab_app.dart`)

**O que este arquivo propõe e resolve:**
Propõe a composição das dependências (*Composition Root*) no topo do aplicativo. Ele resolve onde a implementação concreta do repositório (`MemoryFavoritesRepository`) é escolhida e entregue ao `FavoritesController`, além de disparar imediatamente o carregamento inicial dos dados (`..load()`) no momento da criação do controlador.

**Papel Arquitetural (`lib/app/lab_app.dart`):**
Em uma arquitetura limpa com Injeção de Dependência, as camadas internas não sabem qual implementação concreta está sendo usada. O widget raiz da aplicação (`LabApp`, equivalente ao `CeliLacApp`) atua como a **Raiz de Composição (*Composition Root*)**: é o único lugar do aplicativo que conhece tanto o `FavoritesController` quanto a classe concreta `MemoryFavoritesRepository` (e, na Etapa 3, o `SqliteFavoritesRepository`).

**Fundamentação dos recursos utilizados no código:**
- **Parâmetro opcional `final FavoritesRepository? favoritesRepository`:** Assim como no `CeliLacApp`, permitir que `LabApp` receba um `favoritesRepository` opcional pelo construtor (`favoritesRepository ?? MemoryFavoritesRepository()`) permite que testes de widget injetem um repositório pré-configurado de fora, enquanto o `main.dart` continua chamando apenas `const LabApp()`.
- **Operador de Cascata (`..load()`) no `create`:**
  - Na expressão `FavoritesController(...)..load()`, o operador `..` (*cascade notation*) chama o método `.load()` na instância recém-criada do controlador, mas **devolve a própria instância do `FavoritesController`** (e não o `Future<void>` retornado por `load()`) para o `ChangeNotifierProvider`!
- **`lazy: false` no `ChangeNotifierProvider`:** Por padrão, o `ChangeNotifierProvider` só executa o `create` quando o primeiro widget chama `watch` ou `read`. Definir `lazy: false` garante que o `load()` comece imediatamente assim que o aplicativo inicia, mesmo antes de o usuário abrir a aba de Favoritos (na Etapa 6, veremos como o CeliLac faz essa carga paralela durante a animação da `SplashPage`).

Atualize o arquivo `lib/app/lab_app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/favorites/data/memory_favorites_repository.dart';
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
    return ChangeNotifierProvider<FavoritesController>(
      lazy: false,
      create: (_) => FavoritesController(
        favoritesRepository ?? MemoryFavoritesRepository(),
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

### Passo 3.5 — Tratar carregamento (`!isLoaded`) e falhas (`SnackBar`) na `FavoritesPage` (`lib/features/favorites/presentation/pages/favorites_page.dart`)

**O que este arquivo propõe e resolve:**
Propõe a evolução da aba **Favoritos** para contemplar os **três estados visuais de uma coleção assíncrona** (Carregando, Vazio e Populado) e tratar eventuais falhas ao desfavoritar um item. Ele resolve o problema de mostrar um "falso estado vazio" enquanto o banco ainda está sendo lido (`!favoritesController.isLoaded`) e evita falhas silenciosas ao exibir um `SnackBar` caso a remoção no repositório lance uma exceção.

**Papel Arquitetural (`features/favorites/presentation/pages`):**
É a página de apresentação da aba Favoritos, agora consciente do ciclo de vida assíncrono do `FavoritesController`.

**Fundamentação dos recursos utilizados no código:**
- **Árvore de decisão de 3 estados no `body`:**
  1. `!favoritesController.isLoaded` → exibe `const Center(child: CircularProgressIndicator())` enquanto `load()` ainda não concluiu.
  2. `favorites.isEmpty` → só exibe a mensagem *"Você ainda não salvou nenhum estabelecimento"* quando temos certeza de que o carregamento já terminou (`isLoaded == true`) e a lista realmente veio vazia!
  3. Caso contrário → exibe a `ListView` com a contagem e os cartões.
- **Método assíncrono `_toggleFavorite(BuildContext context, Establishment establishment)`:**
  - Envolve `await context.read<FavoritesController>().toggle(establishment)` em um bloco `try / on Object`.
  - Verifica `if (!context.mounted) return;` após o `await` antes de acessar o `ScaffoldMessenger.of(context)`.

Atualize o arquivo `lib/features/favorites/presentation/pages/favorites_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../establishments/domain/entities/establishment.dart';
import '../../../establishments/presentation/pages/establishment_details_page.dart';
import '../../../establishments/presentation/widgets/establishment_card.dart';
import '../favorites_controller.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key, this.onExploreTap});

  final VoidCallback? onExploreTap;

  void _openDetails(BuildContext context, Establishment establishment) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EstablishmentDetailsPage(establishment: establishment),
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
    final favorites = favoritesController.favorites;

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: !favoritesController.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : favorites.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_border, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Você ainda não salvou nenhum estabelecimento.\n'
                      'Toque no coração em um lugar para encontrá-lo rápido aqui.',
                      textAlign: TextAlign.center,
                    ),
                    if (onExploreTap != null) ...[
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: onExploreTap,
                        child: const Text('Ver estabelecimentos'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    favorites.length == 1
                        ? '1 lugar salvo'
                        : '${favorites.length} lugares salvos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                for (final establishment in favorites)
                  EstablishmentCard(
                    establishment: establishment,
                    isFavorite: true,
                    onFavoriteToggle: () =>
                        _toggleFavorite(context, establishment),
                    onTap: () => _openDetails(context, establishment),
                  ),
              ],
            ),
    );
  }
}
```

---

### Passo 3.6 — Tratar o `toggle` assíncrono e falhas (`SnackBar`) na `HomePage` (`lib/features/home/presentation/pages/home_page.dart`)

**O que este arquivo propõe e resolve:**
Propõe a adição do tratamento de falhas assíncronas ao favoritar ou desfavoritar um estabelecimento diretamente nos cartões da aba **Início**. Ele resolve o risco de exceções não tratadas (*Unhandled Exception*) quando o repositório falha, exibindo um `SnackBar` informativo e mantendo o ícone do cartão intacto.

**Papel Arquitetural (`features/home/presentation/pages`):**
Como página orquestradora da aba **Início**, a `HomePage` é quem fornece o callback `onFavoriteToggle` para cada `EstablishmentCard` e, portanto, é responsável por capturar qualquer erro lançado pelo `FavoritesController.toggle(...)`.

**Fundamentação dos recursos utilizados no código:**
- **Extração do método `_toggleFavorite(BuildContext context, Establishment establishment)`:** Em vez de deixar um bloco `try / catch` dentro do `itemBuilder` da `ListView`, extraímos um método dedicado e limpo que realiza o `await context.read<FavoritesController>().toggle(establishment)`, checa `if (!context.mounted) return;` e aciona o `ScaffoldMessenger`.

Atualize o arquivo `lib/features/home/presentation/pages/home_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../establishments/data/sample_establishments.dart';
import '../../../establishments/domain/entities/establishment.dart';
import '../../../establishments/presentation/pages/establishment_details_page.dart';
import '../../../establishments/presentation/widgets/establishment_card.dart';
import '../../../favorites/presentation/favorites_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openDetails(BuildContext context, Establishment establishment) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EstablishmentDetailsPage(establishment: establishment),
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
    final favorites = context.watch<FavoritesController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Estabelecimentos')),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sampleEstablishments.length,
        itemBuilder: (context, index) {
          final establishment = sampleEstablishments[index];

          return EstablishmentCard(
            establishment: establishment,
            isFavorite: favorites.isFavorite(establishment.id),
            onFavoriteToggle: () => _toggleFavorite(context, establishment),
            onTap: () => _openDetails(context, establishment),
          );
        },
      ),
    );
  }
}
```

---

### Passo 3.7 — Tratar o `toggle` assíncrono e falhas (`SnackBar`) na `EstablishmentDetailsPage` (`lib/features/establishments/presentation/pages/establishment_details_page.dart`)

**O que este arquivo propõe e resolve:**
Propõe o mesmo tratamento seguro de assincronia e erro para o botão de coração localizado na `AppBar` da tela de detalhes. Ele resolve o cenário crítico em que o usuário toca no coração da `AppBar` e pode fechar a rota imediatamente em seguida: caso ocorra uma falha no repositório, `context.mounted` evita tentar exibir um `SnackBar` em uma rota que já saiu da pilha do `Navigator`.

**Papel Arquitetural (`features/establishments/presentation/pages`):**
É a rota empilhada de detalhes do estabelecimento, mantendo consistência de feedback visual (`SnackBar`) com as demais telas do aplicativo.

**Fundamentação dos recursos utilizados no código:**
- **Consistência de UX em todas as telas:** O usuário recebe exatamente o mesmo comportamento e a mesma mensagem (`'Não foi possível atualizar os favoritos.'`) quer tente favoritar pela `HomePage`, pela `FavoritesPage` ou pela `EstablishmentDetailsPage`.

Atualize o arquivo `lib/features/establishments/presentation/pages/establishment_details_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../favorites/presentation/favorites_controller.dart';
import '../../domain/entities/establishment.dart';
import '../widgets/favorite_button.dart';

class EstablishmentDetailsPage extends StatelessWidget {
  const EstablishmentDetailsPage({
    super.key,
    required this.establishment,
  });

  final Establishment establishment;

  Future<void> _toggleFavorite(BuildContext context) async {
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
    final isFavorite = context
        .watch<FavoritesController>()
        .isFavorite(establishment.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(establishment.name),
        actions: [
          FavoriteButton(
            establishmentName: establishment.name,
            isFavorite: isFavorite,
            onPressed: () => _toggleFavorite(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                establishment.name,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('${establishment.category} · ${establishment.neighborhood}'),
              const SizedBox(height: 4),
              Text('Nota: ★ ${establishment.rating}'),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 4. Verificação, Experimentos Controlados de Falha e Ponte com o CeliLac

Esta é a melhor parte da aula: graças ao `MemoryFavoritesRepository`, podemos demonstrar ao vivo para os alunos **3 comportamentos assíncronos** que seriam quase impossíveis de enxergar a olho nu se tivéssemos ido direto para o SQLite!

### 4.1 Roteiro de Verificação ao Vivo na Tela (3 Experimentos Práticos)

#### Experimento 1 — Simulando Favoritos Pré-Salvos e Lentidão de Leitura (`CircularProgressIndicator`)
1. Abra `lib/app/lab_app.dart`, importe `sample_establishments.dart` temporariamente e passe um atraso de 2 segundos com 1 item já salvo no `MemoryFavoritesRepository`:
   ```dart
   create: (_) => FavoritesController(
     favoritesRepository ??
         MemoryFavoritesRepository(
           stored: [sampleEstablishments.first],
           simulatedDelay: const Duration(seconds: 2),
         ),
   )..load(),
   ```
2. Faça um **Hot Restart** (`R`) e clique imediatamente na aba **Favoritos**.
3. **O que a turma vê na tela:**
   - Durante 2 segundos, a aba Favoritos exibe o **`CircularProgressIndicator`** centralizado (porque `isLoaded` ainda é `false` — ela **não** mente dizendo que a lista está vazia!).
   - Assim que os 2 segundos terminam, `_load()` chama `notifyListeners()`, o `CircularProgressIndicator` desaparece sozinho e o **Café Aconchego** já surge salvo tanto na aba Favoritos quanto com o coração vermelho na aba Início!

#### Experimento 2 — Provocando uma Falha de Gravação (`failOnChange: true`) e provando que a UI NÃO mente!
1. Ainda em `lib/app/lab_app.dart`, configure o repositório para falhar ao alterar:
   ```dart
   create: (_) => FavoritesController(
     favoritesRepository ??
         MemoryFavoritesRepository(
           failOnChange: true,
         ),
   )..load(),
   ```
2. Faça um **Hot Restart** (`R`).
3. Na aba **Início**, toque no coração do **Café Aconchego**.
4. **O que a turma vê na tela:**
   - O coração **NÃO fica vermelho**! Como fizemos `await _repository.add(...)` **antes** de atualizar `_favorites` e `_favoriteIds`, a exceção interrompeu o método `toggle` antes da mutação em memória.
   - Imediatamente sobe na base da tela o **`SnackBar`** dizendo: *"Não foi possível atualizar os favoritos."*
   - Abra a `EstablishmentDetailsPage` e toque no coração da `AppBar`: o mesmo `SnackBar` aparece e o coração continua vazio!

#### Experimento 3 — Retornando ao modo normal
1. Volte o `LabApp` para a configuração limpa:
   ```dart
   create: (_) => FavoritesController(
     favoritesRepository ?? MemoryFavoritesRepository(),
   )..load(),
   ```
2. Faça um **Hot Restart** (`R`) e confirme que favoritar e desfavoritar funcionam instantaneamente nas 3 telas.

---

### 4.2 Ponte Direta com o CeliLac

Veja como cada arquivo trabalhado nesta **Etapa 2** corresponde exatamente à arquitetura final do **CeliLac**:

| Arquivo no `lab_favoritos` (Etapa 2) | Arquivo correspondente no **CeliLac** | Papel na Arquitetura |
|---|---|---|
| `lib/features/favorites/domain/repositories/favorites_repository.dart` | [`lib/features/favorites/domain/repositories/favorites_repository.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/favorites/domain/repositories/favorites_repository.dart) | Contrato `abstract interface class` na camada `domain` (100% idêntico!). |
| `lib/features/favorites/data/memory_favorites_repository.dart` | [`test/support/memory_favorites_repository.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/test/support/memory_favorites_repository.dart) | Implementação em memória com `failOnLoad` e `failOnChange` usada nos testes do CeliLac ([`favorites_controller_test.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/test/features/favorites/favorites_controller_test.dart)). |
| `lib/features/favorites/presentation/favorites_controller.dart` | [`lib/features/favorites/presentation/favorites_controller.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/favorites/presentation/favorites_controller.dart) | Controlador assíncrono com `_isLoaded`, `_loading ??= _load()` e `await` antes de `notifyListeners()` (100% idêntico!). |
| `lib/app/lab_app.dart` | [`lib/app/celilac_app.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/app/celilac_app.dart) | Raiz de composição que injeta o `FavoritesRepository` no `FavoritesController`. |
| `lib/features/favorites/presentation/pages/favorites_page.dart` | [`lib/features/favorites/presentation/pages/favorites_page.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/favorites/presentation/pages/favorites_page.dart) | Exibe `CircularProgressIndicator` enquanto `!isLoaded` e trata falha do `toggle` com `SnackBar`. |
| `lib/features/home/presentation/pages/home_page.dart` | [`lib/features/home/presentation/pages/home_page.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/home/presentation/pages/home_page.dart) | Método `_toggleFavorite` com `try / on Object`, `mounted` e `SnackBar`. |
| `lib/features/establishments/presentation/pages/establishment_details_page.dart` | [`lib/features/establishments/presentation/pages/establishment_details_page.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/establishments/presentation/pages/establishment_details_page.dart) | Método `_toggleFavorite` na `AppBar` com `try / on Object`, `mounted` e `SnackBar`. |

---

### 4.3 Gancho para a Etapa 3 (A Beleza da Inversão de Dependência)

Feche a aula mostrando o arquivo `lib/app/lab_app.dart` no projetor e faça a seguinte reflexão com a turma:

1. **O que já está 100% pronto?**
   - O contrato `FavoritesRepository` está pronto.
   - O `FavoritesController` assíncrono está 100% na sua versão final.
   - A `HomePage`, a `FavoritesPage` e a `EstablishmentDetailsPage` já sabem lidar com carregamento assíncrono e erros de gravação.
2. **O que falta para os favoritos sobreviverem quando o usuário desligar o celular?**
   - Hoje, em `LabApp`, estamos passando `MemoryFavoritesRepository()`.
   - Na próxima aula (**Etapa 3**), criaremos a classe **`SqliteFavoritesRepository implements FavoritesRepository`** salvando os dados em uma tabela real do **SQLite (`sqflite`)** no disco do aparelho!
   - E quantas linhas do `FavoritesController`, da `HomePage`, da `FavoritesPage` ou da `EstablishmentDetailsPage` precisaremos alterar na Etapa 3 para o banco SQLite funcionar? **ZERO linhas!** Bastará trocar `MemoryFavoritesRepository()` por `SqliteFavoritesRepository()` no `LabApp`!

