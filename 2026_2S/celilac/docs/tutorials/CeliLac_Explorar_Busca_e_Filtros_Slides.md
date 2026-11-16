# CeliLac Etapa 6 — Explorar: Busca, Filtros e Ordenação
## Base para Slides (Gamma)

> **Instrução para o Gamma:** cada seção separada por `---` é um slide. Progressão: **Problema → Dor → Decisão → Código mínimo → Verificação**. Material de apoio completo em [`CeliLac_Explorar_Busca_e_Filtros.md`](./CeliLac_Explorar_Busca_e_Filtros.md) e no laboratório [`lab_explorar_busca_filtros/`](./lab_explorar_busca_filtros/README.md).

---

## Slide 1 — Capa

### CeliLac · Etapa 6: Explorar
**Busca, filtros combináveis e ordenação, juntando perfil e favoritos**

- Estado de consulta imutável
- Função pura de filtragem
- Estado derivado de três fontes
- *Debounce*
- Integração Home ↔ Explorar

---

## Slide 2 — Onde paramos

| Etapa | Entrega |
|---|---|
| 1–3 | Splash, Home, Detalhe |
| 4 | Perfil alimentar |
| 5 | Favoritos + SQLite + Provider |
| **6** | **Explorar** |

**O que ainda diz "em breve":** aba Explorar · campo de busca da Home · atalhos de categoria · "Ver todos"

---

## Slide 3 — O que a pessoa procura

- "Sem glúten **e** sem lactose"
- "Uma **padaria**"
- "Aquele café do **Centro**"
- "Dos meus **favoritos**, qual atende ao meu perfil?"

> Uma lista fixa por distância não responde a nenhuma delas.

---

## Slide 4 — Problema 1: onde mora a regra?

```text
❌ Regra no build → só testável abrindo a tela
✅ Regra como função pura no domínio → teste em milissegundos
```

```dart
applyExploreFilters(catalog, filters, profile: p, favoriteIds: ids)
```

---

## Slide 5 — A Consulta como Objeto Imutável

```text
ExploreFilters
├─ query
├─ categories        (OU)
├─ dietaryOptions    (E)
├─ onlyMatchingProfile
├─ onlyFavorites
└─ sort              (não é filtro!)
```

`copyWith` · `==` com `Set` · `cleared()` mantém a ordenação

---

## Slide 6 — Semântica E/OU

| Grupo | Regra |
|---|---|
| Entre grupos | **E** |
| Categorias | **OU** |
| Opções alimentares | **E** |
| Texto | todas as palavras (nome, bairro, tipo) |

"Bistrô" = "bistro" = "BISTRO"

---

## Slide 7 — Problema 2: guardar ou calcular?

```text
1. Explorar: liga "Só favoritos"
2. Início: favorita um lugar novo
3. Explorar: o lugar novo não aparece ❌
```

Causa: resultado **guardado** ficou velho.

**Decisão:** guardar catálogo + filtros; **derivar** a lista no `build`.

---

## Slide 8 — Três Fontes, Três `watch`

```dart
final explore   = context.watch<ExploreController>();
final profile   = context.watch<ProfileController>().profile;
final favorites = context.watch<FavoritesController>();
```

Favoritar na Home ou salvar o perfil → Explorar atualiza sozinha.

Alternativas: `select` · `ProxyProvider` · filtrar no banco

---

## Slide 9 — `ExploreController`

- `enum ExploreStatus { loading, ready, failure }`
- `load()` idempotente (`_loading ??= _load()`) + `retry()`
- `_update` ignora valores iguais
- `showOnly(category)` para o atalho da Home
- `Set`s sempre copiados

---

## Slide 10 — Problema 3: uma filtragem por letra

```text
p → pa → pad → pada → padar → padari → padaria
7 letras = 7 recálculos
```

**Debounce de 300 ms:** só avisa depois do silêncio.

---

## Slide 11 — Debounce no Campo

```dart
_timer?.cancel();
_timer = Timer(widget.debounce, () => widget.onChanged(text));
```

- `dispose`: cancela o `Timer`, descarta o `TextEditingController`
- `didUpdateWidget`: campo acompanha mudanças feitas por fora ("Limpar filtros")

---

## Slide 12 — Interface Acessível

- Filtros em **`Wrap`** (sem rolagem horizontal)
- `FilterChip` (estado e área de toque prontos)
- Contagem em **`liveRegion`**
- Chip "Atende ao meu perfil" só com perfil completo
- Estado vazio **com saída**: "Limpar filtros"

---

## Slide 13 — Estados da Tela

| Estado | Tela |
|---|---|
| carregando | indicador |
| erro | "Tentar novamente" |
| vazio | mensagem + "Limpar filtros" |
| pronto | cartões (`heroOrigin: 'explore'`) |

---

## Slide 14 — Home ↔ Explorar: Dois Canais

| Canal | Carrega |
|---|---|
| `ExploreController` | dados: "só Padarias" |
| `onOpenExplore` | navegação: "mostre a aba 1" |

- Categoria → `showOnly` · "Ver todos" → `clearFilters` · Busca → só abre
- Filtros sobrevivem à troca de aba (`IndexedStack` + controlador)

---

## Slide 15 — Refatoração

`toggleFavoriteWithFeedback` extraído na **3ª repetição** do `try/catch` + `SnackBar`.

Rede de segurança: os testes existentes continuaram passando.

---

## Slide 16 — Testes

| Tipo | Foco |
|---|---|
| Unidade | função pura, `ExploreFilters`, controlador |
| Widget | debounce (`pump(Duration)`), chips, vazio, acessibilidade, *overflow* |
| Integração | Home → Explorar filtrado; filtros sobrevivem às abas |

**122 → 162 testes.** Dica: lista lazy pede tela alta no teste.

---

## Slide 17 — Armadilhas Reais

| Sintoma | Causa |
|---|---|
| Lista velha | resultado guardado |
| Campo desatualizado | sem `didUpdateWidget` |
| `setState during build` | `notifyListeners` síncrono no `initState` |
| Teste acha 2 cartões | lista lazy |
| Ordem instável | `sort` sem desempate |

---

## Slide 18 — Aplicando no seu projeto

| Tema | Filtros |
|---|---|
| Cursos | nível, duração, gratuito |
| Imóveis | quartos, pets |
| Receitas | tempo, dificuldade |
| Vagas | modalidade, bolsa |

**Checklist:** consulta imutável · função pura · lista derivada · debounce · `Wrap` · testes

---

## Slide 19 — Desafios

1. Foco automático na busca vinda da Home
2. Persistir filtros (`shared_preferences`)
3. Buscas recentes em SQLite (migração)
4. Contador "Filtros (3)"
5. Filtro "aberto agora"

---

## Slide 20 — Próximos Passos do CeliLac

- API REST remota (cache-first com SQLite)
- Autenticação e sessão
- Geolocalização e mapa (ordenar por distância real)
