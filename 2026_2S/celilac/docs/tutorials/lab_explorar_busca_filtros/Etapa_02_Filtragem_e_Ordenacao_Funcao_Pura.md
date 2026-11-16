# Etapa 2 — Filtragem e Ordenação como Função Pura

## Introdução: O que este documento propõe e resolve?

### 1. O Problema Real
Temos a "pergunta" (`ExploreFilters`, Etapa 1). Falta a "resposta": dado um catálogo e os filtros, **quais lugares aparecem e em que ordem?**

O caminho mais comum é escrever essa regra direto no `build` da tela:

```dart
final visible = catalog.where((e) {
  if (_categories.isNotEmpty && !_categories.contains(e.category)) return false;
  // ... 30 linhas ...
}).toList()..sort(...);
```

Dores:
- **Só dá para testar abrindo a tela** (e digitando).
- O `build` fica enorme e mistura *layout* com *regra de negócio*.
- Fica fácil **alterar a lista original** sem querer (`catalog.sort(...)` muda o catálogo compartilhado).
- Detalhes de texto (acentos, maiúsculas) viram `if`s espalhados.

### 2. O que esta Etapa Propõe
Extrair a regra para uma **função pura** no domínio:

```dart
List<Establishment> applyExploreFilters(
  List<Establishment> catalog,
  ExploreFilters filters, {
  required DietaryProfile profile,
  required Set<String> favoriteIds,
})
```

Tudo o que a regra precisa entra por **parâmetro**; o resultado sai pelo **retorno**. Sem `BuildContext`, sem `Provider`, sem relógio, sem I/O.

---

## Visão Geral do Roteiro de Aula

| Momento | Tempo | O que acontece |
|---|---|---|
| **1. O Problema** | 10 min | Regra dentro do `build`; tentamos testá-la. |
| **2. O Conceito** | 25 min | Função pura; semântica E/OU; normalização de texto; estabilidade de `sort`. |
| **3. A Prática** | 30 min | `normalizeSearchText` e `applyExploreFilters`. |
| **4. Verificação e Ponte** | 10 min | Testes em milissegundos. |

---

## 1. O Problema

Pergunte: "Como eu garanto que *Bistrô* aparece quando digito *bistro*?". Se a resposta é "abrir o app e testar", a regra está no lugar errado.

---

## 2. O Conceito

### 2.1 Função pura
Uma função é **pura** quando (a) o mesmo conjunto de argumentos sempre dá o mesmo resultado e (b) não tem efeitos colaterais. Consequências práticas: testes triviais, reaproveitamento em qualquer tela e segurança para chamá-la a cada `build` (Etapa 3).

### 2.2 Semântica dos filtros (decisão de produto)
| Grupo | Regra | Exemplo |
|---|---|---|
| Entre grupos | **E** (todos precisam passar) | "Café" **E** "Sem glúten" |
| Categorias | **OU** dentro do grupo | "Café" **ou** "Mercado" |
| Opções alimentares | **E** dentro do grupo (`containsAll`) | "Sem glúten" **e** "Sem lactose" |
| Texto | **todas** as palavras precisam aparecer | "cafe centro" |

Por que opções alimentares são **E**? Quem escolhe "Sem glúten" e "Sem lactose" precisa de lugares que atendam às **duas** restrições; um lugar só sem lactose não serve.

### 2.3 Normalização de texto
"Bistrô", "BISTRO" e "bistro" devem casar. `normalizeSearchText` faz: `trim` → minúsculas → troca letras acentuadas. Alternativa de mercado: pacotes como `diacritic`; aqui um mapa pequeno basta e dispensa dependência.

### 2.4 `List.sort` não é estável
Se dois lugares têm a mesma distância, a ordem entre eles pode variar. Solução: **desempate pelo nome**, para a ordem ser previsível e testável.

### 2.5 Não alterar o catálogo
`where(...).toList()` cria **uma lista nova**; só depois ordenamos essa cópia. O catálogo guardado no controlador permanece intacto.

---

## 3. A Prática

### Arquivo 1: `lib/features/explore/domain/search_text.dart`

```dart
const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c',
};

String normalizeSearchText(String text) {
  final lower = text.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final character in lower.split('')) {
    buffer.write(_accents[character] ?? character);
  }
  return buffer.toString();
}
```

Conceito: `toLowerCase()` primeiro, assim o mapa só precisa das minúsculas. `StringBuffer` evita criar uma `String` nova a cada letra.

### Arquivo 2: `lib/features/explore/domain/explore_query.dart`

```dart
List<Establishment> applyExploreFilters(
  List<Establishment> catalog,
  ExploreFilters filters, {
  required DietaryProfile profile,
  required Set<String> favoriteIds,
}) {
  final words = normalizeSearchText(filters.query)
      .split(' ')
      .where((word) => word.isNotEmpty)
      .toList();

  bool matches(Establishment e) {
    if (filters.categories.isNotEmpty &&
        !filters.categories.contains(e.category)) {
      return false;
    }
    if (!e.dietaryOptions.containsAll(filters.dietaryOptions)) {
      return false;
    }
    if (filters.onlyMatchingProfile && !meetsProfile(e, profile)) {
      return false;
    }
    if (filters.onlyFavorites && !favoriteIds.contains(e.id)) {
      return false;
    }
    if (words.isEmpty) return true;

    final haystack = normalizeSearchText(
      '${e.name} ${e.neighborhood} ${e.category.label}',
    );
    return words.every(haystack.contains);
  }

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
- `containsAll` com conjunto **vazio** é `true`: sem opção escolhida, todo lugar passa. Um único `if` cobre "sem filtro" e "com filtro".
- `meetsProfile` já existe desde a Etapa do Perfil Alimentar; reaproveitamos a regra, não a duplicamos. Sem perfil completo ele devolve `false`: com "Atende ao meu perfil" ligado e perfil vazio, nada passa (por isso a UI só mostra o chip quando há perfil — Etapa 5).
- `ExploreSort.name => byName` — a própria função serve como comparador.
- O `switch` é uma *expressão* sobre o `enum`: se criarmos `ExploreSort.price`, o compilador acusa o caso que falta.
- O campo de texto "haystack" junta **nome + bairro + tipo**: "vila nova" e "padaria" funcionam.

---

## 4. Verificação e Ponte com o CeliLac

Testes sem Flutter (trecho de `explore_query_test.dart`):

```dart
test('acha por nome sem depender de acento ou maiúscula', () {
  expect(_ids(const ExploreFilters(query: 'bistro')), ['3']);
  expect(_ids(const ExploreFilters(query: 'CAFÉ')), ['1']);
});

test('todas as palavras precisam aparecer', () {
  expect(_ids(const ExploreFilters(query: 'cafe centro')), ['1']);
  expect(_ids(const ExploreFilters(query: 'cafe vila')), isEmpty);
});

test('não altera o catálogo original', () {
  final before = [...catalog];
  _ids(const ExploreFilters(sort: ExploreSort.name));
  expect(catalog, before);
});
```

| Peça | Arquivo no CeliLac |
|---|---|
| `normalizeSearchText` | `lib/features/explore/domain/search_text.dart` |
| `applyExploreFilters` | `lib/features/explore/domain/explore_query.dart` |

**Checklist**
- [ ] A função não importa Flutter nem `provider`.
- [ ] Categorias: OU. Opções alimentares: E. Entre grupos: E.
- [ ] A busca ignora acento e maiúscula e exige todas as palavras.
- [ ] Desempate por nome em toda ordenação.
- [ ] O catálogo original não é alterado.

**Próxima etapa:** de onde vêm o catálogo, o perfil e os favoritos? Quem guarda o quê? (Estado derivado.)
