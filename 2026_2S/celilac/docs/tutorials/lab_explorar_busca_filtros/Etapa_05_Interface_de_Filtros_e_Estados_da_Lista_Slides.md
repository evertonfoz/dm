# Etapa 5 — Interface de Filtros Acessível e Estados da Lista
## Montando `ExplorePage` sem esconder opções nem deixar ninguém sem saída

> **Instrução para o Gamma:** cada `---` é um slide.

---

## Slide 1 — Capa

### Etapa 5: A Tela Explorar
- **Foco:** `Wrap`, `FilterChip`, `liveRegion`, estados da lista, `Hero` por origem, helper de favoritar

---

## Slide 2 — As Armadilhas de uma Tela de Filtros

1. Chips em rolagem horizontal escondem opções com fonte grande
2. Lista vazia sem botão para desfazer
3. Contagem muda em silêncio para leitor de tela
4. Quatro estados: carregando · erro · vazio · pronto
5. Mesmo cartão em duas abas → colisão de `Hero`
6. `try/catch` de favoritar copiado pela 3ª vez

---

## Slide 3 — `Wrap` × Rolagem Horizontal

```text
Rolagem horizontal (fonte 200%):
[ Atende ao meu perfil ] [ Só fav… →   ← "Mercado" está escondido!

Wrap (fonte 200%):
[ Atende ao meu perfil ]
[ Só favoritos ] [ Sem glúten ]
[ Sem lactose ] [ Restaurante ]
...
```

Mais linhas, mas **tudo visível e tocável**.

---

## Slide 4 — `FilterChip` e Semântica

- `selected` + `onSelected`
- Leitor de tela anuncia o estado sozinho
- Área de toque mínima já respeitada

**Chip de perfil:** só quando `profile.isComplete` (senão ligar esvazia a lista sem explicação).

---

## Slide 5 — Contagem Viva e Ordenação

```dart
Semantics(liveRegion: true, child: Text('2 lugares encontrados'))
```

- Leitores de tela anunciam a mudança
- `DropdownButton<ExploreSort>` com `ExploreSort.values`
- Barra em `Wrap`: a ordenação desce de linha com fonte grande

---

## Slide 6 — Estados da Lista

| Estado | Tela |
|---|---|
| `loading` | indicador |
| `failure` | "Tentar novamente" |
| `ready` + vazio | "Nenhum lugar combina…" + **Limpar filtros** |
| `ready` + itens | cartões |

`switch` sobre `enum` → o compilador cobra todos os casos.

---

## Slide 7 — Reuso e Ponte

- `heroOrigin: 'explore'` → sem colisão com a Home
- `toggleFavoriteWithFeedback` → um só lugar para o `SnackBar` de erro
- CeliLac: `explore_page.dart`, `explore_filter_chips.dart`, `explore_results_bar.dart`, `toggle_favorite.dart`

**Próximo degrau:** Home e `AppShell`.
