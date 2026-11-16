# Etapa 4 — Busca com *Debounce*
## Esperar a pessoa parar de digitar

> **Instrução para o Gamma:** cada `---` é um slide.

---

## Slide 1 — Capa

### Etapa 4: Busca com *Debounce*
- **Foco:** `Timer`, ciclo de vida (`dispose`), `didUpdateWidget`, campo sincronizado com o estado

---

## Slide 2 — A Dor Nº 1: uma filtragem por letra

```text
p → pa → pad → pada → padar → padari → padaria
7 letras = 7 filtragens = 7 reconstruções
```

Com rede ou banco, seriam **7 consultas**.

---

## Slide 3 — A Dor Nº 2: campo que mente

```text
1. Digita "padaria" → lista filtrada
2. Toca em "Limpar filtros" → lista completa
3. O campo ainda mostra "padaria"
```

O texto do campo e `ExploreFilters.query` ficaram dessincronizados.

---

## Slide 4 — Debounce × Throttle

| Debounce | Throttle |
|---|---|
| Espera **silêncio** | No máx. 1 evento por intervalo |
| Cada entrada reinicia a espera | Ignora o excesso |
| **Busca ao digitar** | Rolagem, arrastar |

---

## Slide 5 — O padrão do `Timer`

```dart
_timer?.cancel();
_timer = Timer(const Duration(milliseconds: 300),
    () => widget.onChanged(text));
```

Só o **último** agendamento executa.

---

## Slide 6 — Ciclo de vida e sincronização

```dart
@override
void didUpdateWidget(old) {
  if (widget.query != old.query && widget.query != _controller.text) {
    _timer?.cancel();
    _controller.text = widget.query;   // campo acompanha o estado
  }
}

@override
void dispose() { _timer?.cancel(); _controller.dispose(); super.dispose(); }
```

A 2ª condição evita **laço** e salto do cursor.

---

## Slide 7 — Verificação e Checklist

```dart
await tester.enterText(find.byType(TextField), 'bistro');
await tester.pump(const Duration(milliseconds: 100));  // ainda 4 cartões
await tester.pump(const Duration(milliseconds: 300));  // agora 1
```

- [ ] `Timer` e `TextEditingController` liberados
- [ ] Limpar age na hora
- [ ] Atraso por parâmetro

**Próximo degrau:** a tela completa.
