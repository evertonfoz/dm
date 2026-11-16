# Etapa 3 — Estado Derivado e Múltiplas Fontes
## Guardar o mínimo, calcular o resto

> **Instrução para o Gamma:** cada `---` é um slide.

---

## Slide 1 — Capa

### Etapa 3: `ExploreController` e Estado Derivado
- **Foco:** guardado × derivado, `watch` em três fontes, `enum` de status, não notificar sem mudança

---

## Slide 2 — Quatro fontes, uma lista

| Fonte | Dono | Muda quando |
|---|---|---|
| Catálogo | repositório | carrega / tenta de novo |
| Filtros | Explorar | toque / digitação |
| Perfil | `ProfileController` | salva o perfil |
| Favoritos | `FavoritesController` | favorita em qualquer aba |

---

## Slide 3 — A Dor: a lista que envelhece

```text
1. Explorar: liga "Só favoritos"
2. Início: favorita um lugar novo
3. Explorar: o lugar novo NÃO aparece
```

Causa: guardamos o **resultado** (`_visible`) e ninguém o recalculou.

---

## Slide 4 — Guardado × Derivado

| Guardado | Derivado |
|---|---|
| catálogo, filtros, status | lista visível, "8 lugares encontrados" |
| precisa de cuidado | sempre correto |

> **Regra:** se pode ser calculado a partir de outros dados, não guarde.

---

## Slide 5 — Três `watch`, uma lista

```dart
final explore   = context.watch<ExploreController>();
final profile   = context.watch<ProfileController>().profile;
final favorites = context.watch<FavoritesController>();

final results = applyExploreFilters(explore.catalog, explore.filters,
    profile: profile, favoriteIds: {...});
```

Alternativas: `context.select` (reconstrói por valor) · `ProxyProvider` (objeto que depende de outros)

---

## Slide 6 — Cuidados do Controlador

- `enum ExploreStatus { loading, ready, failure }` → sem combinações impossíveis
- `_update` ignora `next == _filters` → sem rebuild à toa
- `Set`s sempre **copiados**
- `notifyListeners` só depois do `await` → nunca durante o `build`
- `_loading ??= _load()` → carga única

---

## Slide 7 — Ponte e Checklist

- CeliLac: `explore_controller.dart` · `celilac_app.dart` (3º provedor)
- [ ] Não guarda a lista filtrada
- [ ] Ignora valores iguais
- [ ] Provedor acima do `MaterialApp`

**Próximo degrau:** campo de busca com *debounce*.
