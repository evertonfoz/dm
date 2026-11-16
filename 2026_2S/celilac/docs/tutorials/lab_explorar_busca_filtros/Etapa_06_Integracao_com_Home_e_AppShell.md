# Etapa 6 — Integração com a Home e o `AppShell`

## Introdução: O que este documento propõe e resolve?

### 1. O Problema Real
A aba Explorar existe, mas ninguém chega até ela com intenção. Na Home, três elementos ainda respondem "em breve" com um `SnackBar`:

| Elemento da Home | O que a pessoa espera |
|---|---|
| Campo "Buscar produtos ou lugares" | ir para a busca |
| Atalho de categoria (ex.: Padaria) | ver só as padarias |
| "Ver todos" em "Perto de você" | ver a lista completa |

Os desafios:

1. **A Home não pode trocar de aba sozinha:** quem sabe qual aba está selecionada é o `AppShell` (`_selectedIndex`).
2. **A Home precisa mandar um recado ao Explorar** ("comece filtrado por Padaria") sem conhecer a `ExplorePage`.
3. **O estado de Explorar deve sobreviver** à troca de abas (voltar e encontrar os filtros como estavam).
4. **O botão "Ver estabelecimentos"** da aba Favoritos vazia hoje leva ao Início; faz mais sentido levar a Explorar.

### 2. O que esta Etapa Propõe
Duas peças simples, cada uma com uma responsabilidade:

- **O controlador compartilhado é o "canal" de dados:** a Home chama `ExploreController.showOnly(category)` (ou `clearFilters()`).
- **Um callback é o "canal" de navegação:** `HomePage(onOpenExplore: ...)`, fornecido pelo `AppShell`, que apenas troca `_selectedIndex`.

Separar *o que mostrar* (estado) de *para onde ir* (navegação) evita acoplar a Home à página de Explorar.

---

## Visão Geral do Roteiro de Aula

| Momento | Tempo | O que acontece |
|---|---|---|
| **1. O Problema** | 10 min | Os três "em breve" e o botão de Favoritos. |
| **2. O Conceito** | 20 min | Estado compartilhado + callback; `IndexedStack`; `read` em callbacks. |
| **3. A Prática** | 25 min | Alterar `AppShell` e `HomePage`. |
| **4. Verificação e Ponte** | 15 min | Teste de integração no shell. |

---

## 1. O Problema

Toque nas categorias da Home: aparece "A categoria Padaria estará disponível em breve." A aba Explorar, ao lado, está pronta e ignorada.

---

## 2. O Conceito

### 2.1 Dois canais independentes
| Canal | Quem usa | Para quê |
|---|---|---|
| `ExploreController` (via `provider`) | Home → Explorar | **dados**: "filtre por Padaria" |
| `VoidCallback onOpenExplore` | Home → `AppShell` | **navegação**: "mostre a aba 1" |

A Home não importa `ExplorePage`. Se amanhã Explorar virar uma rota empilhada em vez de aba, só o `AppShell` muda.

### 2.2 `IndexedStack` preserva o estado
O `AppShell` mantém **todas** as abas vivas ao mesmo tempo (`IndexedStack`). Como os filtros moram no `ExploreController` (e não num `State` descartável), eles sobrevivem mesmo que a árvore da aba seja reconstruída.

### 2.3 `showOnly` × `toggleCategory`
O atalho da Home significa "**só** Padarias, a partir do zero": se a pessoa já tinha "Sem glúten" ligado, o atalho **limpa** os outros critérios (mantendo a ordenação) e escolhe só a categoria. `toggleCategory` (chip) soma ou tira uma categoria **sem** mexer no resto. Intenções diferentes, métodos diferentes.

### 2.4 `read` em callbacks
Os toques da Home são **ações**, então usam `context.read<ExploreController>()`, nunca `watch` (que só pode ficar no `build`).

### 2.5 O botão "Ver estabelecimentos" em Favoritos
Mudou de `_onDestinationSelected(0)` para `(1)`: quem não tem favoritos quer **descobrir** lugares, não voltar ao início.

---

## 3. A Prática

### Arquivo 1: `lib/app/shell/app_shell.dart`

```dart
late final List<Widget> _tabs = [
  HomePage(
    repository: const FakeEstablishmentRepository(),
    onOpenExplore: () => _onDestinationSelected(1),
  ),
  const ExplorePage(repository: FakeEstablishmentRepository()),
  FavoritesPage(
    repository: const FakeEstablishmentRepository(),
    onExploreTap: () => _onDestinationSelected(1),
  ),
  const ProfilePage(),
];
```

Removemos o `ComingSoonView('Explorar')` desta aba. O botão "voltar" do aparelho continua levando à aba Início (o `PopScope` do shell não muda).

### Arquivo 2: `lib/features/home/presentation/pages/home_page.dart`

Novo parâmetro opcional:

```dart
const HomePage({super.key, required this.repository, this.onOpenExplore});

/// Pede ao AppShell para mostrar a aba Explorar.
final VoidCallback? onOpenExplore;
```

Os três pontos de entrada:

```dart
SearchEntry(onTap: () => widget.onOpenExplore?.call()),

CategoryShortcuts(
  onSelected: (category) {
    context.read<ExploreController>().showOnly(category);
    widget.onOpenExplore?.call();
  },
),

SectionHeader(
  title: 'Perto de você',
  actionLabel: 'Ver todos',
  onAction: () {
    context.read<ExploreController>().clearFilters();
    widget.onOpenExplore?.call();
  },
),
```

E removemos `_showComingSoon` e o `_toggleFavorite` local (agora `toggleFavoriteWithFeedback`).

**Pontos de atenção**
- `onOpenExplore` é **opcional**: em testes isolados da Home não há shell, e `?.call()` simplesmente não faz nada.
- A busca da Home **não** apaga os filtros existentes: ela só leva à tela (preservar o que a pessoa já escolheu é mais respeitoso).
- "Ver todos" **limpa** os filtros: a promessa é "a lista completa".

### Arquivo 3: `lib/features/establishments/data/fake_establishment_repository.dart`

Ampliamos o catálogo fictício de 4 para 12 lugares, com bairros repetidos (Zona 7, Centro), categorias repetidas e combinações diferentes de opções alimentares, para que cada filtro tenha efeito visível. Para os novos lugares (sem fotos), um helper `_simpleDetails` cria detalhes enxutos (descrição, endereço, horário e práticas), de modo que **todo cartão abre uma tela de detalhes válida**.

---

## 4. Verificação e Ponte com o CeliLac

Teste de integração em `test/app/app_shell_test.dart`:

```dart
testWidgets('um atalho de categoria da Home abre Explorar já filtrado', (tester) async {
  await pumpWithProfile(tester, const AppShell(), size: const Size(360, 2400));
  await tester.pumpAndSettle(const Duration(seconds: 1));

  await tester.tap(find.descendant(
    of: find.byType(HomePage),
    matching: find.widgetWithText(InkWell, 'Padaria'),
  ));
  await tester.pumpAndSettle();

  expect(find.byType(ExplorePage), findsOne);
  expect(find.text('Café Aconchego'), findsNothing);
  final chip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Padaria'));
  expect(chip.selected, isTrue);
});

testWidgets('os filtros de Explorar sobrevivem à troca de aba', (tester) async {
  // Explorar → liga "Mercado" → Perfil → volta a Explorar → chip continua selecionado.
});
```

| Peça | Arquivo no CeliLac |
|---|---|
| `onOpenExplore` e abas | `lib/app/shell/app_shell.dart` |
| Atalhos | `lib/features/home/presentation/pages/home_page.dart` |
| Catálogo de 12 lugares | `lib/features/establishments/data/fake_establishment_repository.dart` |

**Checklist**
- [ ] Nenhum "em breve" restante na Home para busca, categorias e "Ver todos".
- [ ] A Home não importa `ExplorePage`.
- [ ] Atalho de categoria = `showOnly`; "Ver todos" = `clearFilters`.
- [ ] Filtros sobrevivem à troca de abas.
- [ ] "Ver estabelecimentos" em Favoritos leva a Explorar.

**Desafio:** ao tocar na busca da Home, focar o campo de Explorar (dica: um contador `focusRequests` no controlador + `FocusNode` na página).

**Próxima etapa:** consolidar com testes.
