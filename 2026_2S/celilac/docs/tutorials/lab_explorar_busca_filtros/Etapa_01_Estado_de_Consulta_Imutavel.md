# Etapa 1 — Estado de Consulta como Valor Imutável (`ExploreFilters`)

## Introdução: O que este documento propõe e resolve?

### 1. O Problema Real
A aba **Explorar** deixa a pessoa escolher vários critérios ao mesmo tempo: um texto de busca, categorias, opções alimentares ("Sem glúten", "Sem lactose"), "só favoritos", "atende ao meu perfil" e a ordenação. O primeiro instinto de quem aprendeu `StatefulWidget` é criar uma variável para cada critério:

```dart
class _ExplorePageState extends State<ExplorePage> {
  String _query = '';
  final Set<EstablishmentCategory> _categories = {};
  final Set<DietaryOption> _dietary = {};
  bool _onlyFavorites = false;
  bool _onlyMatchingProfile = false;
  ExploreSort _sort = ExploreSort.distance;
  // ...
}
```

Funciona para o primeiro filtro. A dor aparece quando precisamos:

- **limpar tudo** (cada variável precisa ser lembrada e zerada);
- **mostrar "3 filtros ativos"** (soma espalhada);
- **comparar** "o filtro mudou?" para não reconstruir à toa;
- **entregar** o conjunto de escolhas a outra tela (a Home vai abrir Explorar já filtrado por categoria, na Etapa 6);
- **testar** a regra de filtragem sem abrir a tela.

### 2. O que esta Etapa Propõe
Agrupar **todas as escolhas da pessoa** num único **objeto de valor imutável**, `ExploreFilters`, que vive no domínio e não conhece Flutter. Para mudar uma escolha, criamos uma **cópia** com `copyWith`. Isso resolve:

1. **Uma só "fotografia" do estado da consulta**, fácil de passar, guardar e comparar.
2. **Limpar** vira uma linha (`cleared()`).
3. **Igualdade por conteúdo** (`==`), que permite ao controlador (Etapa 3) *não notificar* quando nada mudou.
4. **Domínio puro**, testável em milissegundos.

---

## Visão Geral do Roteiro de Aula

| Momento | Tempo | O que acontece |
|---|---|---|
| **0. Ponto de partida** | 10 min | Conferimos o que o laboratório já tem e ampliamos a entidade. |
| **1. O Problema** | 10 min | Escrevemos as variáveis soltas e tentamos "limpar tudo" e "contar filtros". |
| **2. O Conceito** | 20 min | Imutabilidade, objeto de valor, `copyWith`, igualdade com `Set`. |
| **3. A Prática** | 25 min | Criamos `ExploreSort` e `ExploreFilters`. |
| **4. Verificação e Ponte** | 10 min | Teste de unidade e mapa para o CeliLac. |

---

## 0. Ponto de Partida

O projeto `lab_explorar` continua o laboratório de Favoritos. Precisamos ter:

- `Establishment` com **`category`** (`enum EstablishmentCategory`), **`distanceInKm`**, **`rating`** e **`dietaryOptions`** (`Set<DietaryOption>`). Se o seu laboratório ainda usa `String category`, converta agora: filtrar por `String` é frágil (um erro de digitação vira uma categoria nova).
- `DietaryOption` (`glutenFree`, `lactoseFree`) e `EstablishmentCategory` (`restaurant`, `bakery`, `cafe`, `market`), ambos com `label`.
- Um catálogo com **mais de 4 itens** (no CeliLac passamos de 4 para 12): com 4 lugares, filtrar e ordenar não mostra nada.
- `FavoritesController` com `provider` (Etapa 1 do laboratório de Favoritos).

Pasta nova desta etapa:

```text
lib/features/explore/
└── domain/
    ├── explore_sort.dart
    └── explore_filters.dart
```

---

## 1. O Problema (A Dor Provocada ao Vivo)

Peça aos alunos que, com as variáveis soltas, implementem três funções: `_clearAll()`, `_activeCount` e `_isDefault`. Na prática:

```dart
void _clearAll() {
  setState(() {
    _query = '';
    _categories.clear();
    _dietary.clear();
    _onlyFavorites = false;
    _onlyMatchingProfile = false;
    // e a ordenação? limpar também? 🤔
  });
}
```

Perguntas para a turma:
1. Se amanhã surgir o filtro "aberto agora", em quantos lugares do código ele precisa ser lembrado?
2. A ordenação deve ser zerada por "Limpar filtros"? (Spoiler: **não** — ordenar não esconde nada, é uma preferência de visualização.)
3. Como a Home entrega "só Padarias" para essa tela?

---

## 2. O Conceito

### 2.1 Objeto de valor imutável
Um **objeto de valor** é definido pelo seu **conteúdo**, não pela identidade. Dois `ExploreFilters` com a mesma busca e as mesmas categorias são "a mesma consulta". Por isso:

- todos os campos são `final` (imutável);
- o construtor é `const`;
- sobrescrevemos `==` e `hashCode`.

### 2.2 `copyWith`
Em vez de mudar um campo, devolvemos **uma cópia** com o campo trocado. O truque do `copyWith` com parâmetros opcionais (`String? query`) usa `query ?? this.query`: o que não foi informado é preservado.

### 2.3 Igualdade com `Set`
`Set` do Dart **não** compara por conteúdo no `==` padrão. Dois `{cafe}` diferentes não são iguais. Por isso comparamos **tamanho + `containsAll`**, e no `hashCode` usamos `Object.hashAllUnordered` (a ordem de inserção num `Set` não pode alterar o hash).

### 2.4 O que é um "filtro"?
| Campo | Esconde lugares? | Conta em `activeCount`? |
|---|---|---|
| `query` | Sim (se não vazio) | Sim |
| `categories` | Sim | Sim, uma por categoria |
| `dietaryOptions` | Sim | Sim, uma por opção |
| `onlyMatchingProfile` / `onlyFavorites` | Sim | Sim |
| `sort` | **Não** | **Não** |

Decisão de produto registrada no código: `cleared()` **mantém** a ordenação.

---

## 3. A Prática

### Arquivo 1: `lib/features/explore/domain/explore_sort.dart`

```dart
enum ExploreSort {
  distance('Mais perto'),
  rating('Melhor nota'),
  name('Nome (A–Z)');

  const ExploreSort(this.label);

  final String label;
}
```

*Enum com `label`* guarda o texto exibido junto do valor; a UI (Etapa 5) só percorre `ExploreSort.values`.

### Arquivo 2: `lib/features/explore/domain/explore_filters.dart`

```dart
import '../../establishments/domain/entities/dietary_option.dart';
import '../../establishments/domain/entities/establishment_category.dart';
import 'explore_sort.dart';

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
  final Set<EstablishmentCategory> categories;
  final Set<DietaryOption> dietaryOptions;
  final bool onlyMatchingProfile;
  final bool onlyFavorites;
  final ExploreSort sort;

  int get activeCount =>
      (query.trim().isEmpty ? 0 : 1) +
      categories.length +
      dietaryOptions.length +
      (onlyMatchingProfile ? 1 : 0) +
      (onlyFavorites ? 1 : 0);

  bool get hasActiveFilters => activeCount > 0;

  /// Volta tudo ao início, mas mantém a ordenação que a pessoa escolheu.
  ExploreFilters cleared() => ExploreFilters(sort: sort);

  ExploreFilters copyWith({
    String? query,
    Set<EstablishmentCategory>? categories,
    Set<DietaryOption>? dietaryOptions,
    bool? onlyMatchingProfile,
    bool? onlyFavorites,
    ExploreSort? sort,
  }) {
    return ExploreFilters(
      query: query ?? this.query,
      categories: categories ?? this.categories,
      dietaryOptions: dietaryOptions ?? this.dietaryOptions,
      onlyMatchingProfile: onlyMatchingProfile ?? this.onlyMatchingProfile,
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
        other.onlyMatchingProfile == onlyMatchingProfile &&
        other.onlyFavorites == onlyFavorites &&
        other.sort == sort;
  }

  @override
  int get hashCode => Object.hash(
    query,
    Object.hashAllUnordered(categories),
    Object.hashAllUnordered(dietaryOptions),
    onlyMatchingProfile,
    onlyFavorites,
    sort,
  );
}
```

**Pontos de atenção para a aula**
- `static const ExploreFilters initial` é a "consulta vazia" compartilhada.
- `const {}` como valor padrão: conjuntos constantes são imutáveis; quem quiser adicionar um item cria **outro** conjunto (`{...atual, novo}`), como faremos na Etapa 3.
- `copyWith` **não consegue** voltar um campo para `null`. Aqui nenhum campo é anulável, então não há problema. (No `DietaryProfile.name` do CeliLac isso exigiu o parâmetro `clearName`.)

---

## 4. Verificação e Ponte com o CeliLac

Teste rápido (vira o início de `explore_query_test.dart` na Etapa 7):

```dart
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
});
```

| Peça do laboratório | Arquivo no CeliLac |
|---|---|
| `ExploreSort` | `lib/features/explore/domain/explore_sort.dart` |
| `ExploreFilters` | `lib/features/explore/domain/explore_filters.dart` |

**Checklist**
- [ ] `ExploreFilters` sem nenhum `import` de Flutter.
- [ ] Todos os campos `final`, construtor `const`.
- [ ] `==` compara conjuntos por conteúdo e `hashCode` usa `hashAllUnordered`.
- [ ] `cleared()` preserva `sort`.

**Próxima etapa:** com a "pergunta" modelada, precisamos da "resposta": a função que aplica `ExploreFilters` a um catálogo.
