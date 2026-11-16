# Etapa 6 — Integração com a Home e o `AppShell`
## Dois canais: um para dados, outro para navegação

> **Instrução para o Gamma:** cada `---` é um slide.

---

## Slide 1 — Capa

### Etapa 6: Home → Explorar
- **Foco:** estado compartilhado como canal de dados, callback como canal de navegação, `IndexedStack`

---

## Slide 2 — A Dor: Três "em breve"

| Na Home | Hoje |
|---|---|
| Campo "Buscar produtos ou lugares" | SnackBar "em breve" |
| Atalho de categoria | SnackBar "em breve" |
| "Ver todos" | SnackBar "em breve" |

A aba Explorar está pronta, ao lado, ignorada.

---

## Slide 3 — Quem sabe qual aba está aberta?

```text
AppShell (_selectedIndex)  ← só ele troca de aba
   ├── HomePage      ← precisa ir para Explorar
   ├── ExplorePage
   ├── FavoritesPage
   └── ProfilePage
```

A Home **não deve importar** a `ExplorePage`.

---

## Slide 4 — Dois Canais

| Canal | Carrega | Como |
|---|---|---|
| `ExploreController` | **dados:** "só Padarias" | `context.read` + `provider` |
| `onOpenExplore` | **navegação:** "mostre a aba 1" | callback do `AppShell` |

---

## Slide 5 — Três Intenções, Três Métodos

| Gesto na Home | Chamada |
|---|---|
| Toca na categoria | `showOnly(category)` + abrir aba |
| Toca em "Ver todos" | `clearFilters()` + abrir aba |
| Toca na busca | só abrir aba (preserva filtros) |

`showOnly` ≠ `toggleCategory`: o atalho começa **do zero**; o chip soma ou tira.

---

## Slide 6 — `IndexedStack` e Estado

- Todas as abas vivas ao mesmo tempo
- Filtros no **controlador** (não no `State`) → sobrevivem à troca de aba
- Favoritos vazio: "Ver estabelecimentos" agora vai a **Explorar**

---

## Slide 7 — Verificação e Ponte

- Teste no shell: tocar em "Padaria" na Home → Explorar mostra só a padaria com o chip marcado
- Teste: filtros sobrevivem a Perfil → Explorar
- CeliLac: `app_shell.dart`, `home_page.dart`, catálogo com 12 lugares

**Próximo degrau:** testes.
