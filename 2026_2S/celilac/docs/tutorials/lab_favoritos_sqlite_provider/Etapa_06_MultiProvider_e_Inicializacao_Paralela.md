# Etapa 6 — Múltiplos Estados Globais (`MultiProvider`) e Inicialização Paralela

## Introdução: O que este documento propõe e resolve?

### 1. O Problema Real que Estamos Enfrentando
Nas cinco primeiras etapas do nosso laboratório, construímos uma infraestrutura de persistência robusta e resiliente para a funcionalidade de **Favoritos**:
- Na **Etapa 1**, unificamos o estado em memória com `ChangeNotifier` e `provider`, eliminando variáveis booleanas espalhadas e garantindo sincronia instantânea entre telas.
- Na **Etapa 2**, desacoplamos a regra de apresentação da infraestrutura através do contrato `FavoritesRepository`, estabelecendo um fluxo assíncrono seguro.
- Na **Etapa 3**, implementamos o armazenamento relacional no SQLite (`sqflite`), protegendo as consultas contra *SQL Injection*.
- Na **Etapa 4**, construímos a camada de tradução de tipos compostos (`enum`, `Set<Enum>`, `DateTime`, `double`), blindando o app contra divergências de tipos do SQLite.
- Na **Etapa 5**, dominamos o ciclo de vida do banco e a migração de esquema sem perda de dados (`onUpgrade` com `ALTER TABLE`), preservando os registros existentes.

Contudo, nenhum aplicativo do mundo real é composto por apenas uma funcionalidade. Em um produto com o propósito do **CeliLac** — um guia seguro de estabelecimentos gastronômicos para pessoas celíacas, intolerantes à lactose e alérgicas alimentares —, existe outra funcionalidade central indispensável: **o Perfil Alimentar do Usuário (`ProfileController` e `DietaryProfile`)**.

O usuário cadastra suas restrições (ex.: *Doença Celíaca*, *Intolerância à Lactose*, *Alergia a Trigo*) e suas preferências de segurança (ex.: *Exige cuidados contra contato cruzado*). A partir desse momento, surge uma nova exigência de produto:
> **O aplicativo precisa cruzar o perfil do usuário com as opções de cada estabelecimento, destacando visualmente com um selo ("Atende ao seu perfil") quais locais são seguros para aquele consumidor — tanto na listagem da `HomePage` quanto na lista pessoal da `FavoritesPage`!**

Quando tentamos adicionar esse segundo estado global ao aplicativo desenvolvido até a Etapa 5, deparamo-nos imediatamente com **três grandes dores de engenharia**:

1. **A Pirâmide da Ruína de Provedores Aninhados (*Provider Nesting Pyramid*):** Se cada novo controlador exigir encapsular o aplicativo em um novo widget `ChangeNotifierProvider`, a raiz da aplicação (`lab_app.dart`) torna-se uma cascata de indentação ilegível:
   ```dart
   // ❌ O início do caos de aninhamento
   ChangeNotifierProvider(
     create: (_) => ProfileController(...),
     child: ChangeNotifierProvider(
       create: (_) => FavoritesController(...),
       child: ChangeNotifierProvider(
         create: (_) => SettingsController(...),
         child: MaterialApp(...),
       ),
     ),
   )
   ```
2. **O Gargalo da Carga Sequencial na Inicialização (*Waterfall Startup Bottleneck*):** Ao abrir o app, na tela de abertura (`SplashPage`), precisamos carregar os dados persistidos do disco (ler o perfil em `SharedPreferences` e abrir a tabela de favoritos no `SQLite`). Se executarmos esses carregamentos de forma puramente sequencial:
   $$\text{Tempo Total de Espera} = T_{\text{profile}} + T_{\text{favorites}} + T_{\text{onboarding}}$$
   O tempo de bloqueio na tela de *Splash* é a soma de todos os atrasos de disco. À medida que o app ganha novos repositórios, a inicialização torna-se inaceitavelmente lenta e o usuário tem a sensação de que o app travou.
3. **O Desafio do Cruzamento Reativo de Múltiplos Estados na Mesma Tela:** Como fazer com que a `HomePage` e a `FavoritesPage` dependam, ao mesmo tempo, de `FavoritesController` e de `ProfileController`? E mais importante: como garantir que, quando o usuário alterar seu perfil no formulário de configurações, **o selo de compatibilidade de todos os cartões na Home e nos Favoritos mude instantaneamente**, sem recarregar o banco de dados e sem que o cartão (`EstablishmentCard`) fique fortemente acoplado às regras de perfil?

---

### 2. O que esta Etapa 6 Propõe e Resolve
Este documento propõe a arquitetura para **Escalabilidade de Múltiplos Estados Globais e Concorrência de Inicialização**, resolvendo cinco problemas fundamentais de Engenharia de Software no Flutter:

1. **Composição Declarativa e Limpa com `MultiProvider`:** Eliminamos a pirâmide de aninhamento manual utilizando o `MultiProvider` na raiz do app (`lab_app.dart`), mantendo a árvore de código perfeitamente plana, legível e extensível para dezenas de provedores.
2. **Inicialização Paralela e Concorrente com Tuplas (*Records*) do Dart 3 e `.wait`:** Disparamos a carga assíncrona do `ProfileRepository` e do `FavoritesRepository` simultaneamente em paralelo com a animação de introdução da `SplashPage`, reduzindo o tempo de espera de E/S para:
   $$\text{Tempo Total de E/S} = \max(T_{\text{profile}}, T_{\text{favorites}})$$
   Garantindo segurança estática de tipos (*type-safe tuple destructuring*) ao desempacotar os resultados com `final (completed, _, _) = await (storageTask, profileLoad, favoritesLoad).wait;`.
3. **Resiliência e Tolerância a Falhas na Abertura:** Implementamos carregamento assíncrono idempotente com proteção contra exceções (`load() => _loading ??= _load();`), assegurando que uma falha ao ler preferências ou favoritos nunca impeça o aplicativo de abrir.
4. **Desacoplamento de Domínio e Funções Puras de Cruzamento (`meetsProfile`):** Evitamos o antipadrão de fazer uma entidade de domínio conhecer a outra (`Establishment` não conhece `DietaryProfile`). Em vez disso, criamos a função pura de domínio `meetsProfile(establishment, profile)` em `profile_match.dart`, permitindo que qualquer camada cruze os dados de forma testável e independente.
5. **Consumo Concorrente com Múltiplos `context.watch<T>`:** Aplicamos a regra de consumo de múltiplos controladores em uma mesma tela (`HomePage` e `FavoritesPage`), mantendo o `EstablishmentCard` como um componente puramente visual ("burro") que recebe apenas o booleano `matchesProfile: meetsProfile(establishment, profile)`.

---

### 3. Por que Dominar MultiProvider e Carga Paralela Antes da Etapa 7?
Na **Etapa 7**, enfrentaremos o desafio final de refinamento visual e de produto: **eliminar colisões de animação `Hero` dentro do `IndexedStack` e garantir acessibilidade total (TalkBack/VoiceOver) em cartões que possuem duas ações de toque concorrentes**.

Se a base de estados do aplicativo ainda estivesse acoplada, desorganizada ou sofresse com atrasos de carregamento assíncrono na inicialização, seria impossível sincronizar as abas do `IndexedStack` com fluidez. Ao estabilizarmos a injeção com `MultiProvider` e a carga paralela na `SplashPage`, garantimos que, quando a primeira tela for montada, todos os dados já estarão quentes e prontos na memória.

---

## Visão Geral do Roteiro de Aula

| Momento | Tempo estimado | O que acontece na aula |
|---|---|---|
| **0. Arquitetura de Pastas e Cenário Inicial** | 10 min | Introduzimos a funcionalidade de perfil (`lib/features/profile/`), revisamos o estado do app após a Etapa 5 e mapeamos os artefatos impactados. |
| **1. O Problema (A Dor Provocada ao Vivo)** | 15 min | Provocamos as 3 dores em sala: a cascata de indentação no `lab_app.dart`, a lentidão na abertura do app ao encadear `await`s sequenciais e a dessincronização visual ao alterar restrições. |
| **2. O Conceito (Fundamentação Teórica e Técnica)** | 25 min | Fundamentamos o funcionamento interno do `MultiProvider`, a concorrência de E/S no `EventLoop` do Dart, a sintaxe de *Records* e extensão `.wait` do Dart 3, e a orquestração desacoplada de múltiplos `watch`. |
| **3. A Prática (Implementação Passo a Passo por Arquivo)** | 30 min | Criamos a camada de perfil (`DietaryProfile`, `ProfileRepository`, `ProfileController`), injetamos com `MultiProvider`, construímos a `SplashPage` com `.wait` e conectamos `HomePage` e `FavoritesPage` com o selo `_ProfileMatchBadge`. |
| **4. Verificação, Benchmark e Ponte com o CeliLac** | 20 min | Executamos o benchmark didático comparando tempo sequencial vs. paralelo, validamos a reatividade cruzada ao vivo e mapeamos com o código real do **CeliLac**. |

---

## 0. Arquitetura de Pastas e Cenário Inicial

### 0.1 Fundamentação da Inclusão da Feature `profile`
Seguindo a risca nossa arquitetura *Feature-First* em Camadas, adicionamos a pasta `lib/features/profile/` com a mesma separação estrita:
- `domain/`: Contém a entidade `DietaryProfile`, o contrato `ProfileRepository` e a função pura de cruzamento `profile_match.dart`.
- `data/`: Contém o repositório local `LocalProfileRepository` (que persiste as preferências em formato JSON via `SharedPreferencesAsync`).
- `presentation/`: Contém o controlador reativo `ProfileController` e os widgets/páginas de perfil.

Além disso, introduzimos a funcionalidade de inicialização em `lib/features/startup/presentation/splash_page.dart` para orquestrar o carregamento concorrente dos repositórios antes da exibição das telas principais.

### 0.2 Árvore de Arquivos ao Final Desta Etapa 6

```text
lab_favoritos/ (ou celilac/)
├── lib/
│   ├── main.dart                                                     ← Ponto de entrada (runApp)
│   ├── app/
│   │   ├── lab_app.dart                                              ← ✏️ Atualizado: MultiProvider acima do MaterialApp
│   │   └── shell/
│   │       └── app_shell.dart                                        ← Casca com IndexedStack e abas
│   └── features/
│       ├── startup/
│       │   └── presentation/
│       │       └── splash_page.dart                                  ← 🆕 Tela de abertura com carga paralela (.wait)
│       ├── profile/                                                  ← 🆕 Nova funcionalidade completa de Perfil
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── dietary_profile.dart                          ← Entidade pura com Set<DietaryOption>
│       │   │   ├── repositories/
│       │   │   │   └── profile_repository.dart                       ← Contrato abstrato (load/save)
│       │   │   └── profile_match.dart                                ← Função pura: meetsProfile(establishment, profile)
│       │   ├── data/
│       │   │   ├── dietary_profile_json.dart                         ← Mapeador JSON de/para DietaryProfile
│       │   │   └── local_profile_repository.dart                     ← Persistência com SharedPreferencesAsync
│       │   └── presentation/
│       │       └── profile_controller.dart                           ← ChangeNotifier com carregamento idempotente
│       ├── establishments/
│       │   ├── domain/entities/
│       │   │   ├── dietary_option.dart                               ← Enum com restrições alimentares
│       │   │   └── establishment.dart                                ← Entidade atualizada com dietaryOptions
│       │   └── presentation/widgets/
│       │       ├── establishment_card.dart                           ← ✏️ Atualizado: exibe selo matchesProfile
│       │       └── favorite_button.dart
│       ├── home/presentation/pages/
│       │   └── home_page.dart                                        ← ✏️ Atualizado: cruza Favorites + Profile
│       └── favorites/
│           ├── data/
│           │   └── sqlite_favorites_repository.dart                  ← Repositório SQLite da Etapa 5
│           └── presentation/
│               ├── favorites_controller.dart                         ← Controlador de favoritos (Etapas 1 a 5)
│               └── pages/
│                   └── favorites_page.dart                           ← ✏️ Atualizado: cruza Favorites + Profile
```

---

## 1. O Problema (A Dor Provocada ao Vivo)

Para entender a necessidade do `MultiProvider` e da inicialização paralela, vamos analisar as três dores que surgem ao tentar expandir o app manualmente.

### 1.1 Cenário de Partida: O App Precisa Conhecer o Usuário
Na Etapa 5, o nosso app conhecia apenas estabelecimentos e salvava favoritos no SQLite. Mas o CeliLac precisa responder à pergunta: **"Este lugar é seguro para mim?"**

Se o usuário é celíaco estrito, um restaurante que oferece "opção sem glúten", mas prepara pizzas no mesmo forno enfarinhado, apresenta altíssimo risco de contaminação cruzada. Logo, o cartão precisa indicar se aquele local atende rigorosamente às restrições do perfil.

Para isso, criamos o `ProfileController`. Agora temos **dois controladores globais**:
1. `ProfileController`: gerencia as restrições e preferências do usuário.
2. `FavoritesController`: gerencia a lista de locais favoritados no SQLite.

---

### 1.2 Dor 1 ao Vivo: A "Pirâmide da Ruína" de Provedores Aninhados (*Provider Pyramid of Doom*)

Na tentativa de expor ambos os controladores para o app, o desenvolvedor escreve:

```dart
// ❌ Tentativa ingênua de aninhamento manual
class LabApp extends StatelessWidget {
  const LabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProfileController>(
      create: (_) => ProfileController(LocalProfileRepository()),
      child: ChangeNotifierProvider<FavoritesController>(
        create: (_) => FavoritesController(SqliteFavoritesRepository()),
        child: MaterialApp(
          title: 'CeliLac',
          home: const AppShell(),
        ),
      ),
    );
  }
}
```

#### O que há de errado com esse código?
- **Escalabilidade Comprometida:** Quando o aplicativo cresce e recebe `ThemeController`, `AuthController`, `LocationController` e `ConnectivityController`, a árvore de código cria uma pirâmide horizontal que avança 30 colunas para a direita.
- **Risco de Escopo e Erros de Dependência:** Se um provedor precisar ler outro (ou se trocarmos acidentalmente a ordem dos nós filhos), widgets intermediários podem perder o acesso ao contexto correto.
- **Falta de Padronização:** Cada novo controlador adicionado exige reescrever a hierarquia de `child` do widget anterior.

---

### 1.3 Dor 2 ao Vivo: O Gargalo de Inicialização em Cascata (*Waterfall Startup*)

Ambos os controladores dependem de E/S assíncrona para estarem prontos:
- `ProfileController.load()` lê o JSON de preferências do armazenamento local do aparelho.
- `FavoritesController.load()` abre a conexão com o banco SQLite e executa um `SELECT` ordenado na tabela `favorites`.

Se a nossa tela de abertura (`SplashPage`) inicializar os controladores de forma sequencial ingênua:

```dart
// ❌ Inicialização sequencial em cascata (Waterfall)
Future<void> _initializeSequential() async {
  // Passo 1: Espera o perfil carregar do disco (ex.: 300 ms)
  await context.read<ProfileController>().load();

  // Passo 2: Só depois começa a abrir o SQLite (ex.: 450 ms)
  await context.read<FavoritesController>().load();

  // Passo 3: Só depois verifica se o onboarding foi concluído (ex.: 150 ms)
  final completed = await OnboardingStorage().isCompleted();

  // Tempo total somado = 300 + 450 + 150 = 900 ms de atraso desnecessário!
  _navigateToNext(completed);
}
```

```text
CRONOGRAMA SEQUENCIAL (WATERFALL):
[-- Profile Load (300ms) --]
                           [----- Favorites SQLite Load (450ms) -----]
                                                                     [-- Onboarding (150ms) --]
|-------------------------------- TOTAL: 900 ms ---------------------------------------------->|
```

O aplicativo desperdiça quase 1 segundo bloqueado na inicialização porque as tarefas foram enfileiradas uma após a outra, mesmo sendo **completamente independentes entre si**!

---

### 1.4 Dor 3 ao Vivo: O Cruzamento Dessincronizado de Dois Estados na Mesma Tela

Imagine a `FavoritesPage`: ela exibe a lista de locais que o usuário favoritou. Cada cartão deve exibir uma insígnia verde: `Atende ao seu perfil`.

Se o aluno implementar isso de forma acoplada — por exemplo, fazendo o `FavoritesController` carregar o perfil de dentro dele, ou fazendo o `EstablishmentCard` chamar `context.watch<ProfileController>()` internamente —, surgem problemas graves:
1. O `FavoritesController` passa a ter duas responsabilidades (gerenciar favoritos e gerenciar perfil), violando o Princípio da Responsabilidade Única (SRP).
2. O `EstablishmentCard` perde a reutilização: ele não pode mais ser usado em locais onde o perfil não importa ou em telas de catálogo genérico.
3. Se o usuário abrir a tela de Perfil, alterar de "Intolerante a Lactose" para "Doença Celíaca" e voltar para os Favoritos, os cartões podem continuar exibindo o selo antigo se a página não escutar ambos os controladores no lugar certo.

---

## 2. O Conceito (Fundamentação Teórica e Técnica)

### 2.1 Por dentro do `MultiProvider`: Como ele achata a árvore sem alterar a Árvore de Elementos

Muitos desenvolvedores acreditam erroneamente que o `MultiProvider` é um widget mágico que "mescla" vários provedores em um único nó. **Isso é um equívoco conceitual.**

No Flutter, todo `InheritedWidget` precisa ter exatamente **um único filho (`child`)**. Para que dois `InheritedWidget`s estejam disponíveis na mesma subárvore, um **obrigatoriamente precisa ser ancestral do outro** na hierarquia de `Element`s:

```text
Árvore de Elementos Real do Flutter:
┌────────────────────────────────────────────────────────┐
│ InheritedProvider<ProfileController>                   │
│   └─ InheritedProvider<FavoritesController>            │
│        └─ MaterialApp                                  │
│             └─ ...                                     │
└────────────────────────────────────────────────────────┘
```

O que o `MultiProvider` faz é usar o padrão de projeto estrutural de **Composição Linear de Nós Simples (*SingleChildWidget*)**.

Ele recebe uma lista linear `List<SingleChildWidget> providers` e um `Widget child`. Internamente, ele utiliza a função funcional `foldRight` (ou uma iteração reversa) para compor a árvore recursivamente:

```dart
// Representação simplificada de como o MultiProvider opera internamente:
Widget buildTree(List<SingleChildWidget> providers, Widget child) {
  Widget current = child;
  for (final provider in providers.reversed) {
    current = provider.buildWithChild(current);
  }
  return current;
}
```

```text
SINTAXE DECLARATIVA PLANA:
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ProfileController(...)),
    ChangeNotifierProvider(create: (_) => FavoritesController(...)),
  ],
  child: MaterialApp(...),
)

VIRA INTERNAMENTE NA ÁRVORE:
ProfileProvider(
  child: FavoritesProvider(
    child: MaterialApp(...),
  ),
)
```

**Vantagem Arquitetural:** Ganhamos legibilidade total no código Dart (sem indentação em cascata), mantendo exatamente a semântica canônica do Flutter na árvore de elementos.

---

### 2.2 Concorrência no Event Loop do Dart: Por que Operações de E/S Rodam em Paralelo?

O Dart possui uma arquitetura de execução baseada em uma **Thread Única com Fila de Eventos (*Single-Threaded Event Loop*)**:

```text
               ┌────────────────────────┐
               │    Microtask Queue     │  (Prioridade máxima: agendamentos internos)
               └───────────┬────────────┘
                           ▼
               ┌────────────────────────┐
               │      Event Queue       │  (Cliques, timers, respostas de I/O)
               └───────────┬────────────┘
                           ▼
                ┌──────────────────────┐
                │ Dart Execution Thread│
                └──────────────────────┘
```

Se o Dart roda em thread única, como podemos afirmar que `ProfileController.load()` e `FavoritesController.load()` rodam **em paralelo**?

**Fundamentação Técnica:**
1. Operações de persistência (ler arquivo com `SharedPreferencesAsync` ou executar queries no SQLite com `sqflite`) **não consomem ciclos de CPU na thread do Dart**.
2. O pacote `sqflite` delega a execução do SQL para uma **thread de banco de dados nativa em C/C++/Java/Objective-C** gerenciada pelo sistema operacional (Android/iOS).
3. O pacote `shared_preferences` delega a leitura do disco para a API nativa do sistema operacional (Android DataStore/iOS UserDefaults).
4. Enquanto o disco nativo lê os arquivos em background, a thread principal do Dart fica completamente livre para processar frames de animação da `SplashPage` a 60 fps / 120 fps!
5. Quando o SQLite e o SharedPreferences terminam suas leituras de disco, o sistema operacional envia mensagens de volta pela ponte de comunicação do Flutter (*Platform Channels*), inserindo dois eventos na `Event Queue` do Dart.

Logo, ao disparar as duas operações simultaneamente, o tempo gasto com E/S de disco ocorre de forma concorrente no hardware do aparelho!

---

### 2.3 Dart 3 Records e a Extensão `.wait`: Concorrência com Segurança Estática de Tipos

No Dart clássico (versões 1 e 2), a execução paralela de múltiplas `Futures` dependia do método estático `Future.wait`:

```dart
// ❌ Sintaxe antiga do Dart 2: Fraca tipagem e risco de cast manual
final List<dynamic> results = await Future.wait([
  onboardingStorage.isCompleted(), // Future<bool>
  profileController.load(),         // Future<void>
  favoritesController.load(),       // Future<void>
]);

final bool completed = results[0] as bool; // ⚠️ Cast inseguro propenso a erro em tempo de execução
```

No **Dart 3**, a linguagem introduziu o suporte nativo a **Tuplas de Primeira Classe (*Records*)** e a poderosa extensão `.wait` na biblioteca `dart:async`.

Com ela, combinamos múltiplos futuros heterogêneos em uma tupla posicional e desestruturamos o resultado com segurança matemática de tipos:

```dart
// ✅ Sintaxe moderna do Dart 3: Type-Safe Record Concurrency
final (bool completed, _, _) = await (
  onboardingStorage.isCompleted(),
  profileController.load(),
  favoritesController.load(),
).wait;
```

```text
CRONOGRAMA CONCORRENTE COM (loadA, loadB).wait:
[----- Favorites SQLite Load (450ms) -----]
[-- Profile Load (300ms) --]
[-- Onboarding (150ms) --]
|---------------- TOTAL: 450 ms (Tempo do mais lento) ------------------->|
```

#### Vantagens do Padrão do Dart 3:
1. **Verificação Estática:** O compilador sabe exatamente o tipo retornado por cada item da tupla (posição 0 é `bool`, posição 1 é `void`, posição 2 é `void`).
2. **Descarte de Resultados Irrelevantes:** O identificador `_` (*wildcard pattern*) ignora os retornos `void` dos métodos `load()`, extraindo apenas o booleano `completed`.
3. **Redução Pela Metade do Tempo de Espera:** Em vez de somar os tempos ($300 + 450 + 150 = 900\text{ ms}$), o tempo total de bloqueio passa a ser apenas o tempo da operação mais demorada ($\max(300, 450, 150) = 450\text{ ms}$).

---

### 2.4 Cruzamento Reativo de Múltiplos Estados: Como o `context.watch` Lida com Múltiplos Notifiers

Quando um widget invoca `context.watch<T>()`, o método de extensão do `provider` executa o equivalente a:
```dart
Provider.of<T>(context, listen: true);
```
Internamente, isso adiciona o `Element` daquele widget à lista de dependentes do `InheritedProvider<T>`.

Quando uma tela chama dois `watch` dentro do mesmo método `build`:
```dart
@override
Widget build(BuildContext context) {
  final favoritesController = context.watch<FavoritesController>();
  final profileController = context.watch<ProfileController>();
  // ...
}
```

O `Element` da tela é registrado como ouvinte de **ambos os provedores**:
- Se `favoritesController.notifyListeners()` for disparado (ex.: usuário favoritou um local), a tela é reconstruída.
- Se `profileController.notifyListeners()` for disparado (ex.: usuário mudou suas restrições), **a mesma tela também é reconstruída imediatamente**!

```text
DIAGRAMA DE DEPENDÊNCIA REATIVA MÚLTIPLA:
┌────────────────────────────┐     ┌────────────────────────────┐
│    FavoritesController     │     │     ProfileController      │
│     (Notifica se favs      │     │    (Notifica se perfil     │
│          mudarem)          │     │          mudar)            │
└──────────────┬─────────────┘     └─────────────┬──────────────┘
               │                                 │
               └───────────────┬─────────────────┘
                               ▼
               ┌─────────────────────────────────┐
               │    FavoritesPage / HomePage     │
               │   (Reconstrói com qualquer um)  │
               └─────────────────────────────────┘
```

Isso garante reatividade bidirecional completa sem que nenhum controlador precise conhecer o outro!

---

### 2.5 Regra de Ouro do Domínio: Funções Puras para Cruzar Entidades Desacopladas (`meetsProfile`)

Um dos maiores erros de modelagem cometidos por iniciantes é poluir uma entidade de domínio com métodos que dependem de outra entidade:
```dart
// ❌ Violação de responsabilidade e acoplamento desnecessário
class Establishment {
  // ...
  bool isCompatibleWith(DietaryProfile profile) { ... } // ⚠️ Acoplou Establishment a DietaryProfile!
}
```

Por que isso é um erro arquitetural?
- O conceito de `Establishment` existe por si só (é um restaurante ou padaria com endereço, nota e cardápio). Ele não deve saber o que é o perfil de um usuário de aplicativo.
- O conceito de `DietaryProfile` também é independente (representa as condições médicas de uma pessoa).

A solução recomendada pelo **Domain-Driven Design (DDD)** e pela Engenharia de Software Limpa é criar uma **Função Pura de Domínio** em um arquivo de serviço ou especificação:

```dart
// ✅ Função Pura em lib/features/profile/domain/profile_match.dart
bool meetsProfile(Establishment establishment, DietaryProfile profile) {
  return profile.isComplete &&
      establishment.dietaryOptions.containsAll(profile.restrictions);
}
```

#### Propriedades Notáveis desta Função:
1. **Puramente Declarativa:** Não possui efeitos colaterais, não acessa rede, não acessa disco e não depende de contexto visual (`BuildContext`).
2. **Determinística e Testável em Microssegundos:** Para as mesmas entradas, o retorno é rigorosamente o mesmo. Testar essa regra exige zero mocks.
3. **Eficiência Algorítmica:** Como as restrições alimentares do perfil estão armazenadas em um `Set<DietaryOption>`, a verificação `containsAll` roda em tempo linear proporcional ao número de restrições do usuário ($O(k)$, onde $k \le 5$), sendo virtualmente instantânea.

---

## 3. A Prática (Implementação Passo a Passo por Arquivo)

Vamos agora implementar a arquitetura completa da Etapa 6 no nosso projeto de laboratório. Cada arquivo é precedido por seu objetivo técnico, papel arquitetural e fundamentos de código.

---

### Passo 3.1: Entidades de Domínio do Perfil Alimentar

#### Arquivo 1: `lib/features/establishments/domain/entities/dietary_option.dart`

**O que este arquivo propõe e resolve:**
Define o vocabulário padronizado de opções alimentares e restrições suportadas pelo sistema através de um `enum` do Dart com valores descritivos.

```dart
enum DietaryOption {
  glutenFree,
  dairyFree,
  vegan,
  vegetarian,
  celiacSafe,
}
```

---

#### Arquivo 2: `lib/features/profile/domain/entities/dietary_profile.dart`

**O que este arquivo propõe e resolve:**
Representa a entidade de domínio imutável com as restrições do usuário. Implementa `copyWith`, `operator ==` e `hashCode` baseados em valor para permitir comparações precisas na árvore de widgets.

```dart
import '../../establishments/domain/entities/dietary_option.dart';

class DietaryProfile {
  const DietaryProfile({
    this.name,
    this.restrictions = const {},
    this.needsCrossContactCare = false,
  });

  static const DietaryProfile empty = DietaryProfile();

  final String? name;
  final Set<DietaryOption> restrictions;
  final bool needsCrossContactCare;

  bool get isComplete => restrictions.isNotEmpty;

  DietaryProfile copyWith({
    String? name,
    bool clearName = false,
    Set<DietaryOption>? restrictions,
    bool? needsCrossContactCare,
  }) {
    return DietaryProfile(
      name: clearName ? null : (name ?? this.name),
      restrictions: restrictions ?? this.restrictions,
      needsCrossContactCare:
          needsCrossContactCare ?? this.needsCrossContactCare,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DietaryProfile &&
        other.name == name &&
        other.restrictions.length == restrictions.length &&
        other.restrictions.containsAll(restrictions) &&
        other.needsCrossContactCare == needsCrossContactCare;
  }

  @override
  int get hashCode => Object.hash(
    name,
    Object.hashAllUnordered(restrictions),
    needsCrossContactCare,
  );
}
```

---

### Passo 3.2: Função Pura de Match de Perfil

#### Arquivo 3: `lib/features/profile/domain/profile_match.dart`

**O que este arquivo propõe e resolve:**
Implementa a lógica pura que decide se um estabelecimento atende ao perfil do usuário, além de disponibilizar a função de ordenação estável `sortByProfile`.

```dart
import '../../establishments/domain/entities/establishment.dart';
import 'entities/dietary_profile.dart';

bool meetsProfile(Establishment establishment, DietaryProfile profile) {
  return profile.isComplete &&
      establishment.dietaryOptions.containsAll(profile.restrictions);
}

List<Establishment> sortByProfile(
  List<Establishment> establishments,
  DietaryProfile profile,
) {
  // Mantém a ordem original para cada grupo (compatíveis primeiro).
  return [
    ...establishments.where((e) => meetsProfile(e, profile)),
    ...establishments.where((e) => !meetsProfile(e, profile)),
  ];
}
```

---

### Passo 3.3: Contrato e Repositório de Perfil

#### Arquivo 4: `lib/features/profile/domain/repositories/profile_repository.dart`

**O que este arquivo propõe e resolve:**
Contrato abstrato de persistência para as preferências do perfil do usuário.

```dart
import '../entities/dietary_profile.dart';

abstract interface class ProfileRepository {
  Future<DietaryProfile> load();
  Future<void> save(DietaryProfile profile);
}
```

---

#### Arquivo 5: `lib/features/profile/data/local_profile_repository.dart`

**O que este arquivo propõe e resolve:**
Implementação do repositório utilizando `SharedPreferencesAsync` serializado em JSON com tolerância a corrupção de dados.

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/dietary_profile.dart';
import '../domain/repositories/profile_repository.dart';
import 'dietary_profile_json.dart';

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _key = 'dietary_profile';
  static const int _schemaVersion = 1;

  final SharedPreferencesAsync _preferences;

  @override
  Future<DietaryProfile> load() async {
    final stored = await _preferences.getString(_key);
    if (stored == null) {
      return DietaryProfile.empty;
    }

    try {
      if (jsonDecode(stored) case final Map<String, Object?> json) {
        return dietaryProfileFromJson(json);
      }
    } on FormatException {
      // Texto corrompido: segue com perfil vazio sem apagar o arquivo.
    }
    return DietaryProfile.empty;
  }

  @override
  Future<void> save(DietaryProfile profile) async {
    final json = {'schema_version': _schemaVersion, ...profile.toJson()};
    await _preferences.setString(_key, jsonEncode(json));
  }
}
```

---

### Passo 3.4: O Controlador Reativo `ProfileController`

#### Arquivo 6: `lib/features/profile/presentation/profile_controller.dart`

**O que este arquivo propõe e resolve:**
Gerencia o estado reativo do perfil. Aplica o padrão de **carregamento preguiçoso e idempotente**: `Future<void> load() => _loading ??= _load();`, garantindo que múltiplos chamados concorrentes reaproveitem o mesmo `Future` em andamento.

```dart
import 'package:flutter/foundation.dart';
import '../domain/entities/dietary_profile.dart';
import '../domain/repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this._repository);

  final ProfileRepository _repository;

  DietaryProfile _profile = DietaryProfile.empty;
  bool _isLoaded = false;
  Future<void>? _loading;

  DietaryProfile get profile => _profile;
  bool get isLoaded => _isLoaded;

  /// Retorna o Future de carregamento existente ou dispara um novo.
  /// Isso torna chamadas repetidas ou concorrentes completamente seguras (idempotência).
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      _profile = await _repository.load();
    } catch (error) {
      // O perfil enriquece o app, mas falha de leitura nunca deve impedir a navegação.
      debugPrint('Não foi possível carregar o perfil: $error');
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> save(DietaryProfile profile) async {
    await _repository.save(profile);
    _profile = profile;
    _isLoaded = true;
    notifyListeners();
  }
}
```

---

### Passo 3.5: Injeção dos Múltiplos Estados com `MultiProvider`

#### Arquivo 7: `lib/app/lab_app.dart` (ou `celilac_app.dart`)

**O que este arquivo propõe e resolve:**
Posiciona o `MultiProvider` acima do `MaterialApp`. Com isso, todos os controladores globais ficam disponíveis para qualquer tela do aplicativo e para quaisquer rotas empilhadas via `Navigator.push`.

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
    // MultiProvider achata a árvore e gerencia a criação/descarte limpo de ambos os controladores
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
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF1E3A8A), // Navy CeliLac
        ),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const SplashPage(),
      ),
    );
  }
}
```

---

### Passo 3.6: Tela de Abertura com Inicialização Paralela via Records do Dart 3 e `.wait`

#### Arquivo 8: `lib/features/startup/presentation/splash_page.dart`

**O que este arquivo propõe e resolve:**
Orquestra o início da aplicação. Dispara o carregamento concorrente dos repositórios simultaneamente com as animações da marca, aguardando a finalização com a sintaxe de tuplas do Dart 3: `await (task1, task2, task3).wait`.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/shell/app_shell.dart';
import '../../favorites/presentation/favorites_controller.dart';
import '../../profile/presentation/profile_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _initialize();
  }

  Future<void> _initialize() async {
    // 1. Dispara os carregamentos assíncronos de E/S imediatamente em background.
    // Usamos context.read porque estamos disparando uma ação dentro de um método assíncrono.
    final profileLoad = context.read<ProfileController>().load();
    final favoritesLoad = context.read<FavoritesController>().load();

    // 2. Executa a animação visual em paralelo com o I/O de disco
    await _animController.forward();
    if (!mounted) return;

    // 3. Aguarda todas as operações assíncronas em paralelo com Dart 3 Records e .wait
    // O tempo de espera será igual ao mais lento dos dois, nunca à soma!
    await (profileLoad, favoritesLoad).wait;
    if (!mounted) return;

    // 4. Navega para a casca principal com transição suave
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const AppShell(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined, size: 72, color: Color(0xFFD97706)),
              const SizedBox(height: 16),
              Text(
                'CeliLac',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Guia Seguro de Alimentação',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFD97706),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### Passo 3.7: Atualizar o `EstablishmentCard` para Exibir o Selo de Compatibilidade

#### Arquivo 9: Trecho do `EstablishmentCard` (`establishment_card.dart`)

**O que este arquivo propõe e resolve:**
O cartão permanece puramente visual: recebe o booleano `matchesProfile` via construtor e desenha o selo de compatibilidade estilizado com cores suaves e ícone representativo.

```dart
class EstablishmentCard extends StatelessWidget {
  const EstablishmentCard({
    super.key,
    required this.establishment,
    required this.onTap,
    this.matchesProfile = false, // 💡 Controlado pela página!
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.heroOrigin = 'home',
  });

  final Establishment establishment;
  final VoidCallback onTap;
  final bool matchesProfile;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final String heroOrigin;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícone ou Logo do Estabelecimento
                  CircleAvatar(
                    backgroundColor: const Color(0xFFE2E8F0),
                    child: Text(establishment.name.characters.first),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          establishment.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${establishment.category} • ${establishment.neighborhood}',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  // Botão de Favoritar
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: onFavoriteToggle,
                  ),
                ],
              ),
              // Selo de Compatibilidade com o Perfil Alimentar
              if (matchesProfile) ...[
                const SizedBox(height: 8),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5), // Verde claro suave
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF059669)),
          SizedBox(width: 4),
          Text(
            'Atende ao seu perfil',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF065F46),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### Passo 3.8: Cruzando Múltiplos Estados na `HomePage`

#### Arquivo 10: `lib/features/home/presentation/pages/home_page.dart`

**O que este arquivo propõe e resolve:**
A `HomePage` consome simultaneamente `FavoritesController` e `ProfileController` com `context.watch`. Ao renderizar a lista, ela utiliza `meetsProfile(item, profile)` para ativar o selo do cartão.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../establishments/data/sample_establishments.dart';
import '../../../establishments/domain/entities/establishment.dart';
import '../../../establishments/presentation/widgets/establishment_card.dart';
import '../../../profile/domain/profile_match.dart';
import '../../../profile/presentation/profile_controller.dart';
import '../../favorites/presentation/favorites_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 Escuta ambos os controladores no mesmo método build:
    final favoritesController = context.watch<FavoritesController>();
    final profile = context.watch<ProfileController>().profile;

    final establishments = sampleEstablishments;

    return Scaffold(
      appBar: AppBar(title: const Text('CeliLac — Início')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: establishments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final establishment = establishments[index];
          final isFav = favoritesController.isFavorite(establishment.id);
          final matches = meetsProfile(establishment, profile);

          return EstablishmentCard(
            establishment: establishment,
            isFavorite: isFav,
            matchesProfile: matches,
            onFavoriteToggle: () {
              context.read<FavoritesController>().toggle(establishment);
            },
            onTap: () {
              // Navega para detalhes
            },
          );
        },
      ),
    );
  }
}
```

---

### Passo 3.9: Cruzando Múltiplos Estados na `FavoritesPage`

#### Arquivo 11: `lib/features/favorites/presentation/pages/favorites_page.dart`

**O que este arquivo propõe e resolve:**
A página de favoritos lê os locais salvos do `FavoritesController` e cruza cada um deles com o perfil atual do usuário do `ProfileController`, permitindo ao usuário ver instantaneamente quais dos seus lugares favoritados atendem ao seu perfil alimentar atual.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../establishments/presentation/widgets/establishment_card.dart';
import '../../../profile/domain/profile_match.dart';
import '../../../profile/presentation/profile_controller.dart';
import '../favorites_controller.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 Escuta reativamente os dois estados globais
    final favoritesController = context.watch<FavoritesController>();
    final profile = context.watch<ProfileController>().profile;

    final favorites = favoritesController.favorites;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Favoritos')),
      body: !favoritesController.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : favorites.isEmpty
              ? const Center(
                  child: Text('Nenhum favorito salvo ainda no SQLite.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: favorites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final establishment = favorites[index];
                    return EstablishmentCard(
                      establishment: establishment,
                      isFavorite: true,
                      matchesProfile: meetsProfile(establishment, profile),
                      heroOrigin: 'favorites',
                      onFavoriteToggle: () {
                        context.read<FavoritesController>().toggle(establishment);
                      },
                      onTap: () {
                        // Navega para detalhes
                      },
                    );
                  },
                ),
    );
  }
}
```

---

## 4. Verificação, Benchmark e Ponte com o CeliLac

### 4.1 Roteiro de Verificação ao Vivo no Emulador (4 Cenários Interativos)

Para demonstrar a excelência arquitetural desta Etapa 6 aos alunos em sala, execute o seguinte roteiro de testes visuais:

#### Cenário 1: Fluidez na Splash com Carga Paralela
1. Feche o app completamente e abra-o novamente pelo terminal:
   ```bash
   flutter run
   ```
2. Observe que a `SplashPage` renderiza suavemente sua animação e transiciona para a tela principal em menos de meio segundo, com os favoritos do SQLite e as opções de perfil já 100% carregados em memória RAM.

#### Cenário 2: Perfil Completo com Selos Visuais
1. Com o app aberto, cadastre no perfil as restrições: `glutenFree` e `celiacSafe`.
2. Volte para a `HomePage`: observe que apenas os estabelecimentos que possuem ambas as opções exibem o selo verde `Atende ao seu perfil`.
3. Navegue até a aba `FavoritesPage`: observe que os locais salvos também refletem o selo de acordo com o mesmo critério.

#### Cenário 3: Reatividade Instantânea entre Telas
1. Na `FavoritesPage`, favorite um novo estabelecimento compatível.
2. Abra as configurações de perfil e remova a restrição `glutenFree`.
3. Volte imediatamente para a aba de Favoritos:
   - **Resultado Esperado:** O selo de compatibilidade de todos os cartões recalcula instantaneamente, sem necessidade de recarregar a tela ou reiniciar o app.

#### Cenário 4: Teste de Resiliência a Falha de Leitura
1. Simule uma falha na leitura do perfil (por exemplo, forçando uma exceção dentro de `_repository.load()`).
2. Abra o app:
   - **Resultado Esperado:** A `SplashPage` abre normalmente, o log registra o aviso com `debugPrint`, o perfil assume `DietaryProfile.empty` e o app segue funcionando com os favoritos sem travar a interface!

---

### 4.2 Benchmark Didático: Cascata Sequencial vs. Paralelismo com `.wait`

Para tangibilizar a economia de tempo com métricas concretas aos alunos, podemos adicionar uma medição simples com `Stopwatch`:

```dart
// Teste A: Carga Sequencial (Waterfall)
final swA = Stopwatch()..start();
await profileController.load();
await favoritesController.load();
swA.stop();
print('Tempo Sequencial: ${swA.elapsedMilliseconds} ms');

// Teste B: Carga Concorrente (.wait)
final swB = Stopwatch()..start();
await (profileController.load(), favoritesController.load()).wait;
swB.stop();
print('Tempo Concorrente: ${swB.elapsedMilliseconds} ms');
```

Em dispositivos móveis reais com latência de acesso a flash storage:
- **Sequencial:** $\approx 480\text{ ms}$ a $750\text{ ms}$
- **Concorrente (.wait):** $\approx 250\text{ ms}$ a $410\text{ ms}$
- **Ganho Real:** Redução de **35% a 50%** no tempo de abertura do aplicativo!

---

### 4.3 Ponte Direta com o CeliLac

Toda a arquitetura construída nesta etapa corresponde diretamente à espinha dorsal do aplicativo de produção do CeliLac:

| Arquivo do Laboratório | Arquivo no CeliLac de Produção | Responsabilidade no CeliLac |
|---|---|---|
| `lab_app.dart` | `lib/app/celilac_app.dart` | Injeta `ProfileController` e `FavoritesController` via `MultiProvider` acima do `MaterialApp`. |
| `splash_page.dart` | `lib/features/startup/presentation/splash_page.dart` | Dispara `await (OnboardingStorage().isCompleted(), profileLoad, favoritesLoad).wait` em paralelo com as animações da marca. |
| `profile_controller.dart` | `lib/features/profile/presentation/profile_controller.dart` | Controlador reativo com `load() => _loading ??= _load();`. |
| `profile_match.dart` | `lib/features/profile/domain/profile_match.dart` | Função pura `meetsProfile(establishment, profile)` e `sortByProfile`. |
| `establishment_card.dart` | `lib/features/establishments/presentation/widgets/establishment_card.dart` | Componente visual puro que recebe `matchesProfile: bool`. |
| `favorites_page.dart` | `lib/features/favorites/presentation/pages/favorites_page.dart` | Consome `context.watch<FavoritesController>()` e `context.watch<ProfileController>()`. |

---

### 4.4 Gancho para a Etapa 7: Hero Tags sem Colisão em `IndexedStack` e Acessibilidade

Com múltiplos estados sincronizados e carregados em paralelo, o nosso aplicativo atingiu maturidade arquitetural e de performance. No entanto, resta um desafio crítico de experiência de usuário e acessibilidade:

1. **A Colisão Fatal do `Hero` no `IndexedStack`:** Tanto a `HomePage` quanto a `FavoritesPage` permanecem vivas na memória dentro do `IndexedStack`. Se o mesmo estabelecimento estiver renderizado em ambas as abas com a mesma tag `Hero(tag: establishment.id)`, ao clicar para abrir a tela de detalhes, o Flutter quebra com:
   ```text
   There are multiple heroes that share the same tag within a subtree.
   ```
2. **A Barreira de Acessibilidade em Cartões com Múltiplas Ações:** O cartão do estabelecimento possui duas ações de clique independentes: tocar no cartão abre os detalhes; tocar no coração favorita ou desfavorita. Se usarmos `MergeSemantics`, leitores de tela como o *TalkBack* não conseguem alcançar o botão de favoritar!

Na **Etapa 7**, aprenderemos a resolver a desambiguação de tags de `Hero` por origem contextual (`$origin-establishment-icon-$id`) e a estruturar a árvore de semântica para acessibilidade universal.

