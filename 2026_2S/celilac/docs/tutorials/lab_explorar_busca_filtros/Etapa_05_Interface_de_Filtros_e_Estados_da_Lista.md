# Etapa 5 — Interface de Filtros Acessível e Estados da Lista (`ExplorePage`)

## Introdução: O que este documento propõe e resolve?

### 1. O Problema Real
Já temos o modelo (Etapa 1), a regra (Etapa 2), o estado (Etapa 3) e o campo de busca (Etapa 4). Falta montar a tela, e uma tela de filtros tem armadilhas próprias:

1. **Chips numa fileira com rolagem horizontal** escondem opções: com fonte a 200%, "Mercado" some para fora da tela e ninguém sabe que existe.
2. **Lista vazia sem saída:** "Nenhum resultado" sem um botão para desfazer os filtros deixa a pessoa presa.
3. **Contagem muda em silêncio:** quem usa leitor de tela não percebe que "8 lugares" virou "2 lugares".
4. **Três estados do catálogo** (carregando, erro, pronto) e mais o estado vazio.
5. **Mesmo cartão em duas abas:** a Home e Explorar usam `EstablishmentCard` (com `Hero`) dentro do `IndexedStack`; as tags precisam ser distintas (como na Etapa 7 de Favoritos).
6. **Favoritar duplicado:** o `try/catch` + `SnackBar` já existia na Home e em Favoritos; copiar uma terceira vez seria dívida técnica.

### 2. O que esta Etapa Propõe
- Filtros em **`Wrap`** (quebram de linha; nada fica escondido).
- **`FilterChip`** (tem estado "selecionado" e semântica pronta para leitor de tela).
- **Barra de resultados** com contagem em `liveRegion` + ordenação (`DropdownButton`).
- Estados `loading / failure / ready` e **vazio com "Limpar filtros"**.
- `heroOrigin: 'explore'` nos cartões.
- Extrair `toggleFavoriteWithFeedback` e usar nas três telas.

---

## Visão Geral do Roteiro de Aula

| Momento | Tempo | O que acontece |
|---|---|---|
| **1. O Problema** | 10 min | Fileira horizontal + fonte 200% + lista vazia sem saída. |
| **2. O Conceito** | 20 min | `Wrap`, `FilterChip`, `liveRegion`, estados da lista. |
| **3. A Prática** | 40 min | Três widgets e a `ExplorePage`. |
| **4. Verificação e Ponte** | 10 min | Rodar com `320×640` e fonte `200%`. |

---

## 1. O Problema

Monte os chips em um `SingleChildScrollView(scrollDirection: Axis.horizontal)`, aumente a fonte do aparelho para o máximo e veja: as últimas opções ficam fora da tela, sem nenhuma pista visual.

---

## 2. O Conceito

### 2.1 `Wrap` em vez de rolagem horizontal
`Wrap` coloca os filhos em linha e **quebra para a linha de baixo** quando não cabe. Mais linhas, mas tudo visível e tocável. `spacing` = espaço horizontal; `runSpacing` = espaço vertical entre linhas.

### 2.2 `FilterChip`
Chip com `selected` + `onSelected`. O Flutter já anuncia "selecionado/não selecionado" aos leitores de tela e respeita a área mínima de toque (48 dp) por padrão. Não precisamos montar semântica manual.

### 2.3 Quando mostrar "Atende ao meu perfil"?
`meetsProfile` devolve `false` sem perfil completo. Se o chip aparecesse para quem não tem perfil, ligá-lo esvaziaria a lista sem explicação. Decisão: **só exibir o chip quando `profile.isComplete`**.

### 2.4 `liveRegion`
`Semantics(liveRegion: true, child: Text('2 lugares encontrados'))` faz o leitor de tela **anunciar sozinho** quando o texto muda. É o equivalente do `aria-live` da web.

### 2.5 Estados da lista
| Estado | O que a tela mostra |
|---|---|
| `loading` | indicador de progresso |
| `failure` | `StatusMessage` com "Tentar novamente" |
| `ready` + vazio | `StatusMessage` com "Limpar filtros" (só se houver filtro ativo) |
| `ready` + itens | cartões |

Use `switch` sobre o `enum`: o compilador avisa se faltar um estado.

### 2.6 Lista com cabeçalho: `CustomScrollView` + slivers
O cabeçalho (busca, chips, contagem) **rola junto** com a lista (como na Home). Usamos `SliverList.list` para o cabeçalho e `SliverList.separated` para os cartões (construção sob demanda).

### 2.7 Lazy não monta tudo
`SliverList` só constrói o que está perto da tela. É ótimo para performance, mas muda como **testamos** (Etapa 7: tela alta).

---

## 3. A Prática

### Arquivo 1: `widgets/explore_filter_chips.dart`

```dart
class ExploreFilterChips extends StatelessWidget {
  const ExploreFilterChips({
    super.key,
    required this.filters,
    required this.showProfileFilter,
    required this.onCategoryToggle,
    required this.onDietaryToggle,
    required this.onProfileChanged,
    required this.onFavoritesChanged,
  });

  final ExploreFilters filters;
  final bool showProfileFilter;
  final ValueChanged<EstablishmentCategory> onCategoryToggle;
  final ValueChanged<DietaryOption> onDietaryToggle;
  final ValueChanged<bool> onProfileChanged;
  final ValueChanged<bool> onFavoritesChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        if (showProfileFilter)
          FilterChip(
            avatar: const Icon(Icons.person_pin_outlined),
            label: const Text('Atende ao meu perfil'),
            selected: filters.onlyMatchingProfile,
            onSelected: onProfileChanged,
          ),
        FilterChip(
          avatar: const Icon(Icons.favorite_outline),
          label: const Text('Só favoritos'),
          selected: filters.onlyFavorites,
          onSelected: onFavoritesChanged,
        ),
        for (final option in DietaryOption.values)
          FilterChip(
            label: Text(option.label),
            selected: filters.dietaryOptions.contains(option),
            onSelected: (_) => onDietaryToggle(option),
          ),
        for (final category in EstablishmentCategory.values)
          FilterChip(
            label: Text(category.label),
            selected: filters.categories.contains(category),
            onSelected: (_) => onCategoryToggle(category),
          ),
      ],
    );
  }
}
```

O widget é **"burro"**: recebe o estado e devolve eventos. Quem fala com o controlador é a página. Isso o torna reutilizável e fácil de testar.

### Arquivo 2: `widgets/explore_results_bar.dart`

```dart
final summary = switch (count) {
  0 => 'Nenhum lugar encontrado',
  1 => '1 lugar encontrado',
  _ => '$count lugares encontrados',
};

return Wrap(
  alignment: WrapAlignment.spaceBetween,
  crossAxisAlignment: WrapCrossAlignment.center,
  spacing: AppSpacing.md,
  children: [
    Semantics(
      liveRegion: true,
      child: Text(summary, style: /* titleMedium em navy, negrito */),
    ),
    DropdownButton<ExploreSort>(
      value: sort,
      underline: const SizedBox.shrink(),
      onChanged: (value) {
        if (value != null) onSortChanged(value);
      },
      items: [
        for (final option in ExploreSort.values)
          DropdownMenuItem(value: option, child: Text(option.label)),
      ],
    ),
  ],
);
```

Plural tratado à mão (`1 lugar` × `N lugares`), como em "1 lugar salvo" de Favoritos. `Wrap` aqui também: com fonte grande, a ordenação desce para a linha de baixo em vez de estourar a largura.

### Arquivo 3: `lib/features/favorites/presentation/toggle_favorite.dart`

```dart
Future<void> toggleFavoriteWithFeedback(
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
        const SnackBar(content: Text('Não foi possível atualizar os favoritos.')),
      );
  }
}
```

Aplicamos a mesma função na `HomePage` e na `FavoritesPage`, removendo os métodos duplicados. É uma **refatoração com testes de rede de segurança**: os testes existentes continuam passando.

### Arquivo 4: `pages/explore_page.dart` (essência)

```dart
class _ExplorePageState extends State<ExplorePage> {
  @override
  void initState() {
    super.initState();
    context.read<ExploreController>().load(); // read: é uma ação
  }

  @override
  Widget build(BuildContext context) {
    final explore = context.watch<ExploreController>();
    final profile = context.watch<ProfileController>().profile;
    final favorites = context.watch<FavoritesController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Explorar')),
      body: switch (explore.status) {
        ExploreStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        ExploreStatus.failure => Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: StatusMessage(
            icon: Icons.cloud_off_outlined,
            message: 'Não foi possível carregar os estabelecimentos.',
            actionLabel: 'Tentar novamente',
            onAction: explore.retry,
          ),
        ),
        ExploreStatus.ready => _buildReady(explore, profile, favorites, horizontalPadding),
      },
    );
  }
}
```

E em `_buildReady`:

```dart
final results = applyExploreFilters(
  explore.catalog, explore.filters,
  profile: profile,
  favoriteIds: {for (final f in favorites.favorites) f.id},
);

return CustomScrollView(slivers: [
  SliverPadding(
    padding: /* laterais responsivas */,
    sliver: SliverList.list(children: [
      ExploreSearchField(query: filters.query, onChanged: explore.setQuery),
      const SizedBox(height: AppSpacing.md),
      ExploreFilterChips(
        filters: filters,
        showProfileFilter: profile.isComplete,
        onCategoryToggle: explore.toggleCategory,
        onDietaryToggle: explore.toggleDietaryOption,
        onProfileChanged: explore.setOnlyMatchingProfile,
        onFavoritesChanged: explore.setOnlyFavorites,
      ),
      const SizedBox(height: AppSpacing.md),
      ExploreResultsBar(
        count: results.length,
        sort: filters.sort,
        onSortChanged: explore.setSort,
      ),
    ]),
  ),
  if (results.isEmpty)
    SliverToBoxAdapter(
      child: StatusMessage(
        icon: Icons.search_off_outlined,
        message: 'Nenhum lugar combina com esses filtros.',
        actionLabel: filters.hasActiveFilters ? 'Limpar filtros' : null,
        onAction: explore.clearFilters,
      ),
    )
  else
    SliverList.separated(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final establishment = results[index];
        return EstablishmentCard(
          establishment: establishment,
          matchesProfile: meetsProfile(establishment, profile),
          isFavorite: favorites.isFavorite(establishment.id),
          heroOrigin: 'explore',
          onFavoriteToggle: () =>
              toggleFavoriteWithFeedback(context, establishment),
          onTap: () => _openDetails(establishment),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
    ),
]);
```

O arquivo completo tem os `SliverPadding` de cada trecho; veja `lib/features/explore/presentation/pages/explore_page.dart`.

**Pontos de atenção**
- `context.read` no `initState` e `context.watch` só no `build`: regra de ouro da Etapa 1 de Favoritos.
- `load()` é **idempotente** (`_loading ??=`): mesmo se a página for reconstruída, não busca de novo.
- `_openDetails` empilha `EstablishmentDetailsPage(heroOrigin: 'explore')`: sem isso, `Hero` colidiria com o cartão da Home (erro "multiple heroes that share the same tag").
- O `FavoritesPage` e `HomePage` continuam recebendo `repository` por construtor; Explorar também, só para abrir o detalhe (o catálogo vem do controlador).

---

## 4. Verificação e Ponte com o CeliLac

Roteiro manual:
1. Digite "cafe": cartões com "Café" no nome ou tipo.
2. Ligue "Sem glúten" + "Mercado": lista vazia com **Limpar filtros**.
3. Mude a ordenação para "Melhor nota".
4. Aumente a fonte do aparelho a 200% e use uma tela pequena: nada estoura, todos os chips visíveis.

| Peça | Arquivo no CeliLac |
|---|---|
| `ExplorePage` | `lib/features/explore/presentation/pages/explore_page.dart` |
| `ExploreFilterChips` | `.../widgets/explore_filter_chips.dart` |
| `ExploreResultsBar` | `.../widgets/explore_results_bar.dart` |
| `toggleFavoriteWithFeedback` | `lib/features/favorites/presentation/toggle_favorite.dart` |

**Checklist**
- [ ] Filtros em `Wrap`, sem rolagem horizontal.
- [ ] Chip de perfil só com perfil completo.
- [ ] Contagem em `liveRegion`.
- [ ] `switch` cobre `loading`, `failure` e `ready`; vazio com saída.
- [ ] `heroOrigin: 'explore'`.
- [ ] Sem duplicação do `try/catch` de favoritos.

**Próxima etapa:** ligar a Home e o `AppShell` à nova aba.
