# Etapa 7 — Testes da Busca e dos Filtros
## Função pura, controlador e widgets com relógio falso

> **Instrução para o Gamma:** cada `---` é um slide.

---

## Slide 1 — Capa

### Etapa 7: Testando Explorar
- **Foco:** pirâmide de testes, `pump(Duration)`, dublês, lista lazy, acessibilidade

---

## Slide 2 — Cada Peça, um Tipo de Teste

| Peça | Teste |
|---|---|
| `applyExploreFilters`, `ExploreFilters` | **unidade** (sem Flutter) |
| `ExploreController` | **unidade** com dublê |
| `ExplorePage`, debounce | **widget** |
| Home ↔ Explorar | **integração** no shell |

---

## Slide 3 — Armadilha 1: a Lista Lazy

```dart
expect(find.byType(Card), findsNWidgets(4));  // ❌ "found 2"
```

`SliverList` só monta o que cabe → use **tela alta** no teste (`360×2400`).
O app estava certo; o teste é que não montava tudo.

---

## Slide 4 — Armadilha 2: o Tempo

```dart
await tester.enterText(find.byType(TextField), 'bistro');
await tester.pump(const Duration(milliseconds: 100));  // 4 cartões
await tester.pump(const Duration(milliseconds: 300));  // 1 cartão
```

Relógio **simulado**: sem `sleep`, sem teste lento.

---

## Slide 5 — Dublês e Dados Fixos

- `StubEstablishmentRepository(nearbyResults: [falha, sucesso])` → testa "Tentar novamente"
- `FakeEstablishmentRepository(delay: Duration.zero)` → sem 800 ms de rede simulada
- `explore_catalog.dart` → 4 lugares conhecidos, **fora de ordem** de propósito

---

## Slide 6 — Acessibilidade Automática

```dart
await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
```

E *overflow*: `320×640` com fonte `200%` → `tester.takeException()` deve ser `null`.

---

## Slide 7 — Resultado e Ponte

- 38 testes da feature + 2 de integração no shell
- Suíte do CeliLac: **162 testes** passando
- `flutter analyze`: sem avisos

**Fim do laboratório** → consolidar no material principal.
