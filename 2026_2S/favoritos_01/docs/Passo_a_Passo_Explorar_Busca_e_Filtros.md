# Passo a Passo — Aba Explorar (Busca, Filtros e Ordenação) no `favoritos_01`

Guia de aula para implementar, com os alunos, a feature **Explorar** sobre o projeto `favoritos_01`. É a adaptação do laboratório `celilac/docs/tutorials/lab_explorar_busca_filtros` (7 etapas) ao ponto onde o `favoritos_01` está: estado compartilhado com `provider`, em memória, sem perfil alimentar.

**Como usar:** cada passo tem **Problema → Conceito → Código → Verificação**. O código está completo e na ordem em que deve ser digitado. O projeto **compila e roda ao final de cada passo** (os pontos em que algo fica temporariamente "meio-termo" estão avisados).

> Pacote: `favoritos_01`. Todos os imports de teste usam `package:favoritos_01/...`.

---

## Sumário

0. [Diagnóstico e decisões](#0-diagnóstico-e-decisões)
1. [Domínio: enums e campos novos](#passo-1--domínio-enums-e-campos-novos-pré-requisito)
2. [Catálogo assíncrono com 12 lugares](#passo-2--catálogo-assíncrono-com-12-lugares)
3. [Estado de consulta imutável (`ExploreFilters`)](#passo-3--estado-de-consulta-imutável-explorefilters)
4. [Filtragem e ordenação como função pura](#passo-4--filtragem-e-ordenação-como-função-pura)
5. [`ExploreController` e estado derivado](#passo-5--explorecontroller-e-estado-derivado)
6. [Busca com *debounce*](#passo-6--busca-com-debounce)
7. [Interface: chips, barra de resultados e `ExplorePage`](#passo-7--interface-chips-barra-de-resultados-e-explorepage)
8. [Home e `AppShell`](#passo-8--home-e-appshell)
9. [Testes](#passo-9--testes)
10. [Checklist final, roteiro de demonstração e desafios](#checklist-final)

---

## 0. Diagnóstico e decisões

### 0.1 Onde o `favoritos_01` está × o que o lab exige

| Item | `favoritos_01` hoje | O que o lab assume | Ação |
|---|---|---|---|
| `Establishment.category` | `String` | `enum EstablishmentCategory` com `label` | Converter (Passo 1) |
| `distanceInKm`, `dietaryOptions` | não existem | existem | Adicionar (Passo 1) |
| Catálogo | 3 itens em `sample_establishments.dart` | 12 itens, via repositório assíncrono | Repositório fake (Passo 2) |
| Abas | Início, Favoritos | Início, **Explorar**, Favoritos | Adicionar aba (Passo 8) |
| Perfil alimentar (`ProfileController`) | não existe | filtro "Atende ao meu perfil" | **Fora de escopo**: sem o filtro e sem `meetsProfile` |
| `AppColors`, `AppSpacing`, `StatusMessage` | não existem | usados nas telas | Usar `Theme` + constantes locais; criar um `StatusMessage` simples |
| `Hero` / `heroOrigin` | não existe | evita colisão de tags | **Não se aplica** |
| Favoritar com feedback | `toggle` síncrono e sem `SnackBar` | `toggleFavoriteWithFeedback` | Versão simples com `SnackBar` (Passo 7) |
| Testes | pasta `test/` não existe | suíte com 38+ testes | Criar (Passo 9) |

### 0.2 Problemas que já existem no projeto (corrigidos no caminho)

1. **`EstablishmentCard` ignora o `onTap` recebido**: o `ListTile` empilha `EstablishmentDetailsPage` por conta própria. (Passo 7)
2. **`FavoritesPage` usa `context.read`** para ler a lista, então não reconstrói quando outra aba favorita algo. É exatamente a "lista velha" da Etapa 3 do lab. (Passo 7)
3. **"Ver estabelecimentos" em Favoritos leva ao índice 0** (Início). Deve levar a Explorar. (Passo 8)
4. Comentários `PROBLEMA DIDÁTICO AQUI` ficaram desatualizados e são removidos nos arquivos tocados.

### 0.3 Decisões de projeto (já tomadas)

| # | Decisão | Motivo |
|---|---|---|
| D1 | A Home **lê o catálogo do `ExploreController`** e mostra só os **4 mais próximos** em "Perto de você". | Uma única fonte de dados; a Home vira consumidora do mesmo estado. "Ver todos" leva a Explorar. |
| D2 | A Home ganha um **cabeçalho mínimo**: botão de busca, atalhos de categoria e "Ver todos". | Sem isso, não há de onde partir o fluxo Home → Explorar (Passo 8). |
| D3 | `sample_establishments.dart` é **removido** e substituído por `fake_establishment_repository.dart`. | O repositório assíncrono é o que permite ensinar `loading/failure/ready`. |
| D4 | Os nomes dos 3 primeiros lugares passam a ser os do CeliLac (Café Aconchego, Padaria Leve Grão, Bistrô Bem-Estar). | Os testes e os exemplos do material assumem esses nomes. |
| D5 | O campo de id continua se chamando **`establishmentId`** (não renomear para `id`). | Evita mexer em código que já funciona. |

### 0.4 Estrutura final esperada

```text
lib/
├── app/
│   ├── common/status_message.dart                 (novo)
│   ├── lab_app.dart                               (MultiProvider)
│   └── shell/app_shell.dart                       (3 abas)
└── features/
    ├── establishments/
    │   ├── data/fake_establishment_repository.dart        (novo; substitui sample_establishments.dart)
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   ├── dietary_option.dart                    (novo)
    │   │   │   ├── establishment_category.dart            (novo)
    │   │   │   └── establishment.dart                     (alterado)
    │   │   └── repositories/establishment_repository.dart (novo)
    │   └── presentation/{pages/establishment_details_page.dart, widgets/establishment_card.dart} (ajustes)
    ├── explore/
    │   ├── domain/{explore_sort,explore_filters,search_text,explore_query}.dart
    │   └── presentation/
    │       ├── explore_controller.dart
    │       ├── pages/explore_page.dart
    │       └── widgets/{explore_search_field,explore_filter_chips,explore_results_bar}.dart
    ├── favorites/presentation/{toggle_favorite.dart (novo), pages/favorites_page.dart (alterado)}
    └── home/presentation/pages/home_page.dart         (reescrita)
test/
├── support/{explore_catalog,pump_app,stub_establishment_repository}.dart
├── features/explore/{search_text,explore_query,explore_controller,explore_page}_test.dart
└── app/app_shell_test.dart
```

### 0.5 Preparação

```bash
cd favoritos_01
flutter pub get
flutter analyze        # deve estar limpo antes de começar
flutter run
```

Confirme com a turma o comportamento atual: favoritar na Home atualiza o coração do detalhe e a aba Favoritos. É a base que vamos reaproveitar.

---

## Passo 1 — Domínio: enums e campos novos (pré-requisito)

**Problema.** Filtrar por `String category` é frágil: um erro de digitação ("Padria") vira uma categoria nova e o compilador não avisa. Além disso, sem `distanceInKm` e `dietaryOptions` não há o que filtrar nem ordenar.

**Conceito.** `enum` com campo `label`: o valor é seguro para o código, o texto é para a tela. `Set<DietaryOption>` guarda "o que o lugar oferece" sem duplicatas.

### 1.1 `lib/features/establishments/domain/entities/establishment_category.dart` (novo)

```dart
enum EstablishmentCategory {
  restaurant('Restaurante'),
  bakery('Padaria'),
  cafe('Café'),
  market('Mercado');

  const EstablishmentCategory(this.label);

  final String label;
}
```

### 1.2 `lib/features/establishments/domain/entities/dietary_option.dart` (novo)

```dart
enum DietaryOption {
  glutenFree('Sem glúten'),
  lactoseFree('Sem lactose');

  const DietaryOption(this.label);

  final String label;
}
```

### 1.3 `lib/features/establishments/domain/entities/establishment.dart` (substituir)

```dart
import 'dietary_option.dart';
import 'establishment_category.dart';

class Establishment {
  const Establishment({
    required this.establishmentId,
    required this.name,
    required this.category,
    required this.neighborhood,
    required this.distanceInKm,
    required this.rating,
    required this.dietaryOptions,
  });

  final String establishmentId;
  final String name;
  final EstablishmentCategory category;
  final String neighborhood;
  final double distanceInKm;
  final double rating;
  final Set<DietaryOption> dietaryOptions;
}
```

### 1.4 Ajustar quem usa `category` como texto

Em `establishment_card.dart`, no `subtitle`:

```dart
subtitle: Text(
  '${item.category.label} · ${item.neighborhood} · ★ ${item.rating}',
),
```

Em `establishment_details_page.dart`:

```dart
Text('${establishment.category.label} · ${establishment.neighborhood}'),
```

### 1.5 Atualizar temporariamente `sample_establishments.dart`

Para o projeto continuar compilando até o Passo 8, atualize os 3 itens (o arquivo será apagado no Passo 8):

```dart
import '../domain/entities/dietary_option.dart';
import '../domain/entities/establishment.dart';
import '../domain/entities/establishment_category.dart';

const sampleEstablishments = <Establishment>[
  Establishment(
    establishmentId: '1',
    name: 'Café Aconchego',
    category: EstablishmentCategory.cafe,
    neighborhood: 'Centro',
    distanceInKm: 0.35,
    rating: 4.8,
    dietaryOptions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
  ),
  Establishment(
    establishmentId: '2',
    name: 'Padaria Leve Grão',
    category: EstablishmentCategory.bakery,
    neighborhood: 'Jardim das Flores',
    distanceInKm: 1.2,
    rating: 4.6,
    dietaryOptions: {DietaryOption.glutenFree},
  ),
  Establishment(
    establishmentId: '3',
    name: 'Bistrô Bem-Estar',
    category: EstablishmentCategory.restaurant,
    neighborhood: 'Bela Vista',
    distanceInKm: 2.4,
    rating: 4.7,
    dietaryOptions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
  ),
];
```

**Verificação:** `flutter analyze` limpo; o app roda igual a antes (cartões mostram "Café · Centro · ★ 4.8").

---

## Passo 2 — Catálogo assíncrono com 12 lugares

**Problema.** Com 3 itens, filtrar e ordenar não mostra nada. E uma lista `const` não permite demonstrar carregamento e erro.

**Conceito.** Contrato de repositório (`abstract interface class`) + implementação fake com atraso que simula rede. O `ExploreController` (Passo 5) só conhece o contrato.

### 2.1 `lib/features/establishments/domain/repositories/establishment_repository.dart` (novo)

```dart
import '../entities/establishment.dart';

abstract interface class EstablishmentRepository {
  /// Estabelecimentos próximos. Pode demorar e pode falhar.
  Future<List<Establishment>> fetchNearby();
}
```

### 2.2 `lib/features/establishments/data/fake_establishment_repository.dart` (novo)

```dart
import '../domain/entities/dietary_option.dart';
import '../domain/entities/establishment.dart';
import '../domain/entities/establishment_category.dart';
import '../domain/repositories/establishment_repository.dart';

class FakeEstablishmentRepository implements EstablishmentRepository {
  const FakeEstablishmentRepository({
    this.delay = const Duration(milliseconds: 800),
  });

  /// Simula a rede. Nos testes usamos [Duration.zero].
  final Duration delay;

  static const List<Establishment> _establishments = [
    Establishment(
      establishmentId: '1',
      name: 'Café Aconchego',
      category: EstablishmentCategory.cafe,
      neighborhood: 'Centro',
      distanceInKm: 0.35,
      rating: 4.8,
      dietaryOptions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
    ),
    Establishment(
      establishmentId: '2',
      name: 'Padaria Leve Grão',
      category: EstablishmentCategory.bakery,
      neighborhood: 'Jardim das Flores',
      distanceInKm: 1.2,
      rating: 4.6,
      dietaryOptions: {DietaryOption.glutenFree},
    ),
    Establishment(
      establishmentId: '3',
      name: 'Bistrô Bem-Estar',
      category: EstablishmentCategory.restaurant,
      neighborhood: 'Bela Vista',
      distanceInKm: 2.4,
      rating: 4.7,
      dietaryOptions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
    ),
    Establishment(
      establishmentId: '4',
      name: 'Empório Natural',
      category: EstablishmentCategory.market,
      neighborhood: 'Vila Nova',
      distanceInKm: 3.1,
      rating: 4.5,
      dietaryOptions: {DietaryOption.lactoseFree},
    ),
    Establishment(
      establishmentId: '5',
      name: 'Cozinha da Vó Lúcia',
      category: EstablishmentCategory.restaurant,
      neighborhood: 'Zona 7',
      distanceInKm: 0.8,
      rating: 4.4,
      dietaryOptions: {DietaryOption.glutenFree},
    ),
    Establishment(
      establishmentId: '6',
      name: 'Pão de Quinoa',
      category: EstablishmentCategory.bakery,
      neighborhood: 'Centro',
      distanceInKm: 0.6,
      rating: 4.9,
      dietaryOptions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
    ),
    Establishment(
      establishmentId: '7',
      name: 'Café Grão Leve',
      category: EstablishmentCategory.cafe,
      neighborhood: 'Zona 7',
      distanceInKm: 1.9,
      rating: 4.2,
      dietaryOptions: {DietaryOption.lactoseFree},
    ),
    Establishment(
      establishmentId: '8',
      name: 'Mercado Vida Simples',
      category: EstablishmentCategory.market,
      neighborhood: 'Jardim das Flores',
      distanceInKm: 1.5,
      rating: 4.3,
      dietaryOptions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
    ),
    Establishment(
      establishmentId: '9',
      name: 'Trattoria Sem Trigo',
      category: EstablishmentCategory.restaurant,
      neighborhood: 'Vila Nova',
      distanceInKm: 2.8,
      rating: 4.6,
      dietaryOptions: {DietaryOption.glutenFree},
    ),
    Establishment(
      establishmentId: '10',
      name: 'Doce Pureza Confeitaria',
      category: EstablishmentCategory.bakery,
      neighborhood: 'Bela Vista',
      distanceInKm: 3.4,
      rating: 4.7,
      dietaryOptions: {DietaryOption.lactoseFree},
    ),
    Establishment(
      establishmentId: '11',
      name: 'Café Pé de Serra',
      category: EstablishmentCategory.cafe,
      neighborhood: 'Bela Vista',
      distanceInKm: 4.2,
      rating: 4.1,
      dietaryOptions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
    ),
    Establishment(
      establishmentId: '12',
      name: 'Empório da Terra',
      category: EstablishmentCategory.market,
      neighborhood: 'Zona 7',
      distanceInKm: 5.0,
      rating: 4.0,
      dietaryOptions: {DietaryOption.glutenFree},
    ),
  ];

  @override
  Future<List<Establishment>> fetchNearby() async {
    await Future<void>.delayed(delay);
    return _establishments;
  }
}
```

> Os dados têm **bairros repetidos** (Zona 7, Centro, Bela Vista), **categorias repetidas** e **combinações diferentes de opções**, para que cada filtro tenha efeito visível.

**Verificação:** `flutter analyze` limpo. Ainda nada novo na tela (a Home usa `sampleEstablishments`).

---

## Passo 3 — Estado de consulta imutável (`ExploreFilters`)

**Problema.** O primeiro instinto é uma variável por critério no `State`:

```dart
String _query = '';
final Set<EstablishmentCategory> _categories = {};
final Set<DietaryOption> _dietary = {};
bool _onlyFavorites = false;
ExploreSort _sort = ExploreSort.distance;
```

Funciona para um filtro. A dor aparece ao **limpar tudo**, **contar filtros ativos**, **comparar "mudou?"**, **entregar o conjunto à Home** e **testar sem abrir a tela**.

*Para provocar ao vivo:* peça aos alunos `_clearAll()`, `_activeCount` e `_isDefault` com variáveis soltas. Pergunte: "se amanhã surgir 'aberto agora', em quantos lugares preciso lembrar dele?" e "limpar filtros deve zerar a ordenação?" (não: ordenar não esconde nada, é preferência de visualização).

**Conceito.**
- **Objeto de valor imutável:** todos os campos `final`, construtor `const`, `==`/`hashCode` por conteúdo.
- **`copyWith`:** em vez de mudar um campo, devolve uma cópia (`query ?? this.query`).
- **`Set` não compara por conteúdo** no `==` padrão: comparamos `length` + `containsAll`; o `hashCode` usa `Object.hashAllUnordered` (a ordem de inserção não pode mudar o hash).
- O que conta como "filtro":

| Campo | Esconde lugares? | Conta em `activeCount`? |
|---|---|---|
| `query` | sim (se não vazio) | sim |
| `categories` | sim | uma por categoria |
| `dietaryOptions` | sim | uma por opção |
| `onlyFavorites` | sim | sim |
| `sort` | **não** | **não** |

### 3.1 `lib/features/explore/domain/explore_sort.dart`

```dart
enum ExploreSort {
  distance('Mais perto'),
  rating('Melhor nota'),
  name('Nome (A–Z)');

  const ExploreSort(this.label);

  final String label;
}
```

### 3.2 `lib/features/explore/domain/explore_filters.dart`

```dart
import '../../establishments/domain/entities/dietary_option.dart';
import '../../establishments/domain/entities/establishment_category.dart';
import 'explore_sort.dart';

class ExploreFilters {
  const ExploreFilters({
    this.query = '',
    this.categories = const {},
    this.dietaryOptions = const {},
    this.onlyFavorites = false,
    this.sort = ExploreSort.distance,
  });

  static const ExploreFilters initial = ExploreFilters();

  final String query;
  final Set<EstablishmentCategory> categories;
  final Set<DietaryOption> dietaryOptions;
  final bool onlyFavorites;
  final ExploreSort sort;

  int get activeCount =>
      (query.trim().isEmpty ? 0 : 1) +
      categories.length +
      dietaryOptions.length +
      (onlyFavorites ? 1 : 0);

  bool get hasActiveFilters => activeCount > 0;

  /// Volta tudo ao início, mas mantém a ordenação que a pessoa escolheu.
  ExploreFilters cleared() => ExploreFilters(sort: sort);

  ExploreFilters copyWith({
    String? query,
    Set<EstablishmentCategory>? categories,
    Set<DietaryOption>? dietaryOptions,
    bool? onlyFavorites,
    ExploreSort? sort,
  }) {
    return ExploreFilters(
      query: query ?? this.query,
      categories: categories ?? this.categories,
      dietaryOptions: dietaryOptions ?? this.dietaryOptions,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      sort: sort ?? this.sort,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExploreFilters &&
        other.query == query &&
        other.categories.length == categories.length &&
        other.categories.containsAll(categories) &&
        other.dietaryOptions.length == dietaryOptions.length &&
        other.dietaryOptions.containsAll(dietaryOptions) &&
        other.onlyFavorites == onlyFavorites &&
        other.sort == sort;
  }

  @override
  int get hashCode => Object.hash(
    query,
    Object.hashAllUnordered(categories),
    Object.hashAllUnordered(dietaryOptions),
    onlyFavorites,
    sort,
  );
}
```

**Pontos de atenção para a aula**
- `static const initial` é a "consulta vazia" compartilhada.
- `const {}` como padrão: conjuntos constantes são imutáveis; quem quiser adicionar cria **outro** conjunto (`{...atual, novo}`), como no Passo 5.
- `copyWith` não consegue voltar um campo para `null`; aqui nenhum campo é anulável, então não há problema.
- **Nenhum `import` de Flutter** neste arquivo.

**Verificação:** `flutter analyze`. Os testes deste passo estão no Passo 9 (`explore_query_test.dart`, grupo `ExploreFilters`); se quiser testar já, crie `test/features/explore/explore_query_test.dart` só com esse grupo.

---

## Passo 4 — Filtragem e ordenação como função pura

**Problema.** Com a regra escrita direto no `build`, só dá para testar abrindo a tela; o `build` fica enorme; e é fácil fazer `catalog.sort(...)` e **alterar a lista original** compartilhada. Pergunta para a turma: "como garanto que *Bistrô* aparece quando digito *bistro*?". Se a resposta é "abrir o app e testar", a regra está no lugar errado.

**Conceito.**
- **Função pura:** mesmos argumentos → mesmo resultado; sem efeitos colaterais, sem `BuildContext`, sem `Provider`, sem relógio.
- **Semântica dos filtros (decisão de produto):**

| Grupo | Regra | Exemplo |
|---|---|---|
| Entre grupos | **E** | "Café" **E** "Sem glúten" |
| Categorias | **OU** dentro do grupo | "Café" **ou** "Mercado" |
| Opções alimentares | **E** dentro do grupo (`containsAll`) | "Sem glúten" **e** "Sem lactose" |
| Texto | **todas** as palavras precisam aparecer | "cafe centro" |

  Por que opções são **E**? Quem escolhe "Sem glúten" e "Sem lactose" precisa de lugares que atendam às **duas** restrições.
- **Normalização:** "Bistrô", "BISTRO" e "bistro" devem casar: `trim` → minúsculas → trocar acentos. Um mapa pequeno dispensa dependência (alternativa: pacote `diacritic`).
- **`List.sort` não é estável:** dois lugares com a mesma distância podem trocar de ordem. Solução: **desempate pelo nome**.
- **Não alterar o catálogo:** `where(...).toList()` cria uma lista nova; só ela é ordenada.

### 4.1 `lib/features/explore/domain/search_text.dart`

```dart
const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c',
};

/// "  Bistrô " -> "bistro". Usada na busca para ignorar acento e maiúscula.
String normalizeSearchText(String text) {
  // toLowerCase primeiro: o mapa só precisa das letras minúsculas.
  final lower = text.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final character in lower.split('')) {
    buffer.write(_accents[character] ?? character);
  }
  return buffer.toString();
}
```

### 4.2 `lib/features/explore/domain/explore_query.dart`

```dart
import '../../establishments/domain/entities/establishment.dart';
import 'explore_filters.dart';
import 'explore_sort.dart';
import 'search_text.dart';

/// Devolve os lugares que passam em [filters], já ordenados.
///
/// Função pura: tudo o que a regra precisa entra por parâmetro e a resposta
/// sai pelo retorno. Não altera [catalog].
List<Establishment> applyExploreFilters(
  List<Establishment> catalog,
  ExploreFilters filters, {
  required Set<String> favoriteIds,
}) {
  final words = normalizeSearchText(
    filters.query,
  ).split(' ').where((word) => word.isNotEmpty).toList();

  bool matches(Establishment e) {
    if (filters.categories.isNotEmpty &&
        !filters.categories.contains(e.category)) {
      return false;
    }
    // containsAll com conjunto vazio é true: sem opção escolhida, todo lugar passa.
    if (!e.dietaryOptions.containsAll(filters.dietaryOptions)) {
      return false;
    }
    if (filters.onlyFavorites && !favoriteIds.contains(e.establishmentId)) {
      return false;
    }
    if (words.isEmpty) return true;

    final haystack = normalizeSearchText(
      '${e.name} ${e.neighborhood} ${e.category.label}',
    );
    return words.every(haystack.contains);
  }

  // where(...).toList() cria uma lista nova: o catálogo original fica intacto.
  final results = catalog.where(matches).toList();
  results.sort(_comparatorFor(filters.sort));
  return results;
}

Comparator<Establishment> _comparatorFor(ExploreSort sort) {
  int byName(Establishment a, Establishment b) =>
      normalizeSearchText(a.name).compareTo(normalizeSearchText(b.name));

  return switch (sort) {
    ExploreSort.distance => (a, b) {
      final result = a.distanceInKm.compareTo(b.distanceInKm);
      return result != 0 ? result : byName(a, b);
    },
    ExploreSort.rating => (a, b) {
      final result = b.rating.compareTo(a.rating); // maior nota primeiro
      return result != 0 ? result : byName(a, b);
    },
    ExploreSort.name => byName,
  };
}
```

**Pontos de atenção**
- O `switch` é uma **expressão** sobre o `enum`: se criarmos `ExploreSort.price`, o compilador acusa o caso que falta.
- O "palheiro" junta **nome + bairro + tipo**: "vila nova" e "padaria" funcionam.
- A função não importa Flutter nem `provider`.

**Verificação:** teste rápido no `main` de um arquivo de teste (formato completo no Passo 9):

```dart
test('acha por nome sem depender de acento ou maiúscula', () {
  expect(_ids(const ExploreFilters(query: 'bistro')), ['3']);
});
```

---

## Passo 5 — `ExploreController` e estado derivado

**Problema.** O resultado da tela depende de **três** fontes: catálogo (repositório), filtros (a própria tela) e favoritos (`FavoritesController`). A tentação é guardar o resultado num `List<Establishment> _visible`. Dor, ao vivo:

1. Em Explorar, ligue **"Só favoritos"**.
2. Vá à aba Início e favorite um lugar novo.
3. Volte a Explorar: a lista **não mostra o lugar novo**, porque ninguém recalculou `_visible`.

Guardar o resultado cria uma **cópia que envelhece**. Regra para o quadro: **se um dado pode ser calculado a partir de outros, não o guarde.**

**Conceito.**

| | Guardado | Derivado |
|---|---|---|
| Exemplo | `filters`, `catalog`, `status` | lista visível, contagem "8 lugares" |
| Onde vive | `ChangeNotifier` | `build` (ou getter) |

- Recalcular a cada `build` é aceitável quando o cálculo é **rápido** (dezenas/centenas de itens) e **puro**. Para milhares, memorizar ou filtrar no banco.
- Alternativas: `context.select` (reconstruir só quando um valor muda) e `ChangeNotifierProxyProvider` (objeto que depende de outros provedores).
- **`enum ExploreStatus { loading, ready, failure }`** impede combinações impossíveis (`isLoading` e `hasError` juntos) e o `switch` exaustivo obriga a tela a tratar os três casos.
- **Não notificar sem mudança:** `ExploreFilters` tem `==`, então `_update` ignora valores iguais.
- **`notifyListeners` durante o `build` é proibido:** a tela chama `load()` no `initState`; o `status` já nasce `loading` e só notificamos **depois** do `await`.
- **Copiar `Set`s, nunca alterar:** alterar o `Set` do `ExploreFilters` anterior quebraria `next == _filters` (os dois apontariam para o mesmo conjunto).

### 5.1 `lib/features/explore/presentation/explore_controller.dart`

```dart
import 'package:flutter/foundation.dart';

import '../../establishments/domain/entities/dietary_option.dart';
import '../../establishments/domain/entities/establishment.dart';
import '../../establishments/domain/entities/establishment_category.dart';
import '../../establishments/domain/repositories/establishment_repository.dart';
import '../domain/explore_filters.dart';
import '../domain/explore_sort.dart';

enum ExploreStatus { loading, ready, failure }

/// Guarda o catálogo e as escolhas de filtro. Não guarda a lista filtrada:
/// ela é calculada na tela, juntando este estado com os favoritos.
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
    _update(
      _filters.copyWith(categories: _toggled(_filters.categories, category)),
    );
  }

  void toggleDietaryOption(DietaryOption option) {
    _update(
      _filters.copyWith(
        dietaryOptions: _toggled(_filters.dietaryOptions, option),
      ),
    );
  }

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

  /// Devolve um conjunto novo; nunca altera [current].
  Set<T> _toggled<T>(Set<T> current, T item) {
    return current.contains(item)
        ? ({...current}..remove(item))
        : {...current, item};
  }
}
```

**Pontos de atenção**
- `_loading ??= _load()` garante **uma** carga mesmo que Home e Explorar peçam; `retry()` faz de propósito uma nova.
- `List.unmodifiable` impede que a tela altere o catálogo por engano.
- O controlador **não conhece** favoritos: quem junta as fontes é a tela (no `build`).

### 5.2 Registrar o provedor — `lib/app/lab_app.dart` (substituir)

Trocamos o `ChangeNotifierProvider` único por um `MultiProvider`, **acima** do `MaterialApp`.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/establishments/data/fake_establishment_repository.dart';
import '../features/explore/presentation/explore_controller.dart';
import '../features/favorites/presentation/favorites_controller.dart';
import 'shell/app_shell.dart';

class LabApp extends StatelessWidget {
  const LabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FavoritesController>(
          create: (_) => FavoritesController(),
        ),
        ChangeNotifierProvider<ExploreController>(
          create: (_) => ExploreController(const FakeEstablishmentRepository()),
        ),
      ],
      child: MaterialApp(
        title: 'Lab Favoritos',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const AppShell(),
      ),
    );
  }
}
```

Por que não criar o controlador dentro da `ExplorePage`? Porque a **Home** também vai usá-lo (Passo 8) e a página vive numa aba que pode ser reconstruída; o provedor no topo preserva o estado.

**Verificação:** `flutter analyze` limpo; o app continua igual (ninguém consome o `ExploreController` ainda).

---

## Passo 6 — Busca com *debounce*

**Problema.** `TextField(onChanged: explore.setQuery)` recalcula e redesenha a lista **a cada letra**. Digitar "padaria" dispara 7 filtragens. E há uma dor menos óbvia: o texto vive no `TextEditingController`, mas a "verdade" da busca vive em `ExploreFilters.query`. Se "Limpar filtros" (ou um atalho da Home) zerar a busca no controlador, o campo continua mostrando o texto antigo: o app mente.

*Para provocar ao vivo:* coloque um `debugPrint('filtrou')` em `applyExploreFilters`, digite "padaria" (7 mensagens); depois, com o campo preenchido, toque em "Limpar filtros": a lista volta, mas o campo ainda diz "padaria".

**Conceito.**
- **Debounce × throttle:** debounce espera **silêncio** (cada entrada reinicia a contagem), bom para busca; throttle deixa passar no máximo 1 evento por intervalo, bom para rolagem.
- **`Timer`:** `_timer?.cancel(); _timer = Timer(delay, ...)`. Só o **último** agendamento executa.
- **Quem é dono do quê:** `TextEditingController` e `Timer` são do `State` (criar e **descartar**); `ExploreFilters.query` é do controlador. Todo `Timer` criado precisa ser cancelado no `dispose`, senão pode disparar depois que a tela saiu da árvore.
- **`didUpdateWidget`:** chamado quando o pai reconstrói o widget com novos parâmetros. A condição `widget.query != _controller.text` evita um laço: quando o próprio debounce atualiza o estado, o `query` oficial passa a ser igual ao digitado e **não** reescrevemos o campo (o que moveria o cursor).

### 6.1 `lib/features/explore/presentation/widgets/explore_search_field.dart`

```dart
import 'dart:async';

import 'package:flutter/material.dart';

/// Campo de busca que só avisa a tela depois que a pessoa para de digitar.
/// Sem isso, a lista seria recalculada a cada letra.
class ExploreSearchField extends StatefulWidget {
  const ExploreSearchField({
    super.key,
    required this.query,
    required this.onChanged,
    this.debounce = const Duration(milliseconds: 300),
  });

  /// O texto "oficial", vindo do controlador.
  final String query;
  final ValueChanged<String> onChanged;
  final Duration debounce;

  @override
  State<ExploreSearchField> createState() => _ExploreSearchFieldState();
}

class _ExploreSearchFieldState extends State<ExploreSearchField> {
  // late: permite usar `widget` no inicializador.
  late final TextEditingController _controller = TextEditingController(
    text: widget.query,
  );
  Timer? _timer;

  @override
  void didUpdateWidget(ExploreSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // O estado mudou "por fora" (ex.: Limpar filtros): o campo acompanha.
    if (widget.query != oldWidget.query && widget.query != _controller.text) {
      _timer?.cancel();
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onChanged(text));
    setState(() {}); // mostra ou esconde o botão de limpar na hora
  }

  void _clear() {
    // Apagar não precisa de espera: cancela o timer e avisa já.
    _timer?.cancel();
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar por nome, bairro ou tipo',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpar busca',
                icon: const Icon(Icons.close),
                onPressed: _clear,
              ),
        filled: true,
        fillColor: colors.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
```

**Pontos de atenção**
- `debounce` é **parâmetro** (padrão 300 ms): nos testes avançamos o relógio com `pump(Duration)`.
- `_clear` **cancela** o timer e avisa na hora.
- O `setState(() {})` serve só para o `suffixIcon`; o texto em si é do `TextEditingController`.
- `TextInputAction.search` mostra a lupa no teclado.

**Verificação:** o widget só será visto no Passo 7; o teste do debounce está no Passo 9.

---

## Passo 7 — Interface: chips, barra de resultados e `ExplorePage`

**Problema.** Uma tela de filtros tem armadilhas próprias:
1. **Chips numa fileira com rolagem horizontal** escondem opções: com fonte a 200%, "Mercado" some para fora da tela e ninguém sabe que existe.
2. **Lista vazia sem saída:** "Nenhum resultado" sem botão para desfazer os filtros deixa a pessoa presa.
3. **Contagem muda em silêncio:** quem usa leitor de tela não percebe que "8 lugares" virou "2".
4. **Três estados do catálogo** (carregando, erro, pronto) mais o vazio.
5. **Favoritar duplicado:** o mesmo código de favoritar seria copiado na Home, em Explorar e em Favoritos.

*Para provocar ao vivo:* monte os chips em `SingleChildScrollView(scrollDirection: Axis.horizontal)`, aumente a fonte do aparelho ao máximo e veja as últimas opções fora da tela, sem pista visual.

**Conceito.**
- **`Wrap` em vez de rolagem horizontal:** quebra para a linha de baixo; `spacing` = espaço horizontal, `runSpacing` = vertical.
- **`FilterChip`:** tem `selected` + `onSelected`; o Flutter já anuncia "selecionado/não selecionado" ao leitor de tela e respeita a área mínima de toque.
- **`liveRegion`:** `Semantics(liveRegion: true, child: Text(...))` faz o leitor de tela anunciar sozinho quando o texto muda (equivalente do `aria-live`).
- **Estados da lista:**

| Estado | O que a tela mostra |
|---|---|
| `loading` | indicador de progresso |
| `failure` | mensagem + "Tentar novamente" |
| `ready` + vazio | mensagem + "Limpar filtros" (só se houver filtro ativo) |
| `ready` + itens | cartões |

- **Cabeçalho que rola junto com a lista:** `CustomScrollView` + `SliverList.list` (cabeçalho) + `SliverList.separated` (cartões, construídos sob demanda).
- **`SliverList` é lazy:** só constrói o que está perto da tela; isso muda como **testamos** (tela alta, Passo 9).
- **Widgets "burros":** `ExploreFilterChips` recebe estado e devolve eventos; quem fala com o controlador é a página.

### 7.1 `lib/app/common/status_message.dart` (novo)

```dart
import 'package:flutter/material.dart';

/// Mensagem centralizada para estados de erro e lista vazia, com ação opcional.
class StatusMessage extends StatelessWidget {
  const StatusMessage({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
```

### 7.2 `lib/features/explore/presentation/widgets/explore_filter_chips.dart`

```dart
import 'package:flutter/material.dart';

import '../../../establishments/domain/entities/dietary_option.dart';
import '../../../establishments/domain/entities/establishment_category.dart';
import '../../domain/explore_filters.dart';

/// Chips de filtro em `Wrap`: quebram de linha em vez de rolar para o lado,
/// então nenhuma opção fica escondida (fonte grande, tela pequena).
class ExploreFilterChips extends StatelessWidget {
  const ExploreFilterChips({
    super.key,
    required this.filters,
    required this.onCategoryToggle,
    required this.onDietaryToggle,
    required this.onFavoritesChanged,
  });

  final ExploreFilters filters;
  final ValueChanged<EstablishmentCategory> onCategoryToggle;
  final ValueChanged<DietaryOption> onDietaryToggle;
  final ValueChanged<bool> onFavoritesChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
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

### 7.3 `lib/features/explore/presentation/widgets/explore_results_bar.dart`

```dart
import 'package:flutter/material.dart';

import '../../domain/explore_sort.dart';

/// "8 lugares encontrados" + escolha da ordenação.
class ExploreResultsBar extends StatelessWidget {
  const ExploreResultsBar({
    super.key,
    required this.count,
    required this.sort,
    required this.onSortChanged,
  });

  final int count;
  final ExploreSort sort;
  final ValueChanged<ExploreSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Plural tratado à mão: "1 lugar" × "N lugares".
    final summary = switch (count) {
      0 => 'Nenhum lugar encontrado',
      1 => '1 lugar encontrado',
      _ => '$count lugares encontrados',
    };

    // Wrap: com fonte grande, a ordenação desce de linha em vez de estourar.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      children: [
        // liveRegion: leitores de tela anunciam a nova contagem sozinhos.
        Semantics(
          liveRegion: true,
          child: Text(
            summary,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
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
  }
}
```

### 7.4 `lib/features/favorites/presentation/toggle_favorite.dart` (novo)

Um só lugar para favoritar com feedback, usado na Home, em Explorar e em Favoritos.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../establishments/domain/entities/establishment.dart';
import 'favorites_controller.dart';

/// Alterna o favorito e avisa a pessoa com um SnackBar.
/// `read`: é uma ação disparada por toque, não uma leitura que redesenha.
void toggleFavoriteWithFeedback(
  BuildContext context,
  Establishment establishment,
) {
  final added = context.read<FavoritesController>().toggle(establishment);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          added
              ? '${establishment.name} salvo nos favoritos.'
              : '${establishment.name} removido dos favoritos.',
        ),
      ),
    );
}
```

> Aqui o `toggle` é síncrono e não falha. Se, mais adiante, o repositório de favoritos virar assíncrono (SQLite), este é o único lugar a ganhar `try/catch`.

### 7.5 `lib/features/explore/presentation/pages/explore_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/common/status_message.dart';
import '../../../establishments/domain/entities/establishment.dart';
import '../../../establishments/presentation/pages/establishment_details_page.dart';
import '../../../establishments/presentation/widgets/establishment_card.dart';
import '../../../favorites/presentation/favorites_controller.dart';
import '../../../favorites/presentation/toggle_favorite.dart';
import '../../domain/explore_query.dart';
import '../explore_controller.dart';
import '../widgets/explore_filter_chips.dart';
import '../widgets/explore_results_bar.dart';
import '../widgets/explore_search_field.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  static const double _padding = 16;

  @override
  void initState() {
    super.initState();
    // read: é uma ação, não uma leitura que redesenha a tela.
    context.read<ExploreController>().load();
  }

  void _openDetails(Establishment establishment) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EstablishmentDetailsPage(establishment: establishment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // watch: qualquer fonte que notificar reconstrói a tela.
    final explore = context.watch<ExploreController>();
    final favorites = context.watch<FavoritesController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Explorar')),
      // switch exaustivo: o compilador avisa se faltar um estado.
      body: switch (explore.status) {
        ExploreStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        ExploreStatus.failure => StatusMessage(
          icon: Icons.cloud_off_outlined,
          message: 'Não foi possível carregar os estabelecimentos.',
          actionLabel: 'Tentar novamente',
          onAction: explore.retry,
        ),
        ExploreStatus.ready => _buildReady(explore, favorites),
      },
    );
  }

  Widget _buildReady(ExploreController explore, FavoritesController favorites) {
    final filters = explore.filters;
    // Estado derivado: nada disto é guardado, tudo é recalculado a cada build
    // a partir de duas fontes (catálogo + filtros) e dos favoritos.
    final results = applyExploreFilters(
      explore.catalog,
      filters,
      favoriteIds: {for (final f in favorites.favorites) f.establishmentId},
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(_padding, 8, _padding, 8),
          sliver: SliverList.list(
            children: [
              ExploreSearchField(
                query: filters.query,
                onChanged: explore.setQuery,
              ),
              const SizedBox(height: 16),
              ExploreFilterChips(
                filters: filters,
                onCategoryToggle: explore.toggleCategory,
                onDietaryToggle: explore.toggleDietaryOption,
                onFavoritesChanged: explore.setOnlyFavorites,
              ),
              const SizedBox(height: 16),
              ExploreResultsBar(
                count: results.length,
                sort: filters.sort,
                onSortChanged: explore.setSort,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        if (results.isEmpty)
          SliverToBoxAdapter(
            child: StatusMessage(
              icon: Icons.search_off_outlined,
              message: 'Nenhum lugar combina com esses filtros.',
              // Só oferece a saída se houver algo para limpar.
              actionLabel: filters.hasActiveFilters ? 'Limpar filtros' : null,
              onAction: explore.clearFilters,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 24),
            sliver: SliverList.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final establishment = results[index];
                return EstablishmentCard(
                  establishment: establishment,
                  isFavorite: favorites.isFavorite(
                    establishment.establishmentId,
                  ),
                  onFavoriteToggle: () =>
                      toggleFavoriteWithFeedback(context, establishment),
                  onTap: () => _openDetails(establishment),
                );
              },
            ),
          ),
      ],
    );
  }
}
```

> O `EstablishmentCard` já tem `margin` horizontal de 16 e vertical de 6, então a lista não precisa de separador nem de padding lateral.

### 7.6 Corrigir os problemas existentes

**`establishment_card.dart` (substituir).** Agora respeita o `onTap` recebido e perde o `Navigator.push` interno e o comentário desatualizado.

```dart
import 'package:flutter/material.dart';

import '../../domain/entities/establishment.dart';
import 'favorite_button.dart';

/// Cartão de um estabelecimento. Não decide navegação nem estado de favorito:
/// recebe tudo pronto (`isFavorite`) e devolve eventos (`onTap`, `onFavoriteToggle`).
class EstablishmentCard extends StatelessWidget {
  const EstablishmentCard({
    super.key,
    required this.establishment,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final Establishment establishment;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final item = establishment;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${item.category.label} · ${item.neighborhood} · ★ ${item.rating}',
        ),
        trailing: onFavoriteToggle != null
            ? FavoriteButton(
                establishmentName: item.name,
                isFavorite: isFavorite,
                onPressed: onFavoriteToggle!,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
```

**`favorites_page.dart` (substituir).** `watch` em vez de `read` e o helper de favoritar.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../establishments/domain/entities/establishment.dart';
import '../../../establishments/presentation/pages/establishment_details_page.dart';
import '../../../establishments/presentation/widgets/establishment_card.dart';
import '../favorites_controller.dart';
import '../toggle_favorite.dart';

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

  @override
  Widget build(BuildContext context) {
    // watch (e não read): a aba precisa refletir favoritos feitos em outras telas.
    final favorites = context.watch<FavoritesController>().favorites;

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: favorites.isEmpty
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
                        toggleFavoriteWithFeedback(context, establishment),
                    onTap: () => _openDetails(context, establishment),
                  ),
              ],
            ),
    );
  }
}
```

**`establishment_details_page.dart`:** remova o comentário `/// PROBLEMA DIDÁTICO AQUI...` acima da classe e, no botão da `AppBar`, use o helper:

```dart
FavoriteButton(
  establishmentName: establishment.name,
  isFavorite: isFavorite,
  onPressed: () => toggleFavoriteWithFeedback(context, establishment),
),
```

(com `import '../../../favorites/presentation/toggle_favorite.dart';`).

**Verificação (ainda sem aba):** para ver a `ExplorePage` antes do Passo 8, troque temporariamente `home: const AppShell()` por `home: const ExplorePage()` em `lab_app.dart`, rode e faça o roteiro:

1. Digite "cafe": só cartões com "Café" no nome ou tipo (após ~300 ms).
2. Ligue "Sem glúten" + "Mercado": lista vazia com **Limpar filtros**; ao tocar, o campo e os chips voltam.
3. Mude a ordenação para "Melhor nota".
4. Aumente a fonte do aparelho a 200% numa tela pequena: nada estoura e todos os chips continuam visíveis.

Volte para `home: const AppShell()` ao terminar.

---

## Passo 8 — Home e `AppShell`

**Problema.** A aba Explorar existe, mas ninguém chega até ela com intenção. A Home precisa de três pontos de entrada (busca, categorias, "Ver todos") e há três desafios:
1. **A Home não pode trocar de aba sozinha:** quem sabe a aba selecionada é o `AppShell`.
2. **A Home precisa mandar um recado a Explorar** ("comece filtrado por Padaria") sem conhecer a `ExplorePage`.
3. **O estado de Explorar deve sobreviver** à troca de abas.
4. O botão "Ver estabelecimentos" de Favoritos vazia hoje leva ao Início; faz mais sentido levar a Explorar.

**Conceito.** Dois canais independentes, cada um com uma responsabilidade:

| Canal | Quem usa | Para quê |
|---|---|---|
| `ExploreController` (via `provider`) | Home → Explorar | **dados**: "filtre por Padaria" |
| `VoidCallback onOpenExplore` | Home → `AppShell` | **navegação**: "mostre a aba 1" |

- A Home **não importa** `ExplorePage`. Se Explorar virar rota empilhada, só o `AppShell` muda.
- **`IndexedStack` preserva o estado:** todas as abas ficam vivas; como os filtros moram no `ExploreController`, sobrevivem.
- **`showOnly` × `toggleCategory`:** o atalho significa "**só** Padarias, do zero" (limpa os outros critérios, mantém a ordenação); o chip soma ou tira uma categoria sem mexer no resto.
- **`read` em callbacks:** toques são ações, então `context.read`, nunca `watch`.
- A busca da Home **não** apaga filtros existentes (só leva à tela); "Ver todos" **limpa** (a promessa é "a lista completa").

### 8.1 `lib/app/shell/app_shell.dart` (substituir)

```dart
import 'package:flutter/material.dart';

import '../../features/explore/presentation/pages/explore_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/home/presentation/pages/home_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const int _exploreIndex = 1;

  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  // As abas são criadas uma vez; IndexedStack as mantém vivas.
  late final List<Widget> _tabs = [
    HomePage(onOpenExplore: () => _onDestinationSelected(_exploreIndex)),
    const ExplorePage(),
    FavoritesPage(onExploreTap: () => _onDestinationSelected(_exploreIndex)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
        ],
      ),
    );
  }
}
```

### 8.2 `lib/features/home/presentation/pages/home_page.dart` (substituir)

A Home agora é `StatefulWidget` (precisa chamar `load()` no `initState`), lê o catálogo do `ExploreController` e mostra os **4 mais próximos**.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/common/status_message.dart';
import '../../../establishments/domain/entities/establishment.dart';
import '../../../establishments/domain/entities/establishment_category.dart';
import '../../../establishments/presentation/pages/establishment_details_page.dart';
import '../../../establishments/presentation/widgets/establishment_card.dart';
import '../../../explore/domain/explore_filters.dart';
import '../../../explore/domain/explore_query.dart';
import '../../../explore/presentation/explore_controller.dart';
import '../../../favorites/presentation/favorites_controller.dart';
import '../../../favorites/presentation/toggle_favorite.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onOpenExplore});

  /// Pede ao AppShell para mostrar a aba Explorar. Opcional: em testes
  /// isolados da Home não há shell e `?.call()` simplesmente não faz nada.
  final VoidCallback? onOpenExplore;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _nearbyCount = 4;

  @override
  void initState() {
    super.initState();
    // load() é idempotente: Home e Explorar podem pedir, a carga é uma só.
    context.read<ExploreController>().load();
  }

  void _openDetails(Establishment establishment) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EstablishmentDetailsPage(establishment: establishment),
      ),
    );
  }

  void _showCategory(EstablishmentCategory category) {
    // Dados: "comece filtrado por esta categoria".
    context.read<ExploreController>().showOnly(category);
    // Navegação: "mostre a aba Explorar".
    widget.onOpenExplore?.call();
  }

  void _showAll() {
    context.read<ExploreController>().clearFilters();
    widget.onOpenExplore?.call();
  }

  @override
  Widget build(BuildContext context) {
    final explore = context.watch<ExploreController>();
    final favorites = context.watch<FavoritesController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Estabelecimentos')),
      body: switch (explore.status) {
        ExploreStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        ExploreStatus.failure => StatusMessage(
          icon: Icons.cloud_off_outlined,
          message: 'Não foi possível carregar os estabelecimentos.',
          actionLabel: 'Tentar novamente',
          onAction: explore.retry,
        ),
        ExploreStatus.ready => _buildReady(explore, favorites),
      },
    );
  }

  Widget _buildReady(ExploreController explore, FavoritesController favorites) {
    // Reaproveita a função pura: consulta inicial = ordenado por distância.
    final nearby = applyExploreFilters(
      explore.catalog,
      ExploreFilters.initial,
      favoriteIds: const {},
    ).take(_nearbyCount).toList();

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              alignment: Alignment.centerLeft,
            ),
            icon: const Icon(Icons.search),
            label: const Text('Buscar produtos ou lugares'),
            // Só leva à tela: não apaga os filtros que a pessoa já escolheu.
            onPressed: () => widget.onOpenExplore?.call(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final category in EstablishmentCategory.values)
                ActionChip(
                  label: Text(category.label),
                  onPressed: () => _showCategory(category),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Perto de você',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(onPressed: _showAll, child: const Text('Ver todos')),
            ],
          ),
        ),
        for (final establishment in nearby)
          EstablishmentCard(
            establishment: establishment,
            isFavorite: favorites.isFavorite(establishment.establishmentId),
            onFavoriteToggle: () =>
                toggleFavoriteWithFeedback(context, establishment),
            onTap: () => _openDetails(establishment),
          ),
      ],
    );
  }
}
```

### 8.3 Apagar o catálogo antigo

```bash
rm lib/features/establishments/data/sample_establishments.dart
```

Nenhum arquivo deve mais importá-lo (`flutter analyze` confirma).

**Verificação**

```bash
flutter analyze
flutter run
```

Roteiro:
1. Início mostra 4 lugares; toque em "Padaria": abre **Explorar** só com padarias e o chip "Padaria" selecionado.
2. Ligue "Sem glúten", vá a Favoritos e volte a Explorar: os filtros **continuam** (o `IndexedStack` e o controlador preservam).
3. Em Início, "Ver todos": Explorar abre sem filtros.
4. Favorite um lugar em Explorar, abra a aba Favoritos: ele aparece (efeito do `watch`).
5. Com Favoritos vazia, "Ver estabelecimentos" leva a **Explorar**.

---

## Passo 9 — Testes

**Problema.** Cada peça pede um tipo de teste diferente:

| Peça | Dificuldade | Tipo ideal |
|---|---|---|
| `applyExploreFilters`, `normalizeSearchText`, `ExploreFilters` | nenhuma (puras) | **unidade**, sem Flutter |
| `ExploreController` | assíncrono (carga, falha, retry) | **unidade** com dublê de repositório |
| `ExploreSearchField` / `ExplorePage` | **tempo** (debounce), **lista lazy**, acessibilidade | **widget** |
| Home ↔ Explorar | duas telas e a barra de abas | **widget** de integração no `AppShell` |

Armadilhas reais:
1. **Debounce:** como esperar 300 ms sem `sleep`?
2. **Lista lazy:** em tela de 800 px, `SliverList` só monta alguns cartões; `findsNWidgets(4)` falha mesmo com o app correto.
3. **Acessibilidade:** como garantir áreas de toque e rótulos sem olhar a tela?
4. **Provedores:** a página depende de dois controladores; o helper precisa fornecê-los.

*Para provocar ao vivo:* `expect(find.byType(Card), findsNWidgets(4))` numa tela de 800 px falha com "found 2 widgets". O app está certo; o teste é que não monta tudo.

**Conceito.**
- **Pirâmide:** muitos testes de unidade, alguns de widget, poucos de integração. A função pura do Passo 4 paga aqui.
- **Relógio falso:** `await tester.pump(const Duration(milliseconds: 300))` avança o relógio simulado e dispara o `Timer` sem esperar de verdade. `pumpAndSettle()` avança até não haver animações/timers pendentes.
- **Dublês:** `StubEstablishmentRepository` devolve, em sequência, os resultados de uma fila (primeiro falha, depois acerta) e conta `nearbyCalls`.
- **Tela alta:** `tester.view.physicalSize` maior (aqui `360×2400`) faz o `SliverList` montar todos os cartões. Para *overflow*, voltamos a `320×640` com fonte 200%.
- **Diretrizes de acessibilidade:** `androidTapTargetGuideline` (área mínima) e `labeledTapTargetGuideline` (todo alvo tem rótulo); exigem `tester.ensureSemantics()`.
- `find.text` ignora widgets **fora da tela** (`Offstage`), por isso, num `IndexedStack`, só a aba visível é encontrada.

### 9.1 `test/support/explore_catalog.dart`

Quatro lugares com distância, nota e opções **conhecidas**, para as asserções serem exatas. A lista nasce **fora de ordem** de propósito: se a função não ordenar, os testes pegam.

```dart
import 'package:favoritos_01/features/establishments/domain/entities/dietary_option.dart';
import 'package:favoritos_01/features/establishments/domain/entities/establishment.dart';
import 'package:favoritos_01/features/establishments/domain/entities/establishment_category.dart';

const both = {DietaryOption.glutenFree, DietaryOption.lactoseFree};

const cafeAconchego = Establishment(
  establishmentId: '1',
  name: 'Café Aconchego',
  category: EstablishmentCategory.cafe,
  neighborhood: 'Centro',
  distanceInKm: 0.35,
  rating: 4.8,
  dietaryOptions: both,
);

const padariaLeve = Establishment(
  establishmentId: '2',
  name: 'Padaria Leve Grão',
  category: EstablishmentCategory.bakery,
  neighborhood: 'Jardim das Flores',
  distanceInKm: 1.2,
  rating: 4.6,
  dietaryOptions: {DietaryOption.glutenFree},
);

const bistro = Establishment(
  establishmentId: '3',
  name: 'Bistrô Bem-Estar',
  category: EstablishmentCategory.restaurant,
  neighborhood: 'Bela Vista',
  distanceInKm: 2.4,
  rating: 4.7,
  dietaryOptions: both,
);

const emporio = Establishment(
  establishmentId: '4',
  name: 'Empório Natural',
  category: EstablishmentCategory.market,
  neighborhood: 'Vila Nova',
  distanceInKm: 3.1,
  rating: 4.5,
  dietaryOptions: {DietaryOption.lactoseFree},
);

// Fora de ordem de propósito.
const catalog = [emporio, bistro, cafeAconchego, padariaLeve];
```

### 9.2 `test/support/stub_establishment_repository.dart`

```dart
import 'package:favoritos_01/features/establishments/domain/entities/establishment.dart';
import 'package:favoritos_01/features/establishments/domain/repositories/establishment_repository.dart';

/// Devolve, em sequência, o resultado de cada função da fila.
/// Ex.: [() async => throw Exception(), () async => catalog] falha e depois acerta.
class StubEstablishmentRepository implements EstablishmentRepository {
  StubEstablishmentRepository({this.nearbyResults = const []});

  final List<Future<List<Establishment>> Function()> nearbyResults;
  int nearbyCalls = 0;

  @override
  Future<List<Establishment>> fetchNearby() => nearbyResults[nearbyCalls++]();
}
```

### 9.3 `test/support/pump_app.dart`

```dart
import 'package:favoritos_01/features/establishments/data/fake_establishment_repository.dart';
import 'package:favoritos_01/features/establishments/domain/repositories/establishment_repository.dart';
import 'package:favoritos_01/features/explore/presentation/explore_controller.dart';
import 'package:favoritos_01/features/favorites/presentation/favorites_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Monta [home] como o app monta: os dois provedores e um MaterialApp.
///
/// O tamanho padrão é alto (360×2400) de propósito: a lista é lazy e só
/// monta o que cabe na tela. Para testar overflow, passe `Size(320, 640)`.
Future<void> pumpApp(
  WidgetTester tester,
  Widget home, {
  EstablishmentRepository? repository,
  Size size = const Size(360, 2400),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final favorites = FavoritesController();
  // delay zero: os 800 ms que simulam rede só atrapalhariam os testes.
  final explore = ExploreController(
    repository ?? const FakeEstablishmentRepository(delay: Duration.zero),
  );
  addTearDown(favorites.dispose);
  addTearDown(explore.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<FavoritesController>.value(value: favorites),
        ChangeNotifierProvider<ExploreController>.value(value: explore),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
}
```

### 9.4 `test/features/explore/search_text_test.dart`

```dart
import 'package:favoritos_01/features/explore/domain/search_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tira acentos e deixa em minúsculas', () {
    expect(normalizeSearchText('Bistrô'), 'bistro');
    expect(normalizeSearchText('CAFÉ'), 'cafe');
    expect(normalizeSearchText('Pão de Açúcar'), 'pao de acucar');
  });

  test('apara espaços nas pontas', () {
    expect(normalizeSearchText('  padaria  '), 'padaria');
  });

  test('texto vazio continua vazio', () {
    expect(normalizeSearchText(''), '');
    expect(normalizeSearchText('   '), '');
  });
}
```

### 9.5 `test/features/explore/explore_query_test.dart`

```dart
import 'package:favoritos_01/features/establishments/domain/entities/dietary_option.dart';
import 'package:favoritos_01/features/establishments/domain/entities/establishment_category.dart';
import 'package:favoritos_01/features/explore/domain/explore_filters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:favoritos_01/features/explore/domain/explore_query.dart';
import 'package:favoritos_01/features/explore/domain/explore_sort.dart';

import '../../support/explore_catalog.dart';

List<String> _ids(
  ExploreFilters filters, {
  Set<String> favoriteIds = const {},
}) {
  return [
    for (final e in applyExploreFilters(
      catalog,
      filters,
      favoriteIds: favoriteIds,
    ))
      e.establishmentId,
  ];
}

void main() {
  test('sem filtros, devolve tudo ordenado por distância', () {
    expect(_ids(ExploreFilters.initial), ['1', '2', '3', '4']);
  });

  test('não altera o catálogo original', () {
    final before = [...catalog];
    _ids(const ExploreFilters(sort: ExploreSort.name));
    expect(catalog, before);
  });

  group('busca', () {
    test('acha por nome sem depender de acento ou maiúscula', () {
      expect(_ids(const ExploreFilters(query: 'bistro')), ['3']);
      expect(_ids(const ExploreFilters(query: 'CAFÉ')), ['1']);
    });

    test('acha por bairro e por tipo', () {
      expect(_ids(const ExploreFilters(query: 'vila nova')), ['4']);
      expect(_ids(const ExploreFilters(query: 'padaria')), ['2']);
    });

    test('todas as palavras precisam aparecer', () {
      expect(_ids(const ExploreFilters(query: 'cafe centro')), ['1']);
      expect(_ids(const ExploreFilters(query: 'cafe vila')), isEmpty);
    });
  });

  group('categorias', () {
    test('uma ou mais categorias: vale qualquer uma delas', () {
      const filters = ExploreFilters(
        categories: {EstablishmentCategory.cafe, EstablishmentCategory.market},
      );
      expect(_ids(filters), ['1', '4']);
    });
  });

  group('opções alimentares', () {
    test('o lugar precisa oferecer todas as escolhidas', () {
      expect(
        _ids(const ExploreFilters(dietaryOptions: {DietaryOption.glutenFree})),
        ['1', '2', '3'],
      );
      expect(_ids(const ExploreFilters(dietaryOptions: both)), ['1', '3']);
    });
  });

  group('favoritos', () {
    test('"só favoritos" usa os ids recebidos', () {
      expect(
        _ids(const ExploreFilters(onlyFavorites: true), favoriteIds: {'2', '4'}),
        ['2', '4'],
      );
    });

    test('sem favoritos, o filtro esvazia a lista', () {
      expect(_ids(const ExploreFilters(onlyFavorites: true)), isEmpty);
    });
  });

  test('os filtros se combinam (E entre grupos)', () {
    const filters = ExploreFilters(
      query: 'a',
      dietaryOptions: {DietaryOption.glutenFree},
      categories: {EstablishmentCategory.bakery, EstablishmentCategory.cafe},
    );
    expect(_ids(filters), ['1', '2']);
  });

  group('ordenação', () {
    test('por nota: maior primeiro', () {
      expect(
        _ids(const ExploreFilters(sort: ExploreSort.rating)),
        ['1', '3', '2', '4'],
      );
    });

    test('por nome: A–Z ignorando acento', () {
      expect(
        _ids(const ExploreFilters(sort: ExploreSort.name)),
        ['3', '1', '4', '2'],
      );
    });
  });

  group('ExploreFilters', () {
    test('activeCount não conta a ordenação nem busca vazia', () {
      expect(const ExploreFilters(sort: ExploreSort.name).activeCount, 0);
      expect(const ExploreFilters(query: '  ').activeCount, 0);
      expect(
        const ExploreFilters(
          query: 'a',
          categories: {EstablishmentCategory.cafe},
          onlyFavorites: true,
        ).activeCount,
        3,
      );
    });

    test('igualdade compara o conteúdo dos conjuntos', () {
      expect(
        const ExploreFilters(categories: {EstablishmentCategory.cafe}),
        const ExploreFilters(categories: {EstablishmentCategory.cafe}),
      );
      expect(
        const ExploreFilters(categories: {EstablishmentCategory.cafe}),
        isNot(const ExploreFilters(categories: {EstablishmentCategory.market})),
      );
    });

    test('hashCode não depende da ordem de inserção', () {
      final a = ExploreFilters(dietaryOptions: {...both});
      final b = ExploreFilters(
        dietaryOptions: {DietaryOption.lactoseFree, DietaryOption.glutenFree},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('cleared mantém a ordenação', () {
      const filters = ExploreFilters(
        query: 'a',
        onlyFavorites: true,
        sort: ExploreSort.rating,
      );
      expect(filters.cleared(), const ExploreFilters(sort: ExploreSort.rating));
    });
  });
}
```

### 9.6 `test/features/explore/explore_controller_test.dart`

```dart
import 'package:favoritos_01/features/establishments/domain/entities/establishment.dart';
import 'package:favoritos_01/features/establishments/domain/entities/establishment_category.dart';
import 'package:favoritos_01/features/explore/domain/explore_sort.dart';
import 'package:favoritos_01/features/explore/presentation/explore_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/explore_catalog.dart';
import '../../support/stub_establishment_repository.dart';

ExploreController _controller(
  List<Future<List<Establishment>> Function()> results,
) => ExploreController(StubEstablishmentRepository(nearbyResults: results));

void main() {
  test('começa carregando e passa a pronto com o catálogo', () async {
    final controller = _controller([() async => catalog]);
    addTearDown(controller.dispose);
    expect(controller.status, ExploreStatus.loading);

    await controller.load();

    expect(controller.status, ExploreStatus.ready);
    expect(controller.catalog, catalog);
  });

  test('load chamado várias vezes busca uma só vez', () async {
    final repository = StubEstablishmentRepository(
      nearbyResults: [() async => catalog],
    );
    final controller = ExploreController(repository);
    addTearDown(controller.dispose);

    await (controller.load(), controller.load()).wait;

    expect(repository.nearbyCalls, 1);
  });

  test('falha vira estado de erro e retry recupera', () async {
    final controller = _controller([
      () async => throw Exception('sem rede'),
      () async => catalog,
    ]);
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.status, ExploreStatus.failure);

    await controller.retry();
    expect(controller.status, ExploreStatus.ready);
    expect(controller.catalog, catalog);
  });

  group('filtros', () {
    late ExploreController controller;
    late int notifications;

    setUp(() {
      controller = _controller([() async => catalog]);
      notifications = 0;
      controller.addListener(() => notifications++);
    });
    tearDown(() => controller.dispose());

    test('toggleCategory liga e desliga', () {
      controller.toggleCategory(EstablishmentCategory.cafe);
      expect(controller.filters.categories, {EstablishmentCategory.cafe});
      controller.toggleCategory(EstablishmentCategory.cafe);
      expect(controller.filters.categories, isEmpty);
      expect(notifications, 2);
    });

    test('não notifica quando nada mudou', () {
      controller.setQuery('');
      controller.setSort(ExploreSort.distance);
      controller.setOnlyFavorites(false);
      expect(notifications, 0);
    });

    test('showOnly zera os outros filtros e escolhe só a categoria', () {
      controller.setQuery('pao');
      controller.setOnlyFavorites(true);

      controller.showOnly(EstablishmentCategory.bakery);

      expect(controller.filters.query, '');
      expect(controller.filters.onlyFavorites, isFalse);
      expect(controller.filters.categories, {EstablishmentCategory.bakery});
    });

    test('clearFilters mantém a ordenação escolhida', () {
      controller.setSort(ExploreSort.rating);
      controller.setQuery('cafe');

      controller.clearFilters();

      expect(controller.filters.hasActiveFilters, isFalse);
      expect(controller.filters.sort, ExploreSort.rating);
    });
  });
}
```

### 9.7 `test/features/explore/explore_page_test.dart`

Aqui os favoritos nascem vazios (o `FavoritesController` é em memória), então os testes de favoritos **favoritam pela interface**.

```dart
import 'package:favoritos_01/features/establishments/domain/entities/establishment.dart';
import 'package:favoritos_01/features/explore/presentation/pages/explore_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/explore_catalog.dart';
import '../../support/pump_app.dart';
import '../../support/stub_establishment_repository.dart';

Future<void> _pumpExplore(
  WidgetTester tester, {
  List<Future<List<Establishment>> Function()>? results,
  // Alta de propósito: a lista é lazy e só monta o que cabe na tela.
  Size size = const Size(360, 2400),
  double textScale = 1,
}) async {
  final repository = StubEstablishmentRepository(
    nearbyResults: results ?? [() async => catalog],
  );
  await pumpApp(
    tester,
    const ExplorePage(),
    repository: repository,
    size: size,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}

/// Restringe o texto aos cartões, para não confundir com o nome que aparece
/// em outro lugar da tela.
Finder _inResults(String text) =>
    find.descendant(of: find.byType(Card), matching: find.text(text));

void main() {
  testWidgets('mostra o carregamento e depois todos os lugares', (tester) async {
    await _pumpExplore(tester);

    expect(find.text('4 lugares encontrados'), findsOne);
    expect(find.byType(Card), findsNWidgets(4));
  });

  testWidgets('erro de carregamento oferece nova tentativa', (tester) async {
    await _pumpExplore(
      tester,
      results: [() async => throw Exception('sem rede'), () async => catalog],
    );

    expect(
      find.text('Não foi possível carregar os estabelecimentos.'),
      findsOne,
    );
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.byType(Card), findsNWidgets(4));
  });

  testWidgets('a busca só filtra depois de a pessoa parar de digitar', (
    tester,
  ) async {
    await _pumpExplore(tester);

    await tester.enterText(find.byType(TextField), 'bistro');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(Card), findsNWidgets(4)); // ainda esperando

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Card), findsOne);
    expect(_inResults('Bistrô Bem-Estar'), findsOne);
    expect(find.text('1 lugar encontrado'), findsOne);
  });

  testWidgets('botão de limpar esvazia o campo e volta a lista', (tester) async {
    await _pumpExplore(tester);
    await tester.enterText(find.byType(TextField), 'bistro');
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byTooltip('Limpar busca'));
    await tester.pump();

    expect(find.byType(Card), findsNWidgets(4));
    expect(find.byTooltip('Limpar busca'), findsNothing);
  });

  testWidgets('chips de categoria e de opção alimentar se combinam', (
    tester,
  ) async {
    await _pumpExplore(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Sem glúten'));
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsNWidgets(3));

    await tester.tap(find.widgetWithText(FilterChip, 'Café'));
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsOne);
    expect(_inResults('Café Aconchego'), findsOne);
  });

  testWidgets('sem resultado, explica e "Limpar filtros" recupera a lista', (
    tester,
  ) async {
    await _pumpExplore(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Mercado'));
    await tester.tap(find.widgetWithText(FilterChip, 'Sem glúten'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum lugar combina com esses filtros.'), findsOne);
    expect(find.text('Nenhum lugar encontrado'), findsOne);

    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();

    expect(find.byType(Card), findsNWidgets(4));
    final chip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Mercado'),
    );
    expect(chip.selected, isFalse);
  });

  testWidgets('a ordenação reordena os cartões', (tester) async {
    await _pumpExplore(tester);

    // Posição vertical: quem está mais acima aparece antes na lista.
    double top(String name) => tester.getTopLeft(_inResults(name)).dy;
    expect(top('Café Aconchego') < top('Empório Natural'), isTrue);

    await tester.tap(find.text('Mais perto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nome (A–Z)').last);
    await tester.pumpAndSettle();

    expect(top('Bistrô Bem-Estar') < top('Café Aconchego'), isTrue);
  });

  testWidgets('"Só favoritos" mostra os salvos e reage ao coração', (
    tester,
  ) async {
    await _pumpExplore(tester);

    await tester.tap(find.byTooltip('Salvar Padaria Leve Grão nos favoritos'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Só favoritos'));
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsOne);
    expect(_inResults('Padaria Leve Grão'), findsOne);

    // Desfavoritar com o filtro ligado tira o cartão da lista.
    await tester.tap(find.byTooltip('Remover Padaria Leve Grão dos favoritos'));
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsNothing);
    expect(find.text('Nenhum lugar combina com esses filtros.'), findsOne);
  });

  testWidgets('favoritar um cartão troca o coração', (tester) async {
    await _pumpExplore(tester);

    await tester.tap(find.byTooltip('Salvar Café Aconchego nos favoritos'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Remover Café Aconchego dos favoritos'), findsOne);
  });

  testWidgets('cumpre as diretrizes de acessibilidade de toque e rótulo', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pumpExplore(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('sem overflow em 320×640 com fonte a 200%', (tester) async {
    await _pumpExplore(tester, size: const Size(320, 640), textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
```

### 9.8 `test/app/app_shell_test.dart`

```dart
import 'package:favoritos_01/app/shell/app_shell.dart';
import 'package:favoritos_01/features/explore/presentation/pages/explore_page.dart';
import 'package:favoritos_01/features/home/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

/// Toca numa aba da barra de navegação inferior pelo rótulo.
Future<void> _goToTab(WidgetTester tester, String label) => tester.tap(
  find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
);

void main() {
  testWidgets('um atalho de categoria da Home abre Explorar já filtrado', (
    tester,
  ) async {
    await pumpApp(tester, const AppShell());
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(HomePage),
        matching: find.widgetWithText(ActionChip, 'Padaria'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ExplorePage), findsOne);
    expect(find.text('Padaria Leve Grão'), findsWidgets);
    expect(find.text('Café Aconchego'), findsNothing);
    final chip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Padaria'),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('"Ver todos" abre Explorar sem filtros', (tester) async {
    await pumpApp(tester, const AppShell());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver todos'));
    await tester.pumpAndSettle();

    expect(find.text('12 lugares encontrados'), findsOne);
  });

  testWidgets('os filtros de Explorar sobrevivem à troca de aba', (
    tester,
  ) async {
    await pumpApp(tester, const AppShell());
    await tester.pumpAndSettle();
    await _goToTab(tester, 'Explorar');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Mercado'));
    await tester.pumpAndSettle();

    await _goToTab(tester, 'Favoritos');
    await tester.pumpAndSettle();
    await _goToTab(tester, 'Explorar');
    await tester.pumpAndSettle();

    final chip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Mercado'),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('um favorito feito em Explorar aparece na aba Favoritos', (
    tester,
  ) async {
    await pumpApp(tester, const AppShell());
    await tester.pumpAndSettle();
    await _goToTab(tester, 'Explorar');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Salvar Café Aconchego nos favoritos'));
    await tester.pumpAndSettle();

    await _goToTab(tester, 'Favoritos');
    await tester.pumpAndSettle();
    expect(find.text('1 lugar salvo'), findsOne);
  });

  testWidgets('"Ver estabelecimentos" em Favoritos leva a Explorar', (
    tester,
  ) async {
    await pumpApp(tester, const AppShell());
    await tester.pumpAndSettle();
    await _goToTab(tester, 'Favoritos');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver estabelecimentos'));
    await tester.pumpAndSettle();

    expect(find.text('12 lugares encontrados'), findsOne);
  });
}
```

> **Nota sobre a Home com 12 lugares:** no teste "Ver todos" o `AppShell` usa o `FakeEstablishmentRepository` (12 itens, `delay: Duration.zero`), por isso a contagem esperada é 12. Já os testes de `ExplorePage` usam o catálogo de 4 do `explore_catalog.dart`.

### 9.9 Rodar

```bash
flutter analyze
flutter test test/features/explore
flutter test
```

Se um teste de acessibilidade falhar, a mensagem indica o widget sem rótulo ou com área menor que 48×48 dp: corrija o widget, não o teste.

---

## Checklist final

- [ ] `ExploreFilters`, `applyExploreFilters` e `normalizeSearchText` sem `import` de Flutter.
- [ ] Categorias **OU**; opções alimentares **E**; entre grupos **E**; todas as palavras da busca.
- [ ] Desempate por nome em toda ordenação; catálogo original nunca alterado.
- [ ] Controlador guarda catálogo, filtros e status, **nunca** a lista filtrada; `Set`s copiados.
- [ ] `status` nasce `loading` e só notifica depois do `await`.
- [ ] `Timer` e `TextEditingController` liberados no `dispose`; campo sincroniza com o estado sem laço.
- [ ] Filtros em `Wrap` (sem rolagem horizontal), contagem em `liveRegion`, vazio com saída.
- [ ] `switch` cobre `loading`, `failure` e `ready`.
- [ ] `EstablishmentCard` respeita `onTap`; `FavoritesPage` usa `watch`.
- [ ] Um só `toggleFavoriteWithFeedback` nas três telas.
- [ ] A Home não importa `ExplorePage`; atalho de categoria = `showOnly`; "Ver todos" = `clearFilters`.
- [ ] Filtros sobrevivem à troca de abas; "Ver estabelecimentos" leva a Explorar.
- [ ] `flutter analyze` limpo e `flutter test` verde.

## Roteiro sugerido de aula (≈ 7 a 8 h)

| Passo | Tema | Tempo |
|---|---|---|
| 1–2 | Domínio e catálogo | 45 min |
| 3 | `ExploreFilters` | 1 h 10 |
| 4 | Função pura | 1 h 15 |
| 5 | Controlador e estado derivado | 1 h 15 |
| 6 | Debounce | 1 h |
| 7 | Interface e estados | 1 h 20 |
| 8 | Home e `AppShell` | 1 h |
| 9 | Testes | 1 h 20 |

## Desafios opcionais (fora do escopo)

1. **Foco automático no campo de busca** ao tocar em "Buscar produtos ou lugares" na Home (dica: um contador `focusRequests` no controlador + `FocusNode` na página).
2. **Persistir os filtros** entre execuções com `shared_preferences`.
3. **Histórico de buscas recentes** em SQLite.
4. **Ordenar por "mais perto" com localização real** (`geolocator`).
5. **Filtro "Atende ao meu perfil"**: depende de criar antes um perfil alimentar (fora deste projeto).
