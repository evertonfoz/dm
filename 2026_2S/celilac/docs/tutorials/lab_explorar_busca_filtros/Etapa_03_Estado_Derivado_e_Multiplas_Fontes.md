# Etapa 3 — Estado Derivado e Múltiplas Fontes (`ExploreController`)

## Introdução: O que este documento propõe e resolve?

### 1. O Problema Real
O resultado da tela Explorar depende de **quatro** informações que vêm de lugares diferentes:

| Informação | Quem a controla | Quando muda |
|---|---|---|
| Catálogo de lugares | repositório (assíncrono) | ao carregar / tentar de novo |
| Filtros da consulta | a própria tela Explorar | a cada toque no chip ou letra digitada |
| Perfil alimentar | `ProfileController` | quando a pessoa salva o perfil na aba Perfil |
| Favoritos | `FavoritesController` | quando favorita em qualquer tela |

A tentação é **guardar o resultado** num campo `List<Establishment> _visible` e atualizá-lo a cada mudança. Dor provocada ao vivo:

1. Na aba Explorar, ligue **"Só favoritos"**.
2. Vá à aba Início e favorite um lugar novo.
3. Volte a Explorar: a lista **não mostra o lugar novo**, porque ninguém recalculou `_visible`.

O mesmo vale para o perfil. Guardar o resultado cria uma **cópia que envelhece**.

### 2. O que esta Etapa Propõe
Distinguir **estado guardado** de **estado derivado**:

- **Guardado** (`ExploreController`): catálogo, filtros e o status do carregamento.
- **Derivado** (calculado no `build`): a lista visível = `applyExploreFilters(catálogo, filtros, perfil, favoritos)`.

Como a função da Etapa 2 é pura e barata, recalcular a cada `build` é mais simples **e** sempre correto.

---

## Visão Geral do Roteiro de Aula

| Momento | Tempo | O que acontece |
|---|---|---|
| **1. O Problema** | 10 min | Reproduzimos a lista velha ao favoritar em outra aba. |
| **2. O Conceito** | 25 min | Guardado vs. derivado; `watch` em três fontes; alternativas. |
| **3. A Prática** | 30 min | `ExploreController`, 3º provedor no `MultiProvider`, lista derivada no `build`. |
| **4. Verificação e Ponte** | 10 min | Testes do controlador. |

---

## 1. O Problema

Com `_visible` guardado, o fluxo "favorito em outra aba" quebra. Anote no quadro a regra: **se um dado pode ser calculado a partir de outros, não o guarde**.

---

## 2. O Conceito

### 2.1 Estado guardado vs. derivado
| | Guardado | Derivado |
|---|---|---|
| Exemplo | `filters`, `catalog` | lista visível, contagem "8 lugares" |
| Risco | precisa ser atualizado com cuidado | nenhum: é recalculado |
| Onde vive | `ChangeNotifier` | `build` (ou getter) |

### 2.2 Quando recalcular a cada `build` é aceitável?
Quando o cálculo é **rápido** (dezenas ou centenas de itens) e **puro**. Para milhares de itens, seria o momento de memorizar o resultado (cache invalidado quando uma das fontes muda) ou de filtrar no banco.

### 2.3 Três fontes, três `watch`
Dentro do `build`:

```dart
final explore = context.watch<ExploreController>();
final profile = context.watch<ProfileController>().profile;
final favorites = context.watch<FavoritesController>();
```

Qualquer uma das três que chamar `notifyListeners()` reconstrói a tela. É a mesma ideia da Etapa 6 de Favoritos (`MultiProvider` + cruzar dois `watch`).

### 2.3.1 Alternativas
- `context.select<T, R>((c) => c.valor)`: reconstrói só quando **aquele valor** muda. Útil para telas pesadas.
- `ProxyProvider`/`ChangeNotifierProxyProvider`: cria um objeto que **depende** de outros provedores (ex.: um `ExploreResults` recalculado quando perfil ou favoritos mudam). Mais indireto; vale quando a lista derivada é usada em várias telas.

### 2.4 Estados de carregamento
O catálogo é assíncrono. Modelamos com um `enum`:

```dart
enum ExploreStatus { loading, ready, failure }
```

Um `enum` impede combinações impossíveis (`isLoading = true` e `hasError = true` ao mesmo tempo) e o `switch` exaustivo obriga a tela a tratar os três casos.

### 2.5 Não notificar quando nada mudou
Cada `notifyListeners()` reconstrói todos os ouvintes. Como `ExploreFilters` tem `==` (Etapa 1), o controlador compara antes:

```dart
void _update(ExploreFilters next) {
  if (next == _filters) return;
  _filters = next;
  notifyListeners();
}
```

### 2.6 `notifyListeners` durante o `build` é proibido
A tela chama `load()` no `initState`. Se `load()` notificasse **antes** do primeiro `await`, o Flutter lançaria "setState() or markNeedsBuild() called during build". Solução: o `status` já nasce `loading`; só notificamos **depois** do `await`.

---

## 3. A Prática

### Arquivo: `lib/features/explore/presentation/explore_controller.dart`

```dart
enum ExploreStatus { loading, ready, failure }

class ExploreController extends ChangeNotifier {
  ExploreController(this._repository);

  final EstablishmentRepository _repository;

  ExploreStatus _status = ExploreStatus.loading;
  List<Establishment> _catalog = const [];
  ExploreFilters _filters = ExploreFilters.initial;
  Future<void>? _loading;

  ExploreStatus get status => _status;
  List<Establishment> get catalog => _catalog;
  ExploreFilters get filters => _filters;

  /// Carrega uma única vez, mesmo que várias telas peçam.
  Future<void> load() => _loading ??= _load();

  /// Nova tentativa depois de uma falha.
  Future<void> retry() {
    _status = ExploreStatus.loading;
    notifyListeners();
    return _loading = _load();
  }

  Future<void> _load() async {
    try {
      _catalog = List.unmodifiable(await _repository.fetchNearby());
      _status = ExploreStatus.ready;
    } catch (error) {
      debugPrint('Não foi possível carregar o catálogo: $error');
      _status = ExploreStatus.failure;
    }
    notifyListeners();
  }

  void setQuery(String query) => _update(_filters.copyWith(query: query));

  void toggleCategory(EstablishmentCategory category) {
    _update(_filters.copyWith(categories: _toggled(_filters.categories, category)));
  }

  void toggleDietaryOption(DietaryOption option) {
    _update(_filters.copyWith(dietaryOptions: _toggled(_filters.dietaryOptions, option)));
  }

  void setOnlyMatchingProfile(bool value) =>
      _update(_filters.copyWith(onlyMatchingProfile: value));

  void setOnlyFavorites(bool value) =>
      _update(_filters.copyWith(onlyFavorites: value));

  void setSort(ExploreSort sort) => _update(_filters.copyWith(sort: sort));

  void clearFilters() => _update(_filters.cleared());

  /// Atalho da Home: começa uma exploração só desta categoria.
  void showOnly(EstablishmentCategory category) {
    _update(_filters.cleared().copyWith(categories: {category}));
  }

  void _update(ExploreFilters next) {
    if (next == _filters) return;
    _filters = next;
    notifyListeners();
  }

  Set<T> _toggled<T>(Set<T> current, T item) {
    return current.contains(item)
        ? ({...current}..remove(item))
        : {...current, item};
  }
}
```

**Pontos de atenção**
- `_loading ??= _load()` (já usado em `ProfileController` e `FavoritesController`) garante **uma** carga, mesmo que `load()` seja chamado várias vezes. `retry()` faz de propósito uma nova.
- `_toggled` **não altera** o conjunto atual: devolve outro (`{...current, item}`). Alterar o `Set` do `ExploreFilters` anterior quebraria a comparação `next == _filters` (os dois apontariam para o mesmo conjunto).
- `List.unmodifiable` impede que a tela altere o catálogo por engano.
- O controlador **não conhece** perfil nem favoritos: quem junta as fontes é a tela.

### Registrando o provedor (`MultiProvider`)

Em `celilac_app.dart`, um terceiro `ChangeNotifierProvider` (acima do `MaterialApp`, como os demais):

```dart
ChangeNotifierProvider<ExploreController>(
  create: (_) => ExploreController(
    establishmentRepository ?? const FakeEstablishmentRepository(),
  ),
),
```

Por que não criamos o controlador dentro da `ExplorePage`? Porque a **Home** também vai usá-lo (Etapa 6), e a página fica em uma aba que pode ser reconstruída; o provedor no topo preserva o estado.

### A lista derivada no `build`

```dart
final results = applyExploreFilters(
  explore.catalog,
  explore.filters,
  profile: profile,
  favoriteIds: {for (final f in favorites.favorites) f.id},
);
```

---

## 4. Verificação e Ponte com o CeliLac

Testes do controlador (sem widget):

```dart
test('não notifica quando nada mudou', () {
  controller.setQuery('');
  controller.setSort(ExploreSort.distance);
  controller.setOnlyFavorites(false);
  expect(notifications, 0);
});

test('falha vira estado de erro e retry recupera', () async {
  final controller = _controller([
    () async => throw Exception('sem rede'),
    () async => catalog,
  ]);
  await controller.load();
  expect(controller.status, ExploreStatus.failure);
  await controller.retry();
  expect(controller.status, ExploreStatus.ready);
});
```

| Peça | Arquivo no CeliLac |
|---|---|
| `ExploreController` | `lib/features/explore/presentation/explore_controller.dart` |
| 3º provedor | `lib/app/celilac_app.dart` |
| Dublê de repositório | `test/support/stub_establishment_repository.dart` |

**Checklist**
- [ ] O controlador guarda catálogo, filtros e status; **não** guarda a lista filtrada.
- [ ] `_update` ignora valores iguais.
- [ ] `status` nasce `loading` e só notifica depois do `await`.
- [ ] `Set`s são **copiados**, nunca alterados.
- [ ] Provedor no `MultiProvider`, acima do `MaterialApp`.

**Próxima etapa:** o campo de busca e o *debounce*.
