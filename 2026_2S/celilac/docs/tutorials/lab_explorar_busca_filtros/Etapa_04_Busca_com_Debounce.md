# Etapa 4 — Busca com *Debounce* (`ExploreSearchField`)

## Introdução: O que este documento propõe e resolve?

### 1. O Problema Real
Ligar um `TextField` direto ao controlador parece simples:

```dart
TextField(onChanged: explore.setQuery)
```

Mas isso **recalcula e redesenha a lista a cada letra**. Digitar "padaria" dispara 7 filtragens e 7 reconstruções, a maioria descartada um instante depois. Com catálogo pequeno ninguém percebe; com a lista vinda de rede ou de SQLite, cada letra viraria uma consulta.

Há uma segunda dor, menos óbvia: **o texto do campo vive no `TextEditingController`, mas a "verdade" da busca vive em `ExploreFilters.query`.** Se "Limpar filtros" (ou um atalho da Home) zerar a busca no controlador, o campo continua mostrando o texto antigo, e o app mente.

### 2. O que esta Etapa Propõe
1. **Debounce:** só avisar o controlador depois que a pessoa **para de digitar** por 300 ms.
2. **Sincronização:** o campo acompanha o estado quando ele muda "por fora" (`didUpdateWidget`).
3. **Limpeza de recursos:** cancelar o `Timer` e descartar o `TextEditingController` no `dispose`.
4. **Botão de limpar** com `tooltip`, que age na hora (sem esperar o atraso).

---

## Visão Geral do Roteiro de Aula

| Momento | Tempo | O que acontece |
|---|---|---|
| **1. O Problema** | 10 min | Contamos quantas vezes a lista é recalculada ao digitar; provocamos o campo desatualizado. |
| **2. O Conceito** | 20 min | *Debounce* vs. *throttle*; `Timer`; ciclo de vida; `didUpdateWidget`. |
| **3. A Prática** | 30 min | Criamos `ExploreSearchField`. |
| **4. Verificação e Ponte** | 10 min | Teste com `tester.pump(Duration)`. |

---

## 1. O Problema (A Dor Provocada ao Vivo)

Coloque um `debugPrint('filtrou')` em `applyExploreFilters` e digite "padaria": são 7 mensagens. Depois, com o campo preenchido, toque em "Limpar filtros": a lista volta, mas o campo ainda diz "padaria".

---

## 2. O Conceito

### 2.1 *Debounce* × *throttle*
| Técnica | Comportamento | Uso típico |
|---|---|---|
| **Debounce** | espera **silêncio**; cada nova entrada reinicia a contagem | busca ao digitar |
| **Throttle** | deixa passar **no máximo 1 evento por intervalo** | rolagem, arrastar |

### 2.2 O `Timer`
`Timer(duração, callback)` agenda o callback. O padrão do debounce:

```dart
_timer?.cancel();                       // desfaz o agendamento anterior
_timer = Timer(delay, () => aviso());   // agenda de novo
```

Só o **último** agendamento chega a executar.

### 2.3 Quem é dono do quê
| Objeto | Dono |
|---|---|
| `TextEditingController`, `Timer` | o `State` do campo (ciclo de vida: criar e **descartar**) |
| `ExploreFilters.query` | o controlador (a "verdade" da busca) |

Todo `Timer` e `TextEditingController` criado no `State` precisa ser liberado no `dispose`; caso contrário o `Timer` pode disparar **depois** de a tela sair da árvore.

### 2.4 `didUpdateWidget`
Chamado quando o *widget pai* reconstrói este com **novos parâmetros**. É o lugar certo para reagir a "o `query` oficial mudou":

```dart
if (widget.query != oldWidget.query && widget.query != _controller.text) {
  _timer?.cancel();
  _controller.text = widget.query;
}
```

A segunda condição (`widget.query != _controller.text`) evita um laço: quando o próprio debounce dispara e atualiza o controlador, o `query` oficial passa a ser igual ao que já está digitado, e **não** reescrevemos o campo (o que moveria o cursor).

---

## 3. A Prática

### Arquivo: `lib/features/explore/presentation/widgets/explore_search_field.dart`

```dart
class ExploreSearchField extends StatefulWidget {
  const ExploreSearchField({
    super.key,
    required this.query,
    required this.onChanged,
    this.debounce = const Duration(milliseconds: 300),
  });

  /// O texto "oficial", vindo do controlador.
  final String query;
  final ValueChanged<String> onChanged;
  final Duration debounce;

  @override
  State<ExploreSearchField> createState() => _ExploreSearchFieldState();
}

class _ExploreSearchFieldState extends State<ExploreSearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.query);
  Timer? _timer;

  @override
  void didUpdateWidget(ExploreSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query && widget.query != _controller.text) {
      _timer?.cancel();
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onChanged(text));
    setState(() {}); // mostra ou esconde o botão de limpar na hora
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar por nome, bairro ou tipo',
        prefixIcon: const Icon(Icons.search, color: AppColors.navy),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpar busca',
                icon: const Icon(Icons.close),
                onPressed: _clear,
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
```

**Pontos de atenção**
- `debounce` é **parâmetro** (padrão 300 ms): em testes podemos usar `Duration.zero` ou avançar o relógio com `pump`.
- `late final TextEditingController _controller = TextEditingController(text: widget.query)`: o `late` permite usar `widget` no inicializador.
- `_clear` **cancela** o timer e avisa **na hora**: apagar não precisa de espera.
- O `setState(() {})` serve só para o `suffixIcon` reagir; o texto em si é gerenciado pelo `TextEditingController`.
- `TextInputAction.search` mostra a lupa no teclado. Podemos ainda tratar `onSubmitted` para aplicar imediatamente (desafio opcional).

---

## 4. Verificação e Ponte com o CeliLac

```dart
testWidgets('a busca só filtra depois de a pessoa parar de digitar', (tester) async {
  await _pumpExplore(tester);

  await tester.enterText(find.byType(TextField), 'bistro');
  await tester.pump(const Duration(milliseconds: 100));
  expect(find.byType(Card), findsNWidgets(4)); // ainda esperando

  await tester.pump(const Duration(milliseconds: 300));
  expect(find.byType(Card), findsOne);
});
```

`tester.pump(Duration)` avança o **relógio falso** do teste: nada de `sleep`, nada de teste lento.

| Peça | Arquivo no CeliLac |
|---|---|
| `ExploreSearchField` | `lib/features/explore/presentation/widgets/explore_search_field.dart` |

**Checklist**
- [ ] `Timer` cancelado antes de criar outro e no `dispose`.
- [ ] `TextEditingController` descartado no `dispose`.
- [ ] `didUpdateWidget` sincroniza o campo com o estado sem criar laço.
- [ ] Botão de limpar com `tooltip` e ação imediata.
- [ ] Atraso configurável por parâmetro.

**Próxima etapa:** a tela completa: chips, ordenação, contagem e estados da lista.
