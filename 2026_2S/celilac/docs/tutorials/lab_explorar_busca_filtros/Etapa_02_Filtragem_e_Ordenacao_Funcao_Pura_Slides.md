# Etapa 2 — Filtragem e Ordenação como Função Pura
## Tirando a regra de negócio de dentro do `build`

> **Instrução para o Gamma:** cada `---` é um slide.

---

## Slide 1 — Capa

### Etapa 2: Função Pura de Filtragem e Ordenação
- **Foco:** função pura, semântica E/OU, normalização de acentos, `sort` estável, imutabilidade do catálogo

---

## Slide 2 — A Dor

```dart
final visible = catalog.where((e) {
  // 30 linhas de regra no build...
}).toList()..sort(...);
```

- Só se testa abrindo o app
- `build` mistura layout e regra
- Risco de ordenar o **catálogo original** sem querer

> "Como garanto que *Bistrô* aparece ao digitar *bistro*?"

---

## Slide 3 — Função Pura

```text
entrada: catálogo + filtros + perfil + favoritos
   │
   ▼  applyExploreFilters
   │
saída:  lista nova, filtrada e ordenada
```

- Mesmos argumentos → mesmo resultado
- Sem `BuildContext`, sem `Provider`, sem I/O
- Teste em milissegundos

---

## Slide 4 — Semântica dos Filtros

| Grupo | Regra |
|---|---|
| Entre grupos | **E** |
| Categorias | **OU** |
| Opções alimentares | **E** (`containsAll`) |
| Texto | **todas** as palavras |

Por quê **E** nas opções? Quem pede "sem glúten" **e** "sem lactose" precisa dos dois.

---

## Slide 5 — Normalização de Texto

```text
"  Bistrô Bem-Estar " → "bistro bem-estar"
"CAFÉ"                → "cafe"
```

- `trim` → minúsculas → troca de acentos
- Campo pesquisado: **nome + bairro + tipo**

---

## Slide 6 — `List.sort` não é estável

| Sem desempate | Com desempate por nome |
|---|---|
| Distâncias iguais → ordem imprevisível | Ordem sempre igual → testável |

Também: `where().toList()` cria **cópia**; o catálogo fica intacto.

---

## Slide 7 — Ponte e Checklist

- CeliLac: `explore_query.dart` e `search_text.dart`
- [ ] Sem imports de Flutter
- [ ] E/OU corretos
- [ ] Desempate por nome
- [ ] Catálogo original preservado

**Próximo degrau:** quem guarda o catálogo, os filtros e como juntar com perfil e favoritos.
