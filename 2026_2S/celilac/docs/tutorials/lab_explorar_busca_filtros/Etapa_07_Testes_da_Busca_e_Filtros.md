# Etapa 7 — Testes: Função Pura, Controlador e Widgets com Tempo

## Introdução: O que este documento propõe e resolve?

### 1. O Problema Real
A feature Explorar tem peças de natureza diferente, e cada uma pede um tipo de teste:

| Peça | Dificuldade de testar | Tipo de teste ideal |
|---|---|---|
| `applyExploreFilters`, `normalizeSearchText`, `ExploreFilters` | nenhuma (puras) | **unidade**, sem Flutter |
| `ExploreController` | assíncrono (carga, falha, nova tentativa) | **unidade** com dublê de repositório |
| `ExploreSearchField` / `ExplorePage` | **tempo** (debounce), **lista lazy**, acessibilidade | **widget** |
| Home ↔ Explorar | duas telas e a barra de abas | **widget de integração** no `AppShell` |

Armadilhas reais encontradas ao escrever estes testes:

1. **Debounce:** como esperar 300 ms sem `sleep` e sem deixar o teste lento?
2. **Lista lazy:** em tela de 800 px, `SliverList` só monta alguns cartões; `findsNWidgets(4)` falha mesmo com o app correto.
3. **Acessibilidade:** como garantir áreas de toque e rótulos sem olhar a tela?
4. **Provedores:** a página depende de **três** controladores; o helper de testes precisa fornecê-los.

### 2. O que esta Etapa Propõe
Uma suíte em camadas, rápida e sem emulador, com **38 testes da feature** (mais 2 no shell).

---

## Visão Geral do Roteiro de Aula

| Momento | Tempo | O que acontece |
|---|---|---|
| **1. O Problema** | 10 min | Teste de widget ingênuo falhando por causa da lista lazy. |
| **2. O Conceito** | 20 min | Pirâmide de testes; relógio falso; dublês; diretrizes de acessibilidade. |
| **3. A Prática** | 40 min | Dados de teste, helper, quatro arquivos de teste. |
| **4. Verificação e Ponte** | 10 min | `flutter analyze` + `flutter test`. |

---

## 1. O Problema

Escreva `expect(find.byType(Card), findsNWidgets(4))` com a tela padrão de 800 px de altura: falha com "found 2 widgets". O app está certo; o teste é que não monta tudo.

---

## 2. O Conceito

### 2.1 Pirâmide de testes
Muitos testes **de unidade** (rápidos, baratos), alguns de **widget**, poucos de **integração**. A Etapa 2 pagou dividendos: a regra mais complexa é testada sem tocar em widget.

### 2.2 Relógio falso: `pump(Duration)`
Em testes de widget o tempo é **simulado**. `await tester.pump(const Duration(milliseconds: 300))` avança o relógio e dispara o `Timer` do debounce **sem esperar de verdade**. `pumpAndSettle()` avança até não haver mais animações/timers pendentes.

### 2.3 Dublês
- `StubEstablishmentRepository(nearbyResults: [...])`: devolve, em sequência, os resultados que a fila definir (primeiro falha, depois acerta: ótimo para "Tentar novamente"). Também conta `nearbyCalls`.
- `MemoryFavoritesRepository` e `MemoryProfileRepository`: já existentes.
- `explore_catalog.dart`: quatro lugares fixos com distância, nota e opções **conhecidas**, para as asserções serem exatas.

### 2.4 Tela alta para lista lazy
`tester.view.physicalSize` maior (no helper: `Size(360, 2400)`) faz o `SliverList` montar todos os cartões. Em testes que verificam *overflow*, volta-se a `320×640` com fonte 200%.

### 2.5 Diretrizes de acessibilidade
```dart
await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
```
Verificam área mínima de toque e que todo alvo de toque tem rótulo. Exigem `tester.ensureSemantics()`.

---

## 3. A Prática

### Arquivo 1: `test/support/explore_catalog.dart`
Quatro constantes (`cafeAconchego`, `padariaLeve`, `bistro`, `emporio`) e `const catalog = [emporio, bistro, cafeAconchego, padariaLeve];`. A lista nasce **fora de ordem** de propósito: se a função não ordenar, os testes pegam.

### Arquivo 2: `test/support/pump_app.dart` (acréscimo)
`pumpWithProfile` ganha `exploreRepository` e passa a fornecer um terceiro provedor:

```dart
final exploreController = ExploreController(
  exploreRepository ?? const FakeEstablishmentRepository(delay: Duration.zero),
);
addTearDown(exploreController.dispose);
// ...
ChangeNotifierProvider<ExploreController>.value(value: exploreController),
```

`FakeEstablishmentRepository(delay: Duration.zero)`: o `delay` de 800 ms (que simula rede) só atrapalharia os testes.

### Arquivo 3: `test/features/explore/search_text_test.dart` e `explore_query_test.dart`
Testes de unidade, agrupados por assunto (`group('busca')`, `group('categorias')`, `group('opções alimentares')`, `group('perfil e favoritos')`, `group('ordenação')`, `group('ExploreFilters')`). Exemplo de combinação:

```dart
test('os filtros se combinam (E entre grupos)', () {
  const filters = ExploreFilters(
    query: 'a',
    dietaryOptions: {DietaryOption.glutenFree},
    categories: {EstablishmentCategory.bakery, EstablishmentCategory.cafe},
  );
  expect(_ids(filters), ['1', '2']);
});
```

### Arquivo 4: `test/features/explore/explore_controller_test.dart`
Status inicial, carga única (`nearbyCalls == 1` mesmo chamando `load` duas vezes), falha e `retry`, `toggleCategory`, não notificar sem mudança, `showOnly` e `clearFilters` (preservando a ordenação).

### Arquivo 5: `test/features/explore/explore_page_test.dart`
Um helper monta a tela:

```dart
Future<void> _pumpExplore(
  WidgetTester tester, {
  List<Future<List<Establishment>> Function()>? results,
  DietaryProfile profile = DietaryProfile.empty,
  MemoryFavoritesRepository? favorites,
  Size size = const Size(360, 2400),
  double textScale = 1,
}) async { /* ... pumpWithProfile + pumpAndSettle ... */ }
```

Casos cobertos: carregamento, erro + nova tentativa, debounce, botão de limpar, combinação de chips, estado vazio + "Limpar filtros", reordenação, chip de perfil (ausente e presente), "Só favoritos" com desfavoritar, favoritar um cartão, acessibilidade e *overflow* a `320×640` com fonte `200%`.

Um detalhe útil: para verificar **ordem** na tela, compare a posição vertical dos textos:

```dart
double top(String name) => tester.getTopLeft(_inResults(name)).dy;
expect(top('Bistrô Bem-Estar') < top('Café Aconchego'), isTrue);
```

`_inResults` restringe o `find.text` aos textos **dentro de `Card`**, para não confundir com o nome que aparece no filtro ou em outro lugar.

### Arquivo 6: `test/app/app_shell_test.dart` (acréscimos)
Os dois testes de integração da Etapa 6.

---

## 4. Verificação e Ponte com o CeliLac

```bash
flutter analyze
flutter test test/features/explore
flutter test
```

No CeliLac, a suíte completa passa a ter **162 testes** (eram 122 antes desta etapa).

| Pasta/arquivo | Conteúdo |
|---|---|
| `test/features/explore/` | unidade (domínio e controlador) e widget (página) |
| `test/support/explore_catalog.dart` | catálogo fixo de teste |
| `test/support/pump_app.dart` | helper com os 3 provedores |
| `test/app/app_shell_test.dart` | integração Home ↔ Explorar |

**Checklist**
- [ ] Regras de filtragem testadas sem Flutter.
- [ ] Controlador testado com dublê e fila de resultados.
- [ ] Debounce testado com `pump(Duration)`, sem `sleep`.
- [ ] Tela alta para lista lazy; `320×640` + `200%` para *overflow*.
- [ ] Diretrizes de acessibilidade verificadas.
- [ ] `flutter analyze` sem avisos.

**Fim do laboratório.** Retorne ao [material principal da Etapa 6](../CeliLac_Explorar_Busca_e_Filtros.md) para consolidar tudo no CeliLac.
