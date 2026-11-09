# Etapa 6 — Múltiplos Estados Globais (`MultiProvider`) e Inicialização Paralela
## Da Pirâmide de Provedores à Concorrência Eficiente de Estado e E/S

> **Instrução para o Gamma:** Cada seção separada por `---` corresponde a um slide. O foco está na progressão **Problema → Dor Arquitetural → Fundamentação → Como Resolver**, utilizando diagramas visuais, tabelas comparativas e trechos mínimos de código.

---

## Slide 1 — Capa

### Etapa 6: Múltiplos Estados Globais (`MultiProvider`) e Carga Paralela
**Escalabilidade de estado, concorrência no Event Loop e cruzamento desacoplado de dados**

- **Contexto:** Laboratório Sequencial CeliLac (Etapa 6 de 7)
- **Foco da aula:**
  1. Sentir a dor da "Pirâmide de Provedores" e do gargalo de abertura sequencial (*Waterfall*)
  2. Fundamentar o `MultiProvider` e a composição linear com `SingleChildWidget`
  3. Compreender a concorrência de E/S no Event Loop do Dart
  4. Implementar inicialização assíncrona paralela com Records do Dart 3 e `.wait`
  5. Cruzar múltiplos estados (`FavoritesController` + `ProfileController`) via funções puras de domínio

---

## Slide 2 — O Desafio de Produto: O App Não é Apenas Favoritos

### O que o usuário espera ao abrir o CeliLac?

Até a Etapa 5, gerenciávamos apenas os estabelecimentos favoritos no SQLite. Mas o CeliLac é um aplicativo de **segurança alimentar**.

- O usuário cadastra suas condições de saúde: *Doença Celíaca*, *Alergia a Trigo*, *Intolerância a Lactose*.
- Ele espera abrir a **Home** ou os **Favoritos** e bater o olho instantaneamente em um selo: **"Atende ao seu perfil"**.
- Se ele alterar suas restrições nas configurações, **todos os cartões do aplicativo devem recalcular a compatibilidade em tempo real**!

> **Problema:** Agora temos **dois controladores globais independentes**: `FavoritesController` (persistido no SQLite) e `ProfileController` (persistido nas preferências locais).

---

## Slide 3 — A Dor 1: A "Pirâmide da Ruína" de Provedores Aninhados

### O que acontece quando tentamos injetar múltiplos controladores manualmente?

A primeira intuição do desenvolvedor é aninhar um `ChangeNotifierProvider` dentro do outro:

```dart
// ❌ O início do caos de aninhamento
ChangeNotifierProvider<ProfileController>(
  create: (_) => ProfileController(...),
  child: ChangeNotifierProvider<FavoritesController>(
    create: (_) => FavoritesController(...),
    child: ChangeNotifierProvider<SettingsController>(
      create: (_) => SettingsController(...),
      child: MaterialApp(...), // 🔒 Preso a 30 colunas de indentação!
    ),
  ),
)
```

### O Custo da Pirâmide:
- **Ilegibilidade:** Cada novo estado empurra o código mais para a direita.
- **Fragilidade Estrutural:** Alterar a ordem ou adicionar wrappers intermediários gera erros de escopo difíceis de rastrear.
- **Violação de Manutenibilidade:** Falta um local único e padronizado para declarar as dependências do app.

---

## Slide 4 — A Dor 2: O Gargalo de Inicialização em Cascata (*Waterfall*)

### Como o app abre quando os controladores são lidos sequencialmente?

Na tela de abertura (`SplashPage`), ambos os controladores precisam carregar seus dados do disco:

```dart
// ❌ Carga sequencial em cascata: soma de todas as latências
await profileController.load();        // ⏳ Espera 300 ms de disco
await favoritesController.load();      // ⏳ Espera 450 ms de SQLite
final completed = await onboarding.isCompleted(); // ⏳ Espera 150 ms
```

```text
CRONOGRAMA SEQUENCIAL (WATERFALL):
[-- Profile Load (300ms) --]
                           [----- Favorites SQLite Load (450ms) -----]
                                                                     [-- Onboarding (150ms) --]
|-------------------------------- TOTAL: 900 ms ---------------------------------------------->|
```

> **A Dor do Usuário:** O aplicativo fica quase 1 segundo travado na tela de Splash, pois as operações foram executadas em fila indiana, mesmo sendo 100% independentes entre si!

---

## Slide 5 — A Dor 3: O Desafio do Cruzamento de Dois Estados na Mesma Tela

### Como a `HomePage` e a `FavoritesPage` exibem o selo de perfil?

```text
❌ ANTIPADRÕES COMUNS:
1. Fazer o FavoritesController carregar e conhecer o perfil
   → Viola o Princípio da Responsabilidade Única (SRP) e acopla domínios distintos.

2. Fazer o EstablishmentCard chamar context.watch<ProfileController>() internamente
   → Destrói a reutilização do cartão: ele deixa de ser um componente visual puro ("burro").

3. Manter variáveis estáticas globais na memória
   → Quebra o ciclo de vida do Flutter e impossibilita testes de unidade independentes.
```

> **A Pergunta de Engenharia:** Como manter as entidades puras, o cartão desacoplado e ainda assim reagir instantaneamente quando qualquer um dos dois estados mudar?

---

## Slide 6 — A Solução Arquitetural 1: Composição Declarativa com `MultiProvider`

### Achatando a árvore de código sem perder a semântica

O `MultiProvider` transforma o aninhamento piramidal em uma lista limpa e declarativa de provedores:

```dart
// ✅ Composição limpa, elegante e extensível
MultiProvider(
  providers: [
    ChangeNotifierProvider<ProfileController>(
      create: (_) => ProfileController(profileRepository),
    ),
    ChangeNotifierProvider<FavoritesController>(
      create: (_) => FavoritesController(favoritesRepository),
    ),
  ],
  child: MaterialApp(
    home: const SplashPage(),
  ),
)
```

- **Lista Plana:** Adicionar um terceiro ou quarto controlador requer apenas uma nova linha na lista `providers: [...]`.
- **Raiz Única:** Fica posicionado acima do `MaterialApp`, garantindo que rotas empilhadas via `Navigator.push` também acessem os dois estados.

---

## Slide 7 — Desmistificando o `MultiProvider`: O que Acontece na Árvore de Elementos?

### O `MultiProvider` cria um "super nó" na árvore? **Não!**

No Flutter, todo `InheritedWidget` só pode ter um filho (`child`). O `MultiProvider` é apenas uma conveniência sintática inteligente baseada no padrão **Composição Linear de `SingleChildWidget`**:

```text
O QUE VOCÊ ESCREVE (Código Plano):
MultiProvider(
  providers: [ProviderA, ProviderB],
  child: MaterialApp(...),
)

O QUE ELE MONTA NA ÁRVORE DE ELEMENTOS (Nós Encadeados):
ElementTree:
┌────────────────────────────────────────┐
│ InheritedProvider<ProfileController>   │
│   └─ InheritedProvider<FavoritesCtrl>  │
│        └─ MaterialApp                  │
└────────────────────────────────────────┘
```

> **Conceito Chave:** O `MultiProvider` não altera o funcionamento dos `InheritedWidget`s; ele simplesmente elimina a dor sintática de aninhar widgets manualmente.

---

## Slide 8 — O Motor Assíncrono do Dart: Concorrência de E/S no Event Loop

### Se o Dart roda em Thread Única, como executar coisas "em paralelo"?

```text
               ┌────────────────────────┐
               │    Microtask Queue     │
               └───────────┬────────────┘
                           ▼
               ┌────────────────────────┐
               │      Event Queue       │  ◄── Respostas de I/O do SQLite / Disco
               └───────────┬────────────┘
                           ▼
                ┌──────────────────────┐
                │ Dart Execution Thread│  ◄── Processa animações e lógica da UI
                └──────────────────────┘
```

1. Operações de persistência (leitura de arquivo ou SQLite) **não travam a CPU do Dart**.
2. O motor do SQLite (`sqflite`) executa em **threads nativas de background do SO**.
3. Enquanto o disco nativo lê os dados, a thread do Dart roda as animações da Splash suavemente a 60/120 fps!
4. Ao disparar as tarefas juntas, o acesso ao armazenamento ocorre de forma concorrente no hardware do dispositivo.

---

## Slide 9 — A Solução Arquitetural 2: Inicialização Paralela com Dart 3 e `.wait`

### Substituindo o antigo `Future.wait` por Tuplas Estáticas (*Records*)

```dart
// ❌ Sintaxe antiga do Dart 2 (Fraca tipagem)
final results = await Future.wait([onboardingTask, profileLoad, favoritesLoad]);
final completed = results[0] as bool; // ⚠️ Cast manual arriscado

// ✅ Sintaxe moderna do Dart 3 com Records e extensão .wait
final (completed, _, _) = await (
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

- **Type-Safe:** Cada posição da tupla possui tipagem estática inferida em tempo de compilação.
- **Descarte Seguro:** O padrão `_` descarta os retornos `void` sem overhead de memória.

---

## Slide 10 — Comparativo de Performance na Inicialização: Sequencial vs. Concorrente

### A matemática da experiência de abertura (Startup Time)

| Abordagem | Equação de Tempo de E/S | Exemplo Real no CeliLac | Sensação do Usuário |
|---|---|---|---|
| **Sequencial (Cascata)** | $T = T_{\text{profile}} + T_{\text{favorites}} + T_{\text{onboarding}}$ | $300 + 450 + 150 = \mathbf{900\text{ ms}}$ | Lento, app parece pesado ou congelado. |
| **Concorrente (`.wait`)** | $T = \max(T_{\text{profile}}, T_{\text{favorites}}, T_{\text{onboarding}})$ | $\max(300, 450, 150) = \mathbf{450\text{ ms}}$ | **Instantâneo**, abertura suave e fluida. |

$$\text{Ganho de Eficiência} = \frac{900 - 450}{900} = \mathbf{50\%\text{ de redução no tempo de abertura!}}$$

> **Regra de Ouro:** Operações de E/S assíncronas independentes nunca devem ser enfileiradas sequencialmente em momentos críticos de inicialização.

---

## Slide 11 — Resiliência na Splash: Carga Idempotente e Tolerante a Falhas

### Um erro de leitura de perfil nunca pode travar o aplicativo!

No `ProfileController`, aplicamos duas regras de blindagem:

```dart
class ProfileController extends ChangeNotifier {
  Future<void>? _loading;

  // 1. Idempotência: chamadas simultâneas reaproveitam o mesmo Future
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      _profile = await _repository.load();
    } catch (error) {
      // 2. Resiliência: loga a falha, mas permite que o app abra com perfil vazio
      debugPrint('Falha ao carregar perfil: $error');
    }
    _isLoaded = true;
    notifyListeners();
  }
}
```

- Se o arquivo de preferências estiver corrompido, o app abre com segurança.
- Múltiplas partes do código chamando `.load()` não disparam leituras redundantes no disco.

---

## Slide 12 — Princípio de Domínio: Desacoplamento Total via Funções Puras

### Como cruzar `Establishment` e `DietaryProfile` sem acoplamento?

```dart
// ✅ Função Pura em lib/features/profile/domain/profile_match.dart
bool meetsProfile(Establishment establishment, DietaryProfile profile) {
  return profile.isComplete &&
      establishment.dietaryOptions.containsAll(profile.restrictions);
}
```

```text
┌───────────────────────────┐                ┌───────────────────────────┐
│       Establishment       │                │      DietaryProfile       │
│ (Não conhece perfil algum)│                │ (Não conhece restaurantes)│
└─────────────┬─────────────┘                └─────────────┬─────────────┘
              │                                            │
              └─────────────────────┬──────────────────────┘
                                    ▼
                     meetsProfile(establishment, profile)
                                    ▼
                           bool matchesProfile
```

- **Independência:** Nenhuma das duas entidades de domínio conhece a outra.
- **Complexidade Mínima:** Como restrições são `Set`, `containsAll` roda em $O(k)$ operações instantâneas.
- **Testabilidade:** Testa a lógica de negócio com 100% de cobertura sem nenhum mock de Flutter ou banco.

---

## Slide 13 — A Regra de Ouro do Multi-Watch: Consumindo Dois Controllers no `build`

### A página como orquestradora e o cartão como componente puramente visual

```dart
// Na HomePage ou FavoritesPage:
@override
Widget build(BuildContext context) {
  final favoritesController = context.watch<FavoritesController>();
  final profile = context.watch<ProfileController>().profile;

  return EstablishmentCard(
    establishment: item,
    isFavorite: favoritesController.isFavorite(item.id),
    matchesProfile: meetsProfile(item, profile), // 💡 A página decide!
    onFavoriteToggle: () => context.read<FavoritesController>().toggle(item),
  );
}
```

```text
Responsabilidades Bem Definidas:
- Controllers: Guardam os dados e notificam mudanças.
- Página: Lê ambos os estados (watch), calcula a regra de negócio (meetsProfile) e dispara ações (read).
- EstablishmentCard: Apenas renderiza os dados que recebeu via construtor ("burro" e 100% reutilizável).
```

---

## Slide 14 — Reatividade Cruzada em Tempo Real

### O que acontece quando o usuário altera suas restrições alimentares?

```text
FLUXO DE REATIVIDADE BIDIRECIONAL:
1. Usuário altera restrição no ProfileFormPage (ex.: adiciona "Sem Glúten")
   └─► context.read<ProfileController>().save(novoPerfil)
         └─► notifyListeners() disparado no ProfileController
               │
               ├─► HomePage reconstrói (porque tinha watch<ProfileController>)
               │     └─► meetsProfile recalcula e novos selos verdes aparecem!
               │
               └─► FavoritesPage reconstrói (porque também tinha watch<ProfileController>)
                     └─► Os favoritos do SQLite atualizam seus selos sem tocar no banco!
```

> **Zero Acoplamento, Máxima Reatividade:** Os favoritos não precisaram ser recarregados do SQLite para que os selos de perfil fossem atualizados!

---

## Slide 15 — Fechamento da Etapa 6 e Provocação para a Etapa 7

### O que conquistamos nesta Etapa 6:
1. **Árvore Plana:** `MultiProvider` organizando todos os estados globais na raiz do app.
2. **Abertura Ultra Rápida:** Carga assíncrona concorrente na `SplashPage` com Records do Dart 3 e `.wait`.
3. **Domínio Desacoplado:** Regra pura de compatibilidade (`meetsProfile`) sem amarrar modelos de dados.
4. **Reatividade Instantânea:** Duas telas cruzando múltiplos estados sem inconsistências.

---

### A Provocação para a Etapa 7 (O Desafio Final!):
Agora temos os mesmos cartões vivos na aba **Início** e na aba **Favoritos** dentro do `IndexedStack`.

> **Problema 1:** Se clicarmos em um cartão para abrir a tela de detalhes com animação suave, o Flutter quebra com:
> `There are multiple heroes that share the same tag within a subtree`!
>
> **Problema 2:** O cartão agora possui **duas ações de clique concorrentes** (abrir detalhes e tocar no coração). Como garantir que pessoas cegas ou com baixa visão consigam usar os dois botões no *TalkBack* e *VoiceOver*?

👉 **Na Etapa 7: Hero sem Colisão em `IndexedStack` e Acessibilidade em Cartões de Ação Dupla!**

