# Etapa 2 — Desacoplamento com `FavoritesRepository` e Fluxo Assíncrono
## Da Memória Volátil ao Contrato de Persistência com Inversão de Dependência e Resiliência a Falhas

> **Instrução para o Gamma:** Cada seção separada por `---` corresponde a um slide. O foco está na progressão **Problema → Dor Arquitetural → Fundamentação → Como Resolver**, utilizando diagramas visuais, tabelas comparativas e trechos mínimos de código.

---

## Slide 1 — Capa

### Etapa 2: Contrato `FavoritesRepository`, Inversão de Dependência e Assincronia
**Como preparar o aplicativo para salvar dados no disco sem acoplar a interface ao banco de dados**

- **Contexto:** Laboratório Sequencial CeliLac (Etapa 2 de 7)
- **Foco da aula:**
  1. Sentir a dor da volatilidade da memória RAM e o perigo de misturar SQL no `Controller`
  2. Fundamentar o Padrão *Repository* e o Princípio da Inversão de Dependência (DIP)
  3. Evoluir o `FavoritesController` para assíncrono (`Future`, `_isLoaded` e `await` antes de `notifyListeners`)
  4. Tratar carregamento (`CircularProgressIndicator`) e falhas de gravação (`try/catch`, `context.mounted` e `SnackBar`)

---

## Slide 2 — O Problema (A Dor ao Vivo): O Experimento do *Hot Restart*

### O que acontece com os nossos favoritos quando o app reinicia?

Ao final da Etapa 1, todas as telas estavam sincronizadas. Mas faça este teste de 10 segundos:

1. **Passo 1:** Favorite o **Café Aconchego** e a **Padaria Trigo Zero** na aba Início.
2. **Passo 2:** Confira na aba Favoritos que os 2 lugares estão listados.
3. **Passo 3:** Pressione **`R` (*Hot Restart*)** ou feche e reabra o aplicativo.
4. **Resultado:** **Todos os favoritos sumiram!**

- **Por quê?** Porque `_favorites` e `_favoriteIds` vivem na **memória RAM**, que é volátil e zerada sempre que o processo do aplicativo é encerrado.

---

## Slide 3 — A Tentação Perigosa: "Por que não colocar o banco direto no Controller?"

### O atalho que destrói a arquitetura do projeto

A primeira intuição ao precisar salvar dados no disco é abrir o `FavoritesController` e escrever comandos de banco de dados diretamente dentro do método `toggle()`:

```text
❌ ACOPLAMENTO DIRETO (Mistura Apresentação com Infraestrutura):
┌───────────────────────────────────────────────────────────┐
│ FavoritesController (Camada Presentation)                 │
│  ├── Cuida de notificar a UI (notifyListeners)            │
│  ├── Cuida da estrutura em memória (List + Set)           │
│  └── ❌ Abre arquivo .db, escreve SQL, converte colunas!  │
└───────────────────────────────────────────────────────────┘
```

### As 4 dores desse atalho:
1. **Quebra do SRP:** o controlador muda se a tela mudar **ou** se o SQL mudar.
2. **Aprisionamento tecnológico:** trocar SQLite por Nuvem (Supabase) obrigaria a reescrever o controlador da UI.
3. **Sem simulação de falhas:** difícil testar como a tela reage a erros de gravação.
4. **Conflito Síncrono vs. Assíncrono:** RAM responde em nanossegundos; disco e rede demoram milissegundos (`Future`).

---

## Slide 4 — As Opções: Como Conectar o Controlador ao Armazenamento?

### Comparando 3 desenhos arquiteturais

| Abordagem | Como funciona | Qual é a dor / vantagem? |
|---|---|---|
| **Opção A: SQL direto no `FavoritesController`** | O controlador importa `sqflite` e executa `db.insert` / `db.delete`. | **Acoplamento total** entre UI e banco de dados; impossível testar isolado. |
| **Opção B: `FavoritesController` importa uma classe concreta `SqliteHelper`** | Separa o SQL em outra classe, mas o controlador depende diretamente dela. | Ainda viola a **Inversão de Dependência**: não permite trocar por memória ou nuvem sem editar o controlador. |
| **Opção C: Contrato `FavoritesRepository` no `domain` + Injeção de Dependência** | O controlador depende apenas de uma `abstract interface class`; quem escolhe a implementação é o topo do app (`LabApp`). | **Nossa escolha:** zero acoplamento, testável em memória e pronto para SQLite na Etapa 3! |

---

## Slide 5 — Organizando as 3 Camadas da Feature `favorites`

### Onde cada novo arquivo entra no nosso projeto?

A funcionalidade `favorites` agora ganha suas três camadas completas (`domain`, `data`, `presentation`):

```text
lib/features/favorites/
├── domain/
│   └── repositories/
│       └── favorites_repository.dart        ← 🆕 Contrato puro (abstract interface class)
├── data/
│   └── memory_favorites_repository.dart     ← 🆕 Implementação assíncrona + simulador de falhas
└── presentation/
    ├── favorites_controller.dart            ← 🔄 Evoluído para receber o Repository e usar Future
    └── pages/
        └── favorites_page.dart              ← 🔄 Exibe loading (!isLoaded) e SnackBar de erro
```

> **Repare no que NÃO muda:** `Establishment`, `EstablishmentCard` e `FavoriteButton` continuam **100% intocados**!

---

## Slide 6 — Fundamentação 1: O Padrão *Repository* e a Inversão de Dependência (DIP)

### Invertendo as setas com o "D" do SOLID

Pelo **Princípio da Inversão de Dependência**, módulos de alto nível (`presentation`) não dependem de módulos de baixo nível (`data`). **Ambos dependem de abstrações (`domain`)**:

```text
Camada PRESENTATION             Camada DOMAIN (Centro Puro)         Camada DATA (Detalhes)
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

- O `FavoritesController` **não sabe** se está falando com a Memória, com o SQLite ou com a Nuvem!

---

## Slide 7 — Fundamentação 2: `abstract interface class` no Dart 3

### Como escrever um contrato estrito na camada de domínio?

Em `lib/features/favorites/domain/repositories/favorites_repository.dart`:

```dart
import '../../../establishments/domain/entities/establishment.dart';

abstract interface class FavoritesRepository {
  Future<List<Establishment>> loadAll();
  Future<bool> isFavorite(String establishmentId);
  Future<void> add(Establishment establishment, {DateTime? savedAt});
  Future<void> remove(String establishmentId);
}
```

| Modificador no Dart 3 | Pode instanciar? | Permite `extends` (herança)? | Permite `implements` (contrato)? |
|---|---|---|---|
| `abstract class` | Não | Sim | Sim |
| **`abstract interface class`** | **Não** | **Não** | **Sim (100% contrato puro!)** |

- **Por que tudo retorna `Future<...>`?** Porque operações de disco/banco demoram milissegundos e não podem congelar a *UI Thread* (60/120 Hz) do Flutter!

---

## Slide 8 — Fundamentação 3: Carga Inicial Idempotente (`_loading ??= _load()`)

### Como carregar os dados na abertura do app sem duplicar leituras?

No `FavoritesController`, criamos o estado `_isLoaded` e memorizamos o `Future` da leitura:

```dart
bool _isLoaded = false;
Future<void>? _loading;
bool get isLoaded => _isLoaded;

Future<void> load() => _loading ??= _load();

Future<void> _load() async {
  try {
    final loaded = await _repository.loadAll();
    _setFavorites(loaded);
  } on Object catch (error) {
    debugPrint('Não foi possível carregar os favoritos: $error');
  }
  _isLoaded = true;
  notifyListeners();
}
```

- **O que `_loading ??= _load()` resolve?** Se `load()` for chamado 2 vezes seguidas, a segunda chamada reaproveita o **mesmo `Future`** sem consultar o banco duas vezes!
- **Degradação Graciosa no `catch`:** Se a leitura inicial falhar, o app não trava no loading infinito — ele registra o erro, segue com a lista vazia e marca `_isLoaded = true`.

---

## Slide 9 — Fundamentação 4: A Ordem Crítica no `toggle()` (A UI Não Pode Mentir!)

### Atualizar a memória ANTES ou DEPOIS do `await _repository.add(...)`?

Compare o que acontece na tela quando a gravação no banco falha:

```text
❌ SE ATUALIZAR A MEMÓRIA ANTES DO AWAIT:
Toque no ♡ ──► 1. Muda _favorites e chama notifyListeners() (Coração fica VERMELHO!)
               2. await _repository.add(...) ──► 💥 ERRO NO BANCO!
               Resultado: O item NÃO foi salvo, mas o coração ficou vermelho! (UI mentirosa)

✅ NOSSA REGRA: AWAIT NO REPOSITÓRIO ANTES DE MUDAR A MEMÓRIA!
Toque no ♡ ──► 1. await _repository.add(establishment)
                  ├── Se deu CERTO: atualiza _favorites + notifyListeners() (Coração VERMELHO!)
                  └── Se deu ERRO: pula direto para o catch da tela! Memória fica INTOCADA!
```

```dart
await _repository.add(establishment); // 1º Grava na persistência!
_setFavorites([establishment, ..._favorites.where((e) => e.id != establishment.id)]);
notifyListeners();                    // 2º Só avisa a tela se a gravação funcionou!
```

---

## Slide 10 — Por que o `isFavorite(id)` do Controller Continua Síncrono?

### Conciliando Banco Assíncrono (`Future`) com `build` Síncrono (120 Hz)

Uma dúvida muito comum:
> *"Se o `FavoritesRepository.isFavorite(id)` retorna `Future<bool>`, por que o `FavoritesController.isFavorite(id)` retorna `bool` direto sem `Future`?"*

| Camada | Método | Retorno | Por quê? |
|---|---|---|---|
| **Repositório (`data`)** | `repository.loadAll()` / `add()` | **`Future<...>`** (Assíncrono) | Vai até o armazenamento (disco/banco) quando o app abre ou quando o usuário clica. |
| **Controlador (`presentation`)** | `controller.isFavorite(id)` | **`bool`** (Síncrono em $O(1)$) | É chamado dentro do método `build` de cada cartão durante a rolagem da lista! Lê direto do `Set<String> _favoriteIds` espelhado na RAM. |

---

## Slide 11 — Fundamentação 5: Tratando Erros na UI (`try/catch`, `context.mounted` e `SnackBar`)

### O que a página faz quando `await controller.toggle(...)` lança uma exceção?

Como o `FavoritesController` não conhece widgets visuais, ele deixa a exceção subir para a página, que exibe um `SnackBar`:

```dart
Future<void> _toggleFavorite(BuildContext context, Establishment item) async {
  try {
    await context.read<FavoritesController>().toggle(item);
  } on Object {
    if (!context.mounted) return; // 🛡️ Proteção obrigatória após await!
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar os favoritos.')),
      );
  }
}
```

- **Por que `if (!context.mounted) return;` é vital?** Enquanto o `await` espera o banco, o usuário pode fechar a tela. Usar um `context` desmontado quebraria o app!
- **Por que `..hideCurrentSnackBar()`?** Evita empilhar uma fila de 5 avisos lentos se o usuário clicar várias vezes seguidas.

---

## Slide 12 — Os 3 Estados Visuais da `FavoritesPage`

### Evitando o "Falso Estado Vazio" durante a leitura inicial

Na `FavoritesPage`, antes de mostrar *"Você ainda não salvou nenhum estabelecimento"*, verificamos se a carga inicial já terminou (`isLoaded`):

```dart
body: !favoritesController.isLoaded
    ? const Center(child: CircularProgressIndicator()) // 1. Carregando...
    : favorites.isEmpty
        ? _buildEmptyState()                           // 2. Vazio real!
        : _buildFavoritesList(favorites),              // 3. Lista populada!
```

| Estado do `FavoritesController` | O que o usuário vê na `FavoritesPage` |
|---|---|
| `isLoaded == false` | `CircularProgressIndicator` centralizado |
| `isLoaded == true` e `favorites.isEmpty` | Estado vazio orientativo + botão *"Ver estabelecimentos"* |
| `isLoaded == true` e `favorites.isNotEmpty` | Contagem (*"2 lugares salvos"*) + lista de `EstablishmentCard` |

---

## Slide 13 — Injeção de Dependência na Raiz (`LabApp`) com `..load()`

### Conectando todas as peças no topo da árvore

Em `lib/app/lab_app.dart`, injetamos o repositório dentro do `FavoritesController` e já iniciamos a carga com o operador de cascata (`..load()`):

```dart
ChangeNotifierProvider<FavoritesController>(
  lazy: false,
  create: (_) => FavoritesController(
    favoritesRepository ?? MemoryFavoritesRepository(),
  )..load(), // 🚀 Cria o controlador, dispara load() e devolve a instância!
  child: MaterialApp(
    home: const AppShell(),
  ),
)
```

- **O poder do `MemoryFavoritesRepository` em aula:** possui parâmetros `stored`, `simulatedDelay` e `failOnChange` para provarmos ao vivo que nossa UI aguenta lentidão e falhas de banco!

---

## Slide 14 — Experimentos Práticos ao Vivo na Sala

### Provando que a nossa arquitetura é à prova de falhas

1. **Experimento 1 (Lentidão Simulada — `simulatedDelay: Duration(seconds: 2)`):**
   - Ao reiniciar o app e abrir a aba Favoritos, vemos o `CircularProgressIndicator` girar por 2 segundos antes de exibir os itens pré-carregados.
2. **Experimento 2 (Falha de Gravação — `failOnChange: true`):**
   - Ao tocar no coração de um cartão na Home ou na Tela de Detalhes:
     - O coração **NÃO fica vermelho** (a UI não mente!).
     - O **`SnackBar`** sobe imediatamente avisando: *"Não foi possível atualizar os favoritos."*

---

## Slide 15 — Fechamento da Etapa 2 e Gancho para a Etapa 3 (SQLite!)

### A recompensa da Inversão de Dependência

**✅ O que deixamos 100% pronto hoje:**
- Contrato `FavoritesRepository` na camada `domain`.
- `FavoritesController` assíncrono na sua versão definitiva (idêntica à do CeliLac!).
- `HomePage`, `FavoritesPage` e `EstablishmentDetailsPage` prontas para assincronia e erros.

**🚀 O Gancho para a Etapa 3 (SQLite Real com `sqflite`):**
- Na próxima aula, vamos criar o **`SqliteFavoritesRepository implements FavoritesRepository`** para gravar os favoritos no arquivo `.db` do celular.
- **Pergunta para a turma:** *"Quantas linhas do `FavoritesController` ou das 3 telas precisaremos alterar na próxima aula para o SQLite funcionar?"*
- **Resposta:** **ZERO linhas!** Bastará trocar `MemoryFavoritesRepository()` por `SqliteFavoritesRepository()` no `LabApp`!

