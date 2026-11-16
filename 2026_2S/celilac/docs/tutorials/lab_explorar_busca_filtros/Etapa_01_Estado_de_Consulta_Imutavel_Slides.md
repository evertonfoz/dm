# Etapa 1 — Estado de Consulta como Valor Imutável
## Do emaranhado de variáveis a um único objeto `ExploreFilters`

> **Instrução para o Gamma:** cada seção separada por `---` é um slide. Progressão: **Problema → Dor → Conceito → Solução**. Use diagramas, tabelas e trechos mínimos de código.

---

## Slide 1 — Capa

### Etapa 1: Estado de Consulta como Valor Imutável
**Como representar "tudo o que a pessoa escolheu" em um só lugar**

- **Contexto:** Laboratório Explorar — CeliLac (Etapa 1 de 7)
- **Foco:** objeto de valor, `copyWith`, igualdade com `Set`, o que é (e o que não é) filtro

---

## Slide 2 — O Problema de Produto

### Uma tela, seis escolhas ao mesmo tempo

- Texto de busca
- Categorias (Café, Padaria…)
- Opções alimentares (Sem glúten, Sem lactose)
- "Só favoritos"
- "Atende ao meu perfil"
- Ordenação (mais perto, melhor nota, A–Z)

> Tudo precisa ser combinável, limpável, contável e entregável a outra tela.

---

## Slide 3 — A Tentativa Ingênua

```dart
String _query = '';
final Set<EstablishmentCategory> _categories = {};
final Set<DietaryOption> _dietary = {};
bool _onlyFavorites = false;
bool _onlyMatchingProfile = false;
ExploreSort _sort = ExploreSort.distance;
```

**Dores ao vivo:**
1. "Limpar tudo" exige lembrar de cada variável.
2. "3 filtros ativos" vira uma soma espalhada.
3. A Home não tem como entregar "só Padarias" a esta tela.
4. Novo filtro = mexer em muitos lugares.

---

## Slide 4 — A Ideia: Um Objeto de Valor Imutável

```text
ANTES: 6 variáveis soltas no State
DEPOIS: 1 objeto → ExploreFilters
        ├─ query
        ├─ categories
        ├─ dietaryOptions
        ├─ onlyMatchingProfile
        ├─ onlyFavorites
        └─ sort
```

- Campos `final`, construtor `const`
- Para mudar: `copyWith` devolve **uma cópia**
- Igualdade por **conteúdo**, não por identidade

---

## Slide 5 — `copyWith` em uma linha

```dart
filters.copyWith(onlyFavorites: true)
```

| Parâmetro | Efeito |
|---|---|
| informado | substitui o campo |
| omitido (`null`) | preserva o valor atual (`query ?? this.query`) |

> Limite: `copyWith` não consegue "voltar para `null`" — aqui nenhum campo é anulável.

---

## Slide 6 — Pegadinha: `Set` não é igual por conteúdo

```dart
{1} == {1}          // false! (identidade)
a.length == b.length && a.containsAll(b)   // ✅ conteúdo
Object.hashAllUnordered(set)               // ✅ hash sem depender da ordem
```

Sem isso, "o filtro mudou?" daria sempre **sim**, e a tela seria reconstruída à toa.

---

## Slide 7 — O que é "filtro"?

| Campo | Esconde lugares? | Conta em `activeCount`? |
|---|---|---|
| busca, categorias, opções, perfil, favoritos | Sim | Sim |
| **ordenação** | **Não** | **Não** |

**Decisão de produto:** "Limpar filtros" **mantém** a ordenação (`cleared()`).

---

## Slide 8 — Verificação e Ponte

- Teste de unidade sem Flutter (`activeCount`, `==`, `cleared`)
- CeliLac: `lib/features/explore/domain/explore_filters.dart` e `explore_sort.dart`

**Checklist:** sem imports de Flutter · campos `final` · `==` com conteúdo · `cleared()` preserva `sort`

**Próximo degrau:** a função que aplica esses filtros ao catálogo.
