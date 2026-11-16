# Laboratório Sequencial: Explorar — Busca, Filtros e Ordenação (Teoria e Prática Etapa a Etapa)

## 1. Motivação e Diagnóstico Pedagógico

O material principal da Etapa 6 do CeliLac — [CeliLac_Explorar_Busca_e_Filtros.md](../CeliLac_Explorar_Busca_e_Filtros.md) e [CeliLac_Explorar_Busca_e_Filtros_Slides.md](../CeliLac_Explorar_Busca_e_Filtros_Slides.md) — apresenta a solução completa, já integrada ao app: a aba **Explorar** com busca, filtros combináveis, ordenação, atalhos vindos da Home e testes.

Como ponto de chegada ele é bom, mas, aplicado de uma vez em sala, junta muitos assuntos: modelagem de uma consulta, regras de filtragem (E/OU), normalização de texto, estado derivado a partir de três fontes, *debounce*, sincronização de campo de texto com o estado, estados de carregamento/erro/vazio, acessibilidade de filtros e navegação entre abas.

### A Solução Pedagógica: Um Projeto-Laboratório Sequencial

Seguimos o mesmo método do [laboratório de Favoritos](../lab_favoritos_sqlite_provider/README.md): **um único conceito por vez**, num projeto enxuto (`lab_explorar`), antes de consolidar no CeliLac. Cada degrau repete o ciclo de 4 passos:

1. **O Problema (A Dor):** o que não funciona ou fica difícil de manter na etapa anterior (provocado ao vivo).
2. **O Conceito (Teoria Focada):** o fundamento que resolve exatamente essa dor e as alternativas.
3. **A Prática (Mão na Massa Isolada):** alteração cirúrgica, tocando só o conceito da vez.
4. **Verificação e Ponte com o CeliLac:** como validar e onde a peça mora no CeliLac.

### Pré-requisito

Quem fez o laboratório de Favoritos já tem o ponto de partida: `Establishment`, `FavoritesController` + `provider`, `EstablishmentCard` e `AppShell` com `IndexedStack`. A [Etapa 1](./Etapa_01_Estado_de_Consulta_Imutavel.md) lista o que precisa existir antes de começar.

---

## 2. Mapa Geral dos 7 Degraus Conceituais

| Etapa | Conceito Central | O Problema Motivador | Teoria Trabalhada | Entrega Prática e Verificação |
|---|---|---|---|---|
| **Etapa 1** | **Estado de consulta como valor imutável** | Cada filtro vira uma variável solta num `State`; combinar, limpar e comparar escolhas vira bagunça. | Objeto de valor; imutabilidade; `copyWith`; `==`/`hashCode` com `Set`; contagem de filtros ativos; o que é e o que não é "filtro" (ordenação). | `ExploreFilters` e `ExploreSort` no domínio, sem Flutter. |
| **Etapa 2** | **Filtragem e ordenação como função pura** | A regra de filtrar está misturada ao `build`; só dá para testar abrindo a tela. | Função pura; semântica E entre grupos e OU dentro de categorias; normalização de texto (acentos); `List.sort` não é estável e o desempate; não alterar a lista original. | `applyExploreFilters` e `normalizeSearchText` testadas em milissegundos. |
| **Etapa 3** | **Estado derivado e múltiplas fontes** | Guardar a lista filtrada deixa-a velha quando o perfil ou os favoritos mudam. | Estado guardado vs. derivado; `ExploreController` guardando só catálogo + filtros; `watch` em três fontes; estados `loading/ready/failure`; alternativas (`ProxyProvider`, `select`). | `ExploreController` e a lista recalculada no `build`. |
| **Etapa 4** | **Busca com *debounce*** | A lista é recalculada a cada letra e o campo não acompanha mudanças feitas por fora. | `Timer`; cancelar e recriar; `dispose`; `didUpdateWidget` para sincronizar texto com o estado; botão de limpar. | `ExploreSearchField` com atraso de 300 ms. |
| **Etapa 5** | **Interface de filtros acessível e estados da lista** | Chips com rolagem horizontal escondem opções com fonte grande; lista vazia deixa a pessoa sem saída. | `FilterChip` em `Wrap`; `DropdownButton`; `liveRegion`; estado vazio com "Limpar filtros"; `Hero` com origem `explore`; helper de favoritar. | `ExplorePage` completa. |
| **Etapa 6** | **Integração com a Home e o `AppShell`** | A Home mostra "em breve" na busca, nas categorias e no "Ver todos". | Controlador compartilhado como "canal" entre abas; callback para trocar de aba; `IndexedStack` preserva filtros; `showOnly(category)`. | Atalhos da Home abrem Explorar já filtrado. |
| **Etapa 7** | **Testes: função pura, controlador e widgets com tempo** | Como testar debounce, lista lazy e acessibilidade sem emulador? | Teste de unidade da função; teste do controlador; `tester.pump(Duration)`; tela alta para lista lazy; `labeledTapTargetGuideline`; teste de integração no shell. | Suíte com 38+ testes da feature rodando no terminal. |

---

## 3. Detalhamento de Cada Etapa

### [Etapa 1 — Estado de Consulta como Valor Imutável](./Etapa_01_Estado_de_Consulta_Imutavel.md)
- **Guia:** [`Etapa_01_Estado_de_Consulta_Imutavel.md`](./Etapa_01_Estado_de_Consulta_Imutavel.md) · **Slides:** [`..._Slides.md`](./Etapa_01_Estado_de_Consulta_Imutavel_Slides.md)
- **Ponte com o CeliLac:** `lib/features/explore/domain/explore_filters.dart` e `explore_sort.dart`.

### [Etapa 2 — Filtragem e Ordenação como Função Pura](./Etapa_02_Filtragem_e_Ordenacao_Funcao_Pura.md)
- **Guia:** [`Etapa_02_Filtragem_e_Ordenacao_Funcao_Pura.md`](./Etapa_02_Filtragem_e_Ordenacao_Funcao_Pura.md) · **Slides:** [`..._Slides.md`](./Etapa_02_Filtragem_e_Ordenacao_Funcao_Pura_Slides.md)
- **Ponte com o CeliLac:** `explore_query.dart` e `search_text.dart`.

### [Etapa 3 — Estado Derivado e Múltiplas Fontes](./Etapa_03_Estado_Derivado_e_Multiplas_Fontes.md)
- **Guia:** [`Etapa_03_Estado_Derivado_e_Multiplas_Fontes.md`](./Etapa_03_Estado_Derivado_e_Multiplas_Fontes.md) · **Slides:** [`..._Slides.md`](./Etapa_03_Estado_Derivado_e_Multiplas_Fontes_Slides.md)
- **Ponte com o CeliLac:** `explore_controller.dart`, `celilac_app.dart` (3º provedor do `MultiProvider`).

### [Etapa 4 — Busca com *Debounce*](./Etapa_04_Busca_com_Debounce.md)
- **Guia:** [`Etapa_04_Busca_com_Debounce.md`](./Etapa_04_Busca_com_Debounce.md) · **Slides:** [`..._Slides.md`](./Etapa_04_Busca_com_Debounce_Slides.md)
- **Ponte com o CeliLac:** `widgets/explore_search_field.dart`.

### [Etapa 5 — Interface de Filtros Acessível e Estados da Lista](./Etapa_05_Interface_de_Filtros_e_Estados_da_Lista.md)
- **Guia:** [`Etapa_05_Interface_de_Filtros_e_Estados_da_Lista.md`](./Etapa_05_Interface_de_Filtros_e_Estados_da_Lista.md) · **Slides:** [`..._Slides.md`](./Etapa_05_Interface_de_Filtros_e_Estados_da_Lista_Slides.md)
- **Ponte com o CeliLac:** `explore_page.dart`, `explore_filter_chips.dart`, `explore_results_bar.dart`, `favorites/presentation/toggle_favorite.dart`.

### [Etapa 6 — Integração com a Home e o `AppShell`](./Etapa_06_Integracao_com_Home_e_AppShell.md)
- **Guia:** [`Etapa_06_Integracao_com_Home_e_AppShell.md`](./Etapa_06_Integracao_com_Home_e_AppShell.md) · **Slides:** [`..._Slides.md`](./Etapa_06_Integracao_com_Home_e_AppShell_Slides.md)
- **Ponte com o CeliLac:** `app_shell.dart` e `home_page.dart`.

### [Etapa 7 — Testes: Função Pura, Controlador e Widgets com Tempo](./Etapa_07_Testes_da_Busca_e_Filtros.md)
- **Guia:** [`Etapa_07_Testes_da_Busca_e_Filtros.md`](./Etapa_07_Testes_da_Busca_e_Filtros.md) · **Slides:** [`..._Slides.md`](./Etapa_07_Testes_da_Busca_e_Filtros_Slides.md)
- **Ponte com o CeliLac:** `test/features/explore/`, `test/support/explore_catalog.dart` e `test/app/app_shell_test.dart`.

---

## 4. Desafios para ir além (fora do escopo da etapa)

1. **Foco automático no campo de busca** ao tocar em "Buscar produtos ou lugares" na Home (hoje só abre a aba).
2. **Persistir os filtros** entre execuções do app com `shared_preferences`.
3. **Histórico de buscas recentes** em SQLite (reaproveita a Etapa 5 de Favoritos: migração `v2`).
4. **Ordenar por "mais perto" com localização real** (`geolocator`), que é o roteiro de próximas fases do CeliLac.
