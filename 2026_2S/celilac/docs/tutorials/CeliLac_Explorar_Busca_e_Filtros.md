# CeliLac: Explorar — Busca, Filtros e Ordenação no Flutter

## Estado derivado, *debounce* e integração entre abas

---

## Como usar este material

Este é o **sexto material** da série de construção do **CeliLac**. Nos materiais anteriores, o aplicativo ganhou:

1. **Splash e Onboarding** — identidade visual e animações de entrada.
2. **HomePage e AppShell** — shell de navegação com quatro abas, tema, domínio e `FutureBuilder`.
3. **Detalhe do Estabelecimento** — navegação mestre-detalhe e `Hero`.
4. **Perfil Alimentar** — formulário, JSON no `SharedPreferences` e Home personalizada.
5. **Favoritos, SQLite e Provider** — persistência relacional, migração de esquema e `MultiProvider`.

Ao fim do quinto material, restaram **dois pontos visíveis** no aplicativo:

- A aba **Explorar** da barra inferior ainda mostrava "Estamos preparando esta área para você".
- Na **Home**, três elementos respondiam apenas com um `SnackBar` de "em breve": o campo **"Buscar produtos ou lugares"**, os **atalhos de categoria** e o botão **"Ver todos"**.

Além disso, o material de Favoritos deixou registrado um desafio opcional ("filtrar apenas os que atendem ao meu perfil"), e o perfil alimentar, que já personalizava a ordem da Home, ainda não podia ser usado como **critério de busca**.

Neste sexto material, damos vida à **segunda aba (`Explorar`)**: busca por texto, filtros combináveis, ordenação, e atalhos vindos da Home, tudo funcionando junto com o **perfil** e os **favoritos** que já existem.

Duas marcações aparecem ao longo do texto:

- **No CeliLac** — o código exato deste projeto.
- **No seu projeto** — como adaptar a mesma decisão para outro domínio (catálogo de cursos, imóveis, receitas, vagas).

> **Trilha de estudo em degraus:** este material é o ponto de chegada. Para estudar um conceito por vez, use o [laboratório sequencial de Explorar](./lab_explorar_busca_filtros/README.md) (7 etapas, cada uma com guia e roteiro de slides).

### Pré-requisitos

O projeto como terminou no material de Favoritos. Confirme:

```bash
flutter analyze
flutter test
```

Nenhuma dependência nova é necessária: usamos `provider` (já instalado) e apenas `dart:async` para o *debounce*.

### Ao final deste material, você será capaz de

1. Modelar **tudo o que a pessoa escolheu numa consulta** como um **objeto de valor imutável** (`copyWith`, `==`, `hashCode` com `Set`).
2. Escrever **filtragem e ordenação como função pura**, com semântica explícita de **E/OU**, busca **sem acentos** e **desempate** para ordenação previsível.
3. Distinguir **estado guardado** de **estado derivado** e combinar **três fontes** (`Explore`, `Profile`, `Favorites`) com `context.watch`.
4. Implementar **busca com *debounce*** usando `Timer`, liberando recursos no `dispose` e sincronizando o campo com o estado via `didUpdateWidget`.
5. Construir uma interface de filtros **acessível**: `Wrap` + `FilterChip`, contagem em `liveRegion`, estado vazio com saída.
6. Integrar duas abas com **dois canais**: estado compartilhado (dados) e *callback* (navegação).
7. Testar com **unidade**, **widget com relógio falso** (`pump(Duration)`) e **integração**, incluindo acessibilidade e *overflow*.

---

# Parte 0: Antes do código — os três problemas desta etapa

## 0.1 O que uma pessoa com restrição alimentar procura?

A Home mostra o que está **perto**. Mas a necessidade real é mais específica:

- *"Preciso de um lugar **sem glúten e sem lactose**."*
- *"Quero uma **padaria**."*
- *"Qual era aquele café do **Centro**?"*
- *"Dos meus **favoritos**, qual atende ao meu perfil?"*

Uma lista fixa ordenada por distância não responde a nenhuma delas. A aba Explorar existe para isso.

## 0.2 Problema 1: Onde mora a regra de "o que aparece"?

Quando há vários critérios (texto, categorias, opções alimentares, favoritos, perfil, ordenação), a regra cresce rápido. Se ela morar no `build`, só poderá ser testada abrindo a tela. **Decisão:** a regra vira uma **função pura no domínio**, e as escolhas da pessoa viram um **objeto de valor** (`ExploreFilters`).

## 0.3 Problema 2: Guardar a lista filtrada ou calculá-la?

A lista visível depende de **quatro fontes**: catálogo, filtros, perfil e favoritos. Se guardarmos o resultado, ele fica **velho** quando o perfil ou os favoritos mudam em outra aba. **Decisão:** guardar só o mínimo (catálogo + filtros) e **derivar** o resto a cada `build`.

## 0.4 Problema 3: Digitar sem recalcular a cada letra

Ligar o `TextField` direto ao estado recalcula a lista a cada tecla e deixa o campo desatualizado quando o estado muda por fora. **Decisão:** *debounce* de 300 ms e sincronização por `didUpdateWidget`.

## 0.5 Mapa dos arquivos desta etapa

```text
lib/
├── app/
│   ├── celilac_app.dart                         ← +ExploreController no MultiProvider
│   └── shell/app_shell.dart                     ← aba Explorar real + onOpenExplore
└── features/
    ├── explore/                                 ← NOVA FEATURE
    │   ├── domain/
    │   │   ├── explore_sort.dart                ← enum de ordenação
    │   │   ├── explore_filters.dart             ← consulta imutável
    │   │   ├── explore_query.dart               ← função pura de filtragem
    │   │   └── search_text.dart                 ← normalização de texto
    │   └── presentation/
    │       ├── explore_controller.dart          ← catálogo + filtros + status
    │       ├── pages/explore_page.dart          ← a tela
    │       └── widgets/
    │           ├── explore_search_field.dart    ← campo com debounce
    │           ├── explore_filter_chips.dart    ← chips em Wrap
    │           └── explore_results_bar.dart     ← contagem + ordenação
    ├── establishments/data/
    │   └── fake_establishment_repository.dart   ← catálogo de 4 → 12 lugares
    ├── favorites/presentation/
    │   ├── toggle_favorite.dart                 ← helper compartilhado (novo)
    │   └── pages/favorites_page.dart            ← usa o helper
    └── home/presentation/pages/home_page.dart   ← atalhos levam a Explorar

test/
├── app/app_shell_test.dart                      ← +2 testes de integração
├── support/
│   ├── explore_catalog.dart                     ← catálogo fixo (novo)
│   └── pump_app.dart                            ← +ExploreController
└── features/explore/                            ← 4 arquivos de teste (38 testes)
```

---

# Parte 1: O domínio da consulta (`domain`)

## 1.1 `ExploreSort` e `ExploreFilters`

Todas as escolhas da pessoa moram em **um único objeto imutável**.

```dart
enum ExploreSort {
  distance('Mais perto'),
  rating('Melhor nota'),
  name('Nome (A–Z)');

  const ExploreSort(this.label);
  final String label;
}
```

```dart
class ExploreFilters {
  const ExploreFilters({
    this.query = '',
    this.categories = const {},
    this.dietaryOptions = const {},
    this.onlyMatchingProfile = false,
    this.onlyFavorites = false,
    this.sort = ExploreSort.distance,
  });

  static const ExploreFilters initial = ExploreFilters();

  final String query;
  final Set<EstablishmentCategory> categories;   // vazio = qualquer; várias = OU
  final Set<DietaryOption> dietaryOptions;       // precisa oferecer TODAS
  final bool onlyMatchingProfile;
  final bool onlyFavorites;
  final ExploreSort sort;

  int get activeCount => /* busca + categorias + opções + perfil + favoritos */;
  bool get hasActiveFilters => activeCount > 0;

  ExploreFilters cleared() => ExploreFilters(sort: sort);  // mantém a ordenação
  ExploreFilters copyWith({...}) { ... }
  @override bool operator ==(Object other) { ... }          // compara Sets por conteúdo
  @override int get hashCode => Object.hash(..., Object.hashAllUnordered(categories), ...);
}
```

### Conceitos
- **Objeto de valor imutável:** campos `final`, construtor `const`, mudança por `copyWith`.
- **`Set` e igualdade:** `{a} == {a}` é `false` no Dart se forem instâncias diferentes. Comparamos tamanho + `containsAll`, e o `hashCode` usa `hashAllUnordered`.
- **Ordenação não é filtro:** não esconde lugares, não conta em `activeCount`, e sobrevive a `cleared()`.

> **No seu projeto:** identifique o que a pessoa pode escolher na sua busca (nível do curso, faixa de preço, número de quartos) e agrupe tudo num objeto igual a este.

> Passo a passo isolado: [Etapa 1 do laboratório](./lab_explorar_busca_filtros/Etapa_01_Estado_de_Consulta_Imutavel.md).

## 1.2 A função pura `applyExploreFilters`

```dart
List<Establishment> applyExploreFilters(
  List<Establishment> catalog,
  ExploreFilters filters, {
  required DietaryProfile profile,
  required Set<String> favoriteIds,
}) {
  final words = normalizeSearchText(filters.query)
      .split(' ').where((w) => w.isNotEmpty).toList();

  bool matches(Establishment e) {
    if (filters.categories.isNotEmpty && !filters.categories.contains(e.category)) return false;
    if (!e.dietaryOptions.containsAll(filters.dietaryOptions)) return false;
    if (filters.onlyMatchingProfile && !meetsProfile(e, profile)) return false;
    if (filters.onlyFavorites && !favoriteIds.contains(e.id)) return false;
    if (words.isEmpty) return true;
    final haystack = normalizeSearchText('${e.name} ${e.neighborhood} ${e.category.label}');
    return words.every(haystack.contains);
  }

  final results = catalog.where(matches).toList();
  results.sort(_comparatorFor(filters.sort));
  return results;
}
```

### Semântica adotada

| Grupo | Regra |
|---|---|
| Entre grupos | **E** |
| Categorias | **OU** |
| Opções alimentares | **E** (`containsAll`): quem pede "sem glúten" e "sem lactose" precisa dos dois |
| Texto | **todas** as palavras, em nome, bairro ou tipo |

### Conceitos
- **Função pura:** mesmo resultado para os mesmos argumentos; sem `BuildContext`, `Provider` ou I/O.
- **`meetsProfile` reaproveitado:** a regra de "atende ao perfil" já existe desde o Perfil Alimentar e não é duplicada.
- **`List.sort` não é estável:** todo comparador desempata pelo nome, para a ordem ser previsível.
- **Catálogo intacto:** `where(...).toList()` cria uma cópia antes de ordenar.

## 1.3 Normalização de texto

```dart
String normalizeSearchText(String text) {
  final lower = text.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final character in lower.split('')) {
    buffer.write(_accents[character] ?? character);
  }
  return buffer.toString();
}
```

"Bistrô", "BISTRO" e "bistro" passam a casar. Alternativa de mercado: o pacote `diacritic`; aqui um mapa pequeno evita uma dependência nova.

> Passo a passo: [Etapa 2 do laboratório](./lab_explorar_busca_filtros/Etapa_02_Filtragem_e_Ordenacao_Funcao_Pura.md).

---

# Parte 2: Estado guardado e estado derivado

## 2.1 O `ExploreController`

```dart
enum ExploreStatus { loading, ready, failure }

class ExploreController extends ChangeNotifier {
  ExploreController(this._repository);
  final EstablishmentRepository _repository;

  ExploreStatus _status = ExploreStatus.loading;
  List<Establishment> _catalog = const [];
  ExploreFilters _filters = ExploreFilters.initial;
  Future<void>? _loading;

  Future<void> load() => _loading ??= _load();
  Future<void> retry() { /* volta a loading, notifica e recarrega */ }

  void setQuery(String query) => _update(_filters.copyWith(query: query));
  void toggleCategory(EstablishmentCategory c) { ... }
  void toggleDietaryOption(DietaryOption o) { ... }
  void setOnlyMatchingProfile(bool v) { ... }
  void setOnlyFavorites(bool v) { ... }
  void setSort(ExploreSort s) { ... }
  void clearFilters() => _update(_filters.cleared());
  void showOnly(EstablishmentCategory c) => _update(_filters.cleared().copyWith(categories: {c}));

  void _update(ExploreFilters next) {
    if (next == _filters) return;      // nada mudou: ninguém é reconstruído
    _filters = next;
    notifyListeners();
  }
}
```

### Conceitos
- **Guarda o mínimo:** catálogo, filtros e status. **Não** guarda a lista filtrada.
- **`enum` de status:** impede combinações impossíveis (`isLoading` e `hasError` ao mesmo tempo).
- **Não notifica sem mudança:** possível porque `ExploreFilters` implementa `==`.
- **`Set`s sempre copiados:** nunca alterar o conjunto do filtro anterior.
- **Sem `notifyListeners` durante o `build`:** o status já nasce `loading`; só se notifica depois do `await`.

## 2.2 Registro no `MultiProvider`

```dart
ChangeNotifierProvider<ExploreController>(
  create: (_) => ExploreController(
    establishmentRepository ?? const FakeEstablishmentRepository(),
  ),
),
```

O provedor fica **acima do `MaterialApp`** (como Perfil e Favoritos) porque a Home também o usará.

## 2.3 A lista derivada, três `watch`

Na `ExplorePage`:

```dart
final explore = context.watch<ExploreController>();
final profile = context.watch<ProfileController>().profile;
final favorites = context.watch<FavoritesController>();

final results = applyExploreFilters(
  explore.catalog, explore.filters,
  profile: profile,
  favoriteIds: {for (final f in favorites.favorites) f.id},
);
```

Resultado: favoritar na Home ou salvar o perfil **atualiza Explorar na hora**, sem nenhum código de sincronização.

### Alternativas
| Alternativa | Quando vale |
|---|---|
| `context.select` | tela pesada; reconstruir só quando um valor específico muda |
| `ChangeNotifierProxyProvider` | a lista derivada é usada em várias telas |
| Filtrar no banco (SQL `WHERE`) | catálogo grande, vindo de SQLite ou API |

> Passo a passo: [Etapa 3 do laboratório](./lab_explorar_busca_filtros/Etapa_03_Estado_Derivado_e_Multiplas_Fontes.md).

---

# Parte 3: Busca com *debounce*

```dart
class _ExploreSearchFieldState extends State<ExploreSearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.query);
  Timer? _timer;

  @override
  void didUpdateWidget(ExploreSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query && widget.query != _controller.text) {
      _timer?.cancel();
      _controller.text = widget.query;
    }
  }

  void _onChanged(String text) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onChanged(text));
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }
  // ... _clear() cancela o timer e avisa na hora
}
```

### Conceitos
- **Debounce × throttle:** debounce espera **silêncio** (busca); throttle limita a **frequência** (rolagem).
- **Dono de cada coisa:** o `State` cuida do `Timer` e do `TextEditingController` (e os libera); o controlador guarda a "verdade" da busca.
- **`didUpdateWidget`:** quando "Limpar filtros" ou um atalho da Home mudam a busca por fora, o campo acompanha.
- **A segunda condição evita laço:** se o texto já é igual, não reescrevemos (o cursor não salta).

> **No seu projeto:** o mesmo padrão serve para qualquer busca que, no futuro, vá à rede ou ao banco.

> Passo a passo: [Etapa 4 do laboratório](./lab_explorar_busca_filtros/Etapa_04_Busca_com_Debounce.md).

---

# Parte 4: A tela Explorar

## 4.1 Os três widgets

- **`ExploreFilterChips`:** `Wrap` de `FilterChip`s (perfil, favoritos, opções alimentares, categorias). **Sem rolagem horizontal**: com fonte a 200%, nada fica escondido. O chip "Atende ao meu perfil" só aparece com perfil completo.
- **`ExploreResultsBar`:** contagem ("1 lugar encontrado", "8 lugares encontrados") em `Semantics(liveRegion: true)` e `DropdownButton<ExploreSort>`.
- **`ExploreSearchField`:** Parte 3.

Os widgets de apresentação são **"burros"**: recebem estado e devolvem eventos; só a página fala com o controlador.

## 4.2 A `ExplorePage`

```dart
body: switch (explore.status) {
  ExploreStatus.loading => const Center(child: CircularProgressIndicator()),
  ExploreStatus.failure => StatusMessage(
    icon: Icons.cloud_off_outlined,
    message: 'Não foi possível carregar os estabelecimentos.',
    actionLabel: 'Tentar novamente',
    onAction: explore.retry,
  ),
  ExploreStatus.ready => _buildReady(...),   // CustomScrollView com cabeçalho + lista
},
```

| Estado | O que a pessoa vê |
|---|---|
| carregando | indicador de progresso |
| erro | mensagem + "Tentar novamente" |
| pronto, sem resultado | "Nenhum lugar combina com esses filtros." + **Limpar filtros** (se houver filtro ativo) |
| pronto, com resultado | cartões `EstablishmentCard` |

### Detalhes importantes
- `context.read<ExploreController>().load()` no `initState` (ação), `watch` só no `build`.
- `heroOrigin: 'explore'` no cartão e na `EstablishmentDetailsPage`, para a tag do `Hero` não colidir com a da Home (mesma lição da Etapa 7 de Favoritos).
- O cabeçalho **rola junto** com a lista (`CustomScrollView` + slivers).

## 4.3 Refatoração: `toggleFavoriteWithFeedback`

O `try / catch` + `SnackBar` de "Não foi possível atualizar os favoritos" já existia na Home e em Favoritos. Ao criar a terceira cópia, extraímos:

```dart
Future<void> toggleFavoriteWithFeedback(BuildContext context, Establishment e) async {
  try {
    await context.read<FavoritesController>().toggle(e);
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Não foi possível atualizar os favoritos.')));
  }
}
```

Regra de bolso: **a terceira repetição** pede extração. Os testes existentes serviram de rede de segurança.

> Passo a passo: [Etapa 5 do laboratório](./lab_explorar_busca_filtros/Etapa_05_Interface_de_Filtros_e_Estados_da_Lista.md).

---

# Parte 5: Conectando a Home e o `AppShell`

## 5.1 Dois canais

| Canal | Carrega | Como |
|---|---|---|
| `ExploreController` | **dados** ("só Padarias") | `context.read` + `provider` |
| `HomePage.onOpenExplore` | **navegação** ("mostre a aba 1") | *callback* fornecido pelo `AppShell` |

A Home **não importa** a `ExplorePage`.

```dart
// AppShell
HomePage(
  repository: const FakeEstablishmentRepository(),
  onOpenExplore: () => _onDestinationSelected(1),
),
const ExplorePage(repository: FakeEstablishmentRepository()),
```

```dart
// HomePage
SearchEntry(onTap: () => widget.onOpenExplore?.call()),

CategoryShortcuts(onSelected: (category) {
  context.read<ExploreController>().showOnly(category);
  widget.onOpenExplore?.call();
}),

SectionHeader(
  title: 'Perto de você',
  actionLabel: 'Ver todos',
  onAction: () {
    context.read<ExploreController>().clearFilters();
    widget.onOpenExplore?.call();
  },
),
```

### Decisões de produto
| Gesto | Efeito | Por quê |
|---|---|---|
| Toca numa categoria | `showOnly`: limpa o resto e escolhe a categoria | atalho significa "só isto, do zero" |
| Toca em "Ver todos" | `clearFilters` | a promessa é a lista completa |
| Toca na busca | apenas abre Explorar | respeita filtros já escolhidos |
| "Ver estabelecimentos" (Favoritos vazio) | leva a **Explorar** (antes: Início) | quem não tem favoritos quer descobrir lugares |

`IndexedStack` mantém todas as abas vivas, e como os filtros moram no controlador, **sobrevivem à troca de aba**.

## 5.2 Catálogo maior

O catálogo fictício passou de 4 para **12 lugares** (com bairros, categorias e opções alimentares variados), e um helper `_simpleDetails` gera detalhes enxutos para os novos, de modo que todo cartão abre uma tela de detalhes válida. Com 4 itens, filtros e ordenação não mostrariam diferença.

> Passo a passo: [Etapa 6 do laboratório](./lab_explorar_busca_filtros/Etapa_06_Integracao_com_Home_e_AppShell.md).

---

# Parte 6: Qualidade, responsividade e acessibilidade

| Item | Como foi tratado |
|---|---|
| Fonte a 200% em tela `320×640` | filtros e barra de resultados em `Wrap`; teste de *overflow* |
| Áreas de toque | `FilterChip` e botão de limpar respeitam 48 dp; `androidTapTargetGuideline` |
| Rótulos | `tooltip` em "Limpar busca"; `labeledTapTargetGuideline` |
| Mudança de contagem | `liveRegion` anuncia a nova contagem |
| Cor não é a única pista | chips mostram estado "selecionado" (visual e semântico) |
| Estado vazio | sempre com uma saída ("Limpar filtros") |

---

# Parte 7: Testes automatizados

Nenhuma dependência nova. A suíte passa de **122 para 162 testes**.

| Arquivo | Tipo | O que cobre |
|---|---|---|
| `explore_query_test.dart` | unidade | busca, categorias, opções, perfil, favoritos, ordenação, `ExploreFilters` |
| `search_text_test.dart` | unidade | normalização de acentos |
| `explore_controller_test.dart` | unidade | carga única, falha, `retry`, `showOnly`, não notificar sem mudança |
| `explore_page_test.dart` | widget | debounce, chips, vazio, ordenação, perfil, favoritos, acessibilidade, *overflow* |
| `app_shell_test.dart` | integração | Home → Explorar filtrado; filtros sobrevivem à troca de aba |

Três cuidados que valem ouro:

1. **Debounce:** use `tester.pump(const Duration(milliseconds: 300))`, nunca `sleep`.
2. **Lista lazy:** o `SliverList` só monta o que cabe; nos testes que contam cartões, use tela alta (`Size(360, 2400)`).
3. **Dados fixos fora de ordem:** o catálogo de teste (`explore_catalog.dart`) nasce embaralhado para que a ordenação seja de fato exercitada.

> Passo a passo: [Etapa 7 do laboratório](./lab_explorar_busca_filtros/Etapa_07_Testes_da_Busca_e_Filtros.md).

---

# Parte 8: Revisão — decisões, armadilhas e alternativas

## 8.1 Resumo das decisões

| Decisão | Motivo |
|---|---|
| Consulta como objeto imutável | fácil de comparar, limpar, passar e testar |
| Regra como função pura no domínio | testável sem Flutter |
| Guardar só catálogo + filtros; derivar a lista | nunca fica velha |
| `ExploreController` no `MultiProvider` | a Home também precisa dele; estado sobrevive às abas |
| *Debounce* no widget (não no controlador) | é uma preocupação de **entrada de texto**, não de domínio |
| `Wrap` em vez de rolagem horizontal | acessibilidade com fonte grande |
| Dois canais Home → Explorar | Home desacoplada da página |
| Opções alimentares com **E** | quem restringe os dois precisa dos dois |

## 8.2 Armadilhas encontradas

| Sintoma | Causa | Correção |
|---|---|---|
| Lista não atualiza ao favoritar em outra aba | resultado filtrado guardado no estado | derivar no `build` |
| Campo mostra texto antigo após "Limpar filtros" | texto do campo não sincronizado | `didUpdateWidget` |
| `setState() called during build` ao carregar | `notifyListeners` antes do primeiro `await` em `initState` | status nasce `loading` e notifica só depois |
| `multiple heroes share the same tag` | mesmo cartão em duas abas | `heroOrigin: 'explore'` |
| Teste vê 2 cartões em vez de 4 | lista lazy em tela de 800 px | tela alta no teste |
| Sort instável em empate | `List.sort` não é estável | desempate por nome |

## 8.3 Outras opções do ecossistema

| Necessidade | Opções |
|---|---|
| Debounce | `Timer` (usado aqui), `rxdart` (`debounceTime`), `easy_debounce` |
| Estado derivado | `ProxyProvider`, Riverpod (`Provider` derivado), `signals` |
| Busca em lista grande | SQL com `LIKE`/FTS no SQLite, busca no servidor |
| Normalização de acentos | pacote `diacritic` |

---

# Parte 9: Aplicando no seu projeto

## 9.1 Adaptando ao tema do seu aplicativo

| Tema | Campos de busca | Filtros | Ordenações |
|---|---|---|---|
| Catálogo de cursos | título, instrutor | nível, duração, gratuito | mais recentes, nota, título |
| Imobiliária estudantil | título, bairro | quartos, aceita pets | menor aluguel, mais perto |
| Receitas | título, ingrediente | tempo de preparo, dificuldade | mais rápidas, nota |
| Clínicas | nome, especialidade | aceita convênio, bairro | mais perto, nota |
| Vagas de estágio | cargo, empresa | modalidade, bolsa | prazo, bolsa |

## 9.2 Checklist de aplicação

- [ ] **Consulta imutável:** um objeto com `copyWith`, `==`, `hashCode` e `cleared()`.
- [ ] **Função pura** de filtragem/ordenação no domínio, com semântica E/OU documentada.
- [ ] **Busca sem acento** e por várias palavras.
- [ ] **Controlador** guardando só catálogo + filtros + status (`enum`), sem a lista filtrada.
- [ ] **Lista derivada** no `build` com `watch` das fontes necessárias.
- [ ] **Debounce** com `Timer` cancelado e liberado no `dispose`; campo sincronizado.
- [ ] **Filtros em `Wrap`**, `liveRegion` na contagem, estado vazio com saída.
- [ ] **`heroOrigin`** distinto por aba.
- [ ] **Atalhos** de outras telas via controlador compartilhado + *callback* de navegação.
- [ ] **Testes:** unidade (função e controlador), widget (debounce, vazio, acessibilidade) e integração.

## 9.3 Desafios opcionais

1. **Foco na busca:** ao tocar em "Buscar produtos ou lugares" na Home, focar o campo de Explorar.
2. **Lembrar os filtros:** persistir `ExploreFilters` com `shared_preferences` e restaurar ao abrir o app.
3. **Buscas recentes:** guardar as últimas 5 buscas em SQLite (nova tabela, migração `v3`).
4. **Contador no chip de filtros:** mostrar `filters.activeCount` num botão "Filtros (3)".
5. **Filtro "aberto agora":** usar `EstablishmentDetails.openPeriodAt` (exige carregar detalhes: discuta o custo e a alternativa de pré-calcular).

---

# Apêndice A: Solução de problemas comuns

| Sintoma / mensagem | Causa provável | Como corrigir |
|---|---|---|
| `ProviderNotFoundException: Could not find the correct Provider<ExploreController>` | Faltou o provedor no `MultiProvider` ou no helper de testes | Adicione-o acima do `MaterialApp` e em `pumpWithProfile` |
| `A Timer is still pending even after the widget tree was disposed` (teste) | O debounce disparou depois do fim do teste | Avance o relógio (`pump(Duration)`) ou termine com `pumpAndSettle` |
| `setState() or markNeedsBuild() called during build` | `notifyListeners` síncrono dentro do `initState` | Não notifique antes do primeiro `await` |
| `findsNWidgets(4)` acha 2 | Lista lazy em tela baixa | Aumente `tester.view.physicalSize` |
| Chips estouram a tela | `Row`/rolagem horizontal com fonte grande | Use `Wrap` |
| "Atende ao meu perfil" esvazia tudo | Perfil sem restrições | Exibir o chip só com `profile.isComplete` |

---

# Apêndice B: Glossário desta etapa

- **Objeto de valor (*value object*):** objeto definido pelo conteúdo, não pela identidade; normalmente imutável, com `==` e `hashCode` próprios.
- **Função pura:** função cujo resultado depende só dos argumentos e que não causa efeitos colaterais.
- **Estado derivado:** informação calculada a partir de outros dados em vez de armazenada.
- **Fonte única da verdade:** cada fato tem um único dono; cópias são evitadas.
- **Debounce:** técnica que adia uma ação até que cessem novos eventos por um intervalo.
- **Throttle:** técnica que limita a quantidade de execuções por intervalo.
- **`didUpdateWidget`:** método de ciclo de vida do `State` chamado quando o widget pai fornece novos parâmetros.
- **`liveRegion`:** marcação semântica para que leitores de tela anunciem automaticamente mudanças de um texto.
- **`FilterChip`:** chip selecionável do Material, com estado ligado/desligado.
- **Lista *lazy*:** lista que só constrói os itens próximos da área visível (`SliverList`, `ListView.builder`).
- **Rede de segurança (testes):** suíte existente que permite refatorar com confiança.
