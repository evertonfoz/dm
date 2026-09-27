# CeliLac — Proposta: Onboarding Profissional

> Objetivo: levar para o onboarding **as mesmas técnicas usadas na `SplashPage`**, em etapas pequenas e demonstráveis em vídeo. Cada etapa termina com **"Execute"**, que é o momento de rodar o app e mostrar o resultado.

---

## 0. Diagnóstico: o que foi feito na Splash

Arquivo: `lib/features/startup/presentation/splash_page.dart`

| # | Técnica usada na Splash | Onde aparece |
|---|---|---|
| 1 | Cores da marca como constantes (`_navy`, `_gold`, `_background`) | topo do `_SplashPageState` |
| 2 | Fundo em `LinearGradient` (branco → `#F2F2F2`) | `Container` do `body` |
| 3 | `SafeArea` + padding horizontal de 32 | layout raiz |
| 4 | Distribuição vertical com `Spacer(flex:)` | `Column` principal |
| 5 | `AnimationController` + `TickerProviderStateMixin` | `initState` |
| 6 | Animação escalonada com `Interval` (logo → texto → rodapé) | `_logoFade`, `_textFade`, `_footerFade` |
| 7 | `FadeTransition`, `ScaleTransition` (`easeOutBack`), `SlideTransition` | `build` |
| 8 | Imagem em "cartão": `Container` branco, `borderRadius` 40, `BoxShadow` navy, `Clip.antiAlias`, `BoxFit` | `_buildLogo()` |
| 9 | Tipografia do `textTheme` com `copyWith` (cor navy, `w700`, `letterSpacing`) | título "CeliLac" |
| 10 | Barra dourada de destaque (40×3) sob o título | assinatura visual |
| 11 | Descrição em navy com `alpha: 0.7` | subtítulo |
| 12 | Progresso visível: `LinearProgressIndicator` dourado sobre navy 8% | `_buildProgress()` |
| 13 | `AnimatedSwitcher` + `ValueKey` para trocar texto suavemente | status "Preparando…" |
| 14 | `AnimatedBuilder` para reconstruir só o trecho animado | `_buildProgress()` |
| 15 | `FontFeature.tabularFigures()` no percentual | `%` |
| 16 | Transição de rota com `PageRouteBuilder` + `FadeTransition` (500 ms) | `_initialize()` |
| 17 | `if (!mounted) return;` após cada `await` | `_initialize()` |
| 18 | `dispose()` dos controllers | `dispose()` |
| 19 | Métodos privados de build (`_buildLogo`, `_buildProgress`) para organizar | classe |

### Pontos de atenção encontrados (resolver antes de gravar)

1. **O fluxo para o onboarding está comentado.** Hoje a Splash vai **sempre** para a `HomePage` (linhas 87–112). O onboarding nunca aparece.
2. Por consequência, os imports de `OnboardingStorage` e `OnboardingPage` estão sem uso (warning do analyzer).
3. `flutter_spinkit` foi adicionado ao `pubspec.yaml`, mas não é usado em `lib/`. Remova a dependência ou justifique o uso.
4. As cores da marca estão **presas dentro da Splash**. Para o onboarding usar a mesma identidade, elas precisam sair de lá (Etapa 1).
5. Em `pubspec.yaml` só o arquivo `logo_celilac.png` está declarado. Os assets do onboarding vão precisar de uma nova entrada.
6. O onboarding atual usa `ElevatedButton` padrão, ícones genéricos, fundo branco puro e nenhum indicador. Visualmente, ele "não pertence" ao mesmo produto que a Splash.

---

## Mapa: da Splash para o Onboarding

| Na Splash | No Onboarding |
|---|---|
| Cores `_navy` / `_gold` / `_background` | `AppColors` compartilhado (Etapa 1) |
| Gradiente de fundo | O mesmo gradiente, **fixo** atrás do `PageView` (Etapa 3) |
| Logo em cartão com sombra | Ilustração de cada página no mesmo "cartão" (Etapa 4) |
| Título navy + barra dourada + subtítulo 70% | Título + barra dourada + descrição de cada página (Etapa 4) |
| Barra de progresso dourada | Indicador de "dots" dourado (Etapa 5) |
| `AnimatedSwitcher` no status | `AnimatedSwitcher` no texto "Próximo" → "Começar" (Etapa 6) |
| Entrada escalonada com `Interval` | Entrada escalonada da primeira página (Etapa 7) |
| Rota com `FadeTransition` | Transição Onboarding → Home com fade (Etapa 8) |
| `mounted` + `dispose` | Mantidos e reforçados, com proteção contra toque duplo (Etapa 8) |
| Logo da Splash | *(opcional)* `Hero` do logo da Splash até o topo do onboarding (Etapa 9) |

---

## Etapa 0: Reativar o fluxo Splash → Onboarding

**Conceito para o vídeo:** antes de melhorar a tela, garantir que ela é alcançável.

Em `_initialize()` da Splash, depois das animações:

```dart
await _progressController.forward();
if (!mounted) return;

final completed = await OnboardingStorage().isCompleted();
if (!mounted) return;

_goTo(completed ? const HomePage() : const OnboardingPage());
```

Extraia a transição que já existe para um método, para reaproveitá-la nos dois destinos:

```dart
void _goTo(Widget page) {
  Navigator.of(context).pushReplacement(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}
```

**Dica para a gravação:** para ver o onboarding várias vezes, adicione em `OnboardingStorage` um método de desenvolvimento:

```dart
Future<void> reset() => _preferences.remove(_completedKey);
```

Chame-o temporariamente no `main()` ou desinstale o app entre as execuções.

✅ **Execute:** Splash → (fade) → onboarding atual, ainda "feio". Esse é o "antes" do vídeo.

---

## Etapa 1: Extrair a identidade visual (`AppColors`)

**Conceito:** o que é identidade não deve pertencer a uma única tela.

Criar `lib/app/theme/app_colors.dart`:

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color navy = Color(0xFF263D4F);
  static const Color gold = Color(0xFFD9A53A);
  static const Color background = Color(0xFFF2F2F2);
}
```

Na Splash, substitua `_navy`, `_gold` e `_background` por `AppColors.navy` etc. O resultado visual é idêntico, e esse é o ponto da demonstração: **refatorar sem mudar o comportamento**.

> Alternativa mais avançada, que pode ficar para a etapa "Home real": configurar um `ThemeData` com `ColorScheme.fromSeed(seedColor: AppColors.navy)` em `CeliLacApp`. Nesta etapa, `AppColors` basta e mantém o foco.

✅ **Execute:** a Splash continua igual. O onboarding ainda não mudou.

---

## Etapa 2: Ilustrações e assets

**Conceito:** a imagem precisa apoiar a mensagem (material, seções 6 a 9), e a organização de pastas faz parte da arquitetura.

### 2.1 Estrutura de pastas

```text
assets/
├── brand/
│   └── logo_celilac.png
└── images/
    └── onboarding/
        ├── discovery.png
        ├── information.png
        └── profile.png
```

> 🎨 Os **prompts prontos** para gerar essas três imagens estão na seção [Prompts para gerar as ilustrações](#prompts-para-gerar-as-ilustrações), no fim deste arquivo.

### 2.2 `pubspec.yaml`

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/brand/logo_celilac.png
    - assets/images/onboarding/
```

> Mostre no vídeo que, **sem** essa declaração, o `Image.asset` falha em tempo de execução ("Unable to load asset"). É um erro didático.

### 2.3 Evoluir o modelo `OnboardingItem`

```dart
class OnboardingItem {
  const OnboardingItem({
    required this.title,
    required this.description,
    required this.imagePath,
  });

  final String title;
  final String description;
  final String imagePath;
}
```

A importação de `material.dart` deixa de ser necessária, e o modelo de domínio fica sem dependência de UI. Vale comentar isso no vídeo.

### 2.4 Revisão narrativa dos textos (material, seção 51)

| # | Ideia | Título | Descrição |
|---|---|---|---|
| 1 | Descoberta | Encontre opções adequadas a você | Descubra produtos e estabelecimentos considerando suas necessidades alimentares. |
| 2 | Informação | Entenda antes de escolher | Consulte informações alimentares e conheça melhor cada opção. |
| 3 | Personalização | Uma experiência feita para você | Informe suas necessidades e receba opções mais relevantes. |

Ajustes propostos:
- **Página 2:** "as opções disponíveis" virou "cada opção", que é mais curto.
- **Página 3:** o texto atual ("Seu perfil alimentar poderá ajudar o CeliLac a apresentar…") está na voz passiva e é longo. A versão proposta usa linguagem direta, como na seção 47 do material.

✅ **Execute:** ainda não há mudança visual. O próximo passo usa as imagens.

---

## Etapa 3: Estrutura da página (fundo, `SafeArea`, regiões fixas)

**Conceito:** o fundo e as ações **não deslizam**. Só o conteúdo desliza. Com isso, o botão nunca muda de lugar (material, seção 29).

Estrutura do novo `build` da `OnboardingPage`:

```text
Scaffold (backgroundColor: AppColors.background)
└── Container (mesmo LinearGradient da Splash)
    └── SafeArea
        └── Column
            ├── _buildTopBar()     ← "Pular" (Etapa 6)
            ├── Expanded
            │   └── PageView.builder   ← só isto desliza
            ├── _PageIndicator     ← dots (Etapa 5)
            ├── SizedBox(24)
            └── Padding(horizontal: 32)
                └── FilledButton   ← ação principal (Etapa 6)
```

Nesta etapa montamos só o **esqueleto**: fundo + `PageView` + botão (ainda o `ElevatedButton` atual). O indicador e o "Pular" entram nas Etapas 5 e 6, nos lugares marcados.

Substitua o `build` do `_OnboardingPageState` por:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.background,
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, AppColors.background],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Etapa 6: _buildTopBar() entra aqui
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: OnboardingPage.items.length,
                itemBuilder: (context, index) {
                  return _OnboardingContent(item: OnboardingPage.items[index]);
                },
              ),
            ),
            // Etapa 5: _PageIndicator entra aqui
            Padding(
              padding: const EdgeInsets.fromLTRB(32.0, 24.0, 32.0, 24.0),
              child: ElevatedButton(
                onPressed: _nextPage,
                child: Text(
                  _currentPage < OnboardingPage.items.length - 1
                      ? 'Próximo'
                      : 'Começar',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

- O `bottomNavigationBar` **deixa de existir**. O botão passa a ficar dentro da `Column`, sob o mesmo gradiente, e o `SafeArea` continua protegendo a borda inferior.
- O gradiente é **copiado da Splash**. Se ele se repetir mais vezes, é a deixa para extrair um widget `BrandBackground`.

✅ **Execute:** o fundo já é igual ao da Splash, e a troca de tela deixa de ter um "salto" de cor.

---

## Etapa 4: `_OnboardingContent` com a linguagem visual da Splash

**Conceito:** reaproveitar a composição visual (cartão + título + barra dourada + subtítulo), agora parametrizada pelo `OnboardingItem`.

```dart
class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent({required this.item});

  final OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          const Spacer(),
          Flexible(
            flex: 6,
            child: AspectRatio(
              aspectRatio: 1,
              child: _IllustrationCard(imagePath: item.imagePath),
            ),
          ),
          const SizedBox(height: 40.0),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12.0),
          const _GoldAccent(),          // a mesma barrinha 40×3 da Splash
          const SizedBox(height: 16.0),
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.navy.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
```

O `_OnboardingContent` usa dois widgets auxiliares **novos**. Os dois ficam no mesmo arquivo `onboarding_page.dart`, abaixo do `_OnboardingContent`.

### 4.1 `_IllustrationCard`: widget novo, inspirado no `_buildLogo()`

**Não é o mesmo método.** O `_buildLogo()` é um método privado do `_SplashPageState` e só existe dentro da Splash. O `_IllustrationCard` é um `StatelessWidget` novo que **copia a mesma receita visual** (cartão branco + cantos arredondados + sombra navy + recorte) e a adapta à ilustração.

```dart
class _IllustrationCard extends StatelessWidget {
  const _IllustrationCard({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.12),
            blurRadius: 32.0,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
    );
  }
}
```

**Comparação lado a lado (ótimo trecho para o vídeo):**

| | `_buildLogo()` (Splash) | `_IllustrationCard` (Onboarding) |
|---|---|---|
| Tipo | método privado do `State` | `StatelessWidget` com construtor `const` |
| Imagem | fixa (`logo_celilac.png`) | recebida por parâmetro (`imagePath`) |
| Tamanho | fixo, 160×160 | definido pelo pai (`Flexible` + `AspectRatio`) |
| `BoxFit` | `cover`: o logo preenche o cartão | `contain`: a ilustração **não pode ser cortada** (material, seção 11) |
| `padding` | não tem | 24, para a ilustração respirar dentro do cartão |
| Semântica | padrão | `excludeFromSemantics: true`, porque a imagem é decorativa e o título já comunica |
| Iguais | fundo branco, raio 40, sombra navy 12% / blur 32 / offset (0, 12), `Clip.antiAlias` | ← os mesmos valores |

**Por que um widget, e não outro método `_buildIllustration()`?** O cartão é usado dentro de `_OnboardingContent`, que é outra classe. Além disso, ele recebe um parâmetro e pode ser `const`. Um método privado só serve dentro da classe que o declara.

### 4.2 `_GoldAccent`: a barrinha dourada da Splash

Na Splash, essa barra **não é método nem widget**. É um `Container` escrito direto no `build` ([splash_page.dart:177-184](lib/features/startup/presentation/splash_page.dart#L177-L184)). No onboarding ela vira um widget:

```dart
class _GoldAccent extends StatelessWidget {
  const _GoldAccent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.0,
      height: 3.0,
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(2.0),
      ),
    );
  }
}
```

### 4.3 Opcional: compartilhar de verdade

Com as Etapas 4.1 e 4.2, o **visual** é igual nas duas telas, mas o **código** ainda está duplicado, porque classes com `_` só existem dentro do próprio arquivo. Se quiser mostrar a refatoração no vídeo:

```text
lib/app/widgets/
├── brand_card.dart     ← BrandCard(child: ...)    usado por _buildLogo e pelo onboarding
└── gold_accent.dart    ← GoldAccent()             usado pela Splash e pelo onboarding
```

- `BrandCard` recebe só o `child` (e opcionalmente o `padding`). Assim o `_buildLogo()` passa a ser `BrandCard(child: Image.asset(..., fit: BoxFit.cover))`, e o `_IllustrationCard` passa a ser `BrandCard(padding: ..., child: Image.asset(..., fit: BoxFit.contain))`.
- Recomendação: fazer isso **depois** da Etapa 4 funcionar, como uma refatoração separada ("primeiro funciona, depois organiza").

**Decisões para comentar no vídeo:**
- `Flexible` + `AspectRatio` em vez de um tamanho fixo de 160: a ilustração **encolhe em telas pequenas** e o texto e o botão continuam visíveis (material, seções 41 a 44).
- As três páginas usam **o mesmo widget**, então a consistência está garantida pelo código (material, seções 17 a 19).

✅ **Execute:** as três páginas com ilustração, hierarquia e cores da marca.

---

## Etapa 5: Indicador de progresso (dots)

**Conceito:** na Splash o progresso era uma **barra de tempo**. No onboarding ele é uma **posição em uma sequência**. É a mesma ideia, "mostrar onde estou", com outra representação.

### 5.1 Declarar o widget

No **final** de `onboarding_page.dart`, abaixo do `_GoldAccent`:

```dart
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Etapa ${current + 1} de $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final isActive = index == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: isActive ? 24.0 : 8.0,
            height: 8.0,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.gold
                  : AppColors.navy.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      ),
    );
  }
}
```

### 5.2 Usar o widget no `build` da página

No `build` do `_OnboardingPageState` montado na Etapa 3, insira o indicador **entre o `Expanded(PageView)` e o botão**:

```dart
child: SafeArea(
  child: Column(
    children: [
      Expanded(
        child: PageView.builder(
          controller: _controller,
          onPageChanged: (index) {
            setState(() => _currentPage = index);   // ← já existia
          },
          itemCount: OnboardingPage.items.length,
          itemBuilder: (context, index) {
            return _OnboardingContent(item: OnboardingPage.items[index]);
          },
        ),
      ),
      _PageIndicator(                                // ← NOVO
        count: OnboardingPage.items.length,
        current: _currentPage,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(32.0, 24.0, 32.0, 24.0),
        child: ElevatedButton(/* ... ainda o botão atual ... */),
      ),
    ],
  ),
),
```

**Como funciona (explicar no vídeo):**

```text
usuário desliza (ou toca em Próximo)
↓
PageView chama onPageChanged(index)
↓
setState(() => _currentPage = index)
↓
build() roda de novo → _PageIndicator recebe o novo "current"
↓
AnimatedContainer percebe a mudança de width/color e anima (250 ms)
```

- O indicador fica **fora** do `PageView`, então não desliza junto com o conteúdo e fica parado enquanto as páginas passam (material, seção 29).
- `_PageIndicator` é um `StatelessWidget`: ele **não guarda estado**, só desenha o `current` que recebe. Quem guarda o estado é o `_OnboardingPageState`. É o mesmo padrão "a página decide, o widget renderiza" do `_OnboardingContent` (material, seção 19).
- As cores são **as mesmas da barra de progresso da Splash**: dourado ativo sobre navy translúcido.
- **Acessibilidade:** o `Semantics` faz o leitor de tela anunciar "Etapa 1 de 3". O ponto ativo se diferencia por **largura** além de cor, e isso importa porque o dourado sobre o fundo claro tem pouco contraste.

✅ **Execute:** deslize para frente e para trás e mostre o dot "esticando" nos dois sentidos (swipe e botão sincronizados, material, seção 33).

---

## Etapa 6: Ações (primária e secundária)

**Conceito:** hierarquia de ações (material, seções 27 a 32).

### 6.1 Botão principal: `FilledButton` com a identidade

No `build`, **substitua o `ElevatedButton`** que está dentro do último `Padding` da `Column` por:

```dart
FilledButton(
  onPressed: _nextPage,
  style: FilledButton.styleFrom(
    backgroundColor: AppColors.navy,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(56.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
  ),
  child: AnimatedSwitcher(
    duration: const Duration(milliseconds: 250),
    child: Text(
      _isLastPage ? 'Começar' : 'Próximo',
      key: ValueKey(_isLastPage),
    ),
  ),
)
```

- **O mesmo `AnimatedSwitcher` + `ValueKey`** do texto de status da Splash. Vale mostrar os dois trechos lado a lado no vídeo.
- Declare no `_OnboardingPageState`, logo abaixo de `int _currentPage = 0;`, o getter `bool get _isLastPage => _currentPage == OnboardingPage.items.length - 1;`. Ele substitui a condição repetida e é usado aqui e no "Pular". O `if` de `_nextPage()` também pode passar a usar `!_isLastPage`.
- Ocupa a largura toda (`Size.fromHeight`), com área de toque ≥ 48 dp.

### 6.2 Ação secundária: "Pular" (decisão de produto)

**Recomendação: incluir.** O onboarding do CeliLac apresenta o app, mas não coleta nada obrigatório, e quem reinstala o app não precisa rever as telas.

O `_TopBar` do diagrama da Etapa 3 **não é uma classe separada**. Ele depende do estado da página (`_isLastPage`, `_finishOnboarding`), então fica como um método `_buildTopBar()` dentro do `_OnboardingPageState`, no mesmo estilo de `_buildLogo()` e `_buildProgress()` da Splash:

```dart
Widget _buildTopBar() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
    child: Align(
      alignment: Alignment.centerRight,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isLastPage ? 0 : 1,
        child: TextButton(
          onPressed: _isLastPage ? null : _finishOnboarding,
          style: TextButton.styleFrom(foregroundColor: AppColors.navy),
          child: const Text('Pular'),
        ),
      ),
    ),
  );
}
```

Declare o método dentro do `_OnboardingPageState` (abaixo de `_finishOnboarding()`) e chame-o como **primeiro filho da `Column`**, no lugar do comentário deixado na Etapa 3:

```dart
child: Column(
  children: [
    _buildTopBar(),                 // ← NOVO
    Expanded(child: PageView.builder(/* ... */)),
    _PageIndicator(/* ... */),
    Padding(/* ... FilledButton ... */),
  ],
),
```

> **Regra prática para o vídeo:** se o trecho usa o estado da tela, ele vira um **método `_buildX()`** no `State`, como `_buildLogo`, `_buildProgress` e `_buildTopBar`. Se só recebe dados por parâmetro, ele vira um **widget** (`StatelessWidget`), como `_OnboardingContent`, `_IllustrationCard`, `_GoldAccent` e `_PageIndicator`.

- `TextButton` tem peso visual bem menor que o `FilledButton`, o que deixa a hierarquia clara.
- Na última página o "Pular" some sem mudar o layout (`AnimatedOpacity`, e não um `if`), então nada "pula" na tela.
- "Pular" também marca o onboarding como concluído.

✅ **Execute:** Próximo → Próximo → "Começar" com transição suave. Testar "Pular" a partir da página 1.

---

## Etapa 7: Microinteração de entrada (a coreografia da Splash)

**Conceito:** reaproveitar a animação escalonada com `Interval`, mas **uma única vez**, na entrada. Não se anima a cada página (material, seção 40).

```dart
class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introController;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _actionsFade;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _contentFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(
          parent: _introController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
        ));
    _actionsFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _controller.dispose();   // ← PageController: hoje NÃO é descartado!
    super.dispose();
  }
}
```

Esses campos e métodos **se somam** ao que já existe no `_OnboardingPageState` (`_controller`, `_currentPage`, `_isLastPage`, `_nextPage`, `_finishOnboarding`, `_buildTopBar`, `build`). O `initState` vazio que existe hoje é substituído por este.

Depois, no `build`, envolva cada região da `Column` com a animação correspondente. Assim fica a `Column` **completa e final**:

```dart
child: Column(
  children: [
    FadeTransition(                              // "Pular" aparece junto com as ações
      opacity: _actionsFade,
      child: _buildTopBar(),
    ),
    Expanded(
      child: FadeTransition(                     // conteúdo entra primeiro
        opacity: _contentFade,
        child: SlideTransition(
          position: _contentSlide,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: OnboardingPage.items.length,
            itemBuilder: (context, index) {
              return _OnboardingContent(item: OnboardingPage.items[index]);
            },
          ),
        ),
      ),
    ),
    FadeTransition(                              // ações entram depois
      opacity: _actionsFade,
      child: Column(
        children: [
          _PageIndicator(
            count: OnboardingPage.items.length,
            current: _currentPage,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32.0, 24.0, 32.0, 24.0),
            child: FilledButton(/* ... Etapa 6.1 ... */),
          ),
        ],
      ),
    ),
  ],
),
```

- É a mesma ideia da Splash, onde `FadeTransition(opacity: _logoFade, ...)` e `FadeTransition(opacity: _footerFade, ...)` envolviam as regiões. **As animações não mudam os widgets, só os envolvem.**
- **`SingleTickerProviderStateMixin` × `TickerProviderStateMixin`:** a Splash tem **dois** controllers e usa o segundo. O onboarding tem **um** e usa o primeiro. É uma ótima pergunta para os alunos.
- **Correção importante:** o `PageController` atual nunca recebe `dispose()`. Mostre isso no vídeo como "o mesmo cuidado que tivemos na Splash".
- O deslocamento é pequeno (0.05 contra 0.3 na Splash), porque aqui o conteúdo é maior e o movimento deve ser discreto.

✅ **Execute:** a Splash termina, o fade de rota acontece, o conteúdo "assenta" e depois as ações aparecem. Continuidade.

---

## Etapa 8: Conclusão robusta e transição para a Home

**Conceito:** persistir → checar `mounted` → navegar (material, seções 35 e 36), com a mesma transição da Splash.

```dart
bool _isFinishing = false;

Future<void> _finishOnboarding() async {
  if (_isFinishing) return;          // evita toque duplo
  _isFinishing = true;

  await OnboardingStorage().markAsCompleted();
  if (!mounted) return;

  Navigator.of(context).pushReplacement(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, _, _) => const HomePage(),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}
```

- **Sem loading intermediário.** A persistência é instantânea (material, seção 37).
- O `PageRouteBuilder` com fade agora aparece **três vezes** (Splash → Home, Splash → Onboarding, Onboarding → Home). É um bom gancho para extrair `fadeRoute(Widget page)` em `lib/app/routes/fade_route.dart`. Faça ao vivo como refatoração final, porque demonstra DRY com motivo concreto.

✅ **Execute:** "Começar" → Home com fade. Feche e reabra o app: Splash → **Home direto**.

### Mapa final de `onboarding_page.dart` (após as Etapas 3 a 8)

```text
imports (material, AppColors, HomePage, OnboardingStorage, OnboardingItem)

class OnboardingPage extends StatefulWidget
│   └── static const items = [3 × OnboardingItem com imagePath]      ← Etapa 2
│
class _OnboardingPageState ... with SingleTickerProviderStateMixin   ← Etapa 7
│   ├── _controller (PageController)
│   ├── _currentPage
│   ├── _isFinishing                                                 ← Etapa 8
│   ├── _introController + _contentFade/_contentSlide/_actionsFade   ← Etapa 7
│   ├── get _isLastPage                                              ← Etapa 6
│   ├── initState()                                                  ← Etapa 7
│   ├── dispose()           (_introController + _controller)         ← Etapa 7
│   ├── _nextPage()
│   ├── _finishOnboarding() (guarda + fade route)                    ← Etapa 8
│   ├── _buildTopBar()      ("Pular")                                ← Etapa 6
│   └── build()             (gradiente → SafeArea → Column)          ← Etapas 3, 5, 6, 7
│           ├── _buildTopBar()
│           ├── Expanded → PageView → _OnboardingContent
│           ├── _PageIndicator
│           └── FilledButton
│
class _OnboardingContent  extends StatelessWidget                    ← Etapa 4
class _IllustrationCard   extends StatelessWidget                    ← Etapa 4.1
class _GoldAccent         extends StatelessWidget                    ← Etapa 4.2
class _PageIndicator      extends StatelessWidget                    ← Etapa 5
```

---

## Etapa 9 (opcional): `Hero` do logo, Splash → Onboarding

**Conceito:** continuidade visual entre telas, o "reconhece o app → percebe continuidade" da seção 62.

- Na Splash, envolva `_buildLogo()` em `Hero(tag: 'celilac-logo', ...)`.
- No `_buildTopBar()` do onboarding, troque o `Align` por uma `Row` com `MainAxisAlignment.spaceBetween`. À esquerda vai o logo pequeno (32×32, mesmo cartão com raio 8) com a mesma `tag`, e à direita o "Pular".
- O `Hero` funciona com o `PageRouteBuilder` já usado, e o logo "voa" do centro para o canto.

> Só inclua se o ritmo do vídeo permitir. É vistoso, mas soma mais um movimento (material, seção 40). Se incluir, **mantenha a Etapa 7 discreta**.

---

## Etapa 10: Responsividade e acessibilidade (validação)

Não é código novo. É **teste guiado**, ótimo para o vídeo:

| Teste | Como | O que observar |
|---|---|---|
| Tela pequena | Emulador ~ 4.7" (ex.: Pixel 4a / iPhone SE) | Ilustração encolhe, botão visível, sem overflow listrado |
| Tela grande | Tablet ou emulador grande | Conteúdo não "espalha". Considere `ConstrainedBox(maxWidth: 480)`, como o `maxWidth: 280` da barra da Splash |
| Texto grande | Configurações → tamanho da fonte no máximo | Título quebra bem, nada sobrepõe |
| Leitor de tela | TalkBack / VoiceOver | Ordem: título → descrição → "Etapa 1 de 3" → "Próximo" |
| Contraste | Navy sobre `#F2F2F2` passa com folga. **Nunca use dourado em texto** (contraste ≈ 2:1) | — |

Nas ilustrações, use `Image.asset(..., excludeFromSemantics: true)`. Elas são decorativas, e o título já transmite a mensagem.

---

## Etapa 11: Limpeza final

- [ ] Remover o código comentado da Splash.
- [ ] Remover `flutter_spinkit` do `pubspec.yaml` se continuar sem uso.
- [ ] Remover o `initState` vazio que existe hoje no onboarding (se a Etapa 7 não for aplicada).
- [ ] Remover o `reset()` de desenvolvimento (Etapa 0) ou deixá-lo só em modo debug (`kDebugMode`).
- [ ] `flutter analyze` sem warnings.

---

## Prompts para gerar as ilustrações

### Especificação técnica

- **Formato:** PNG com **fundo transparente** (ou branco puro, já que ficam dentro do cartão branco), **1024×1024**, quadrado.
- **Peso:** otimizar para < 200 KB cada (ex.: TinyPNG / `pngquant`).
- **Consistência:** gere as três **na mesma sessão**. Os prompts já compartilham o mesmo bloco de estilo.
- **Evitar:** texto dentro da imagem, logos de marcas reais, pão ou trigo "comuns" em destaque (em um app para celíacos, isso comunica o oposto), símbolos de proibição.

> Cada prompt abaixo é **completo**: copie o bloco inteiro e cole na ferramenta (ChatGPT/DALL·E, Midjourney, Gemini/Imagen, Firefly etc.). O estilo é o mesmo nos três, então as imagens saem consistentes entre si.
>
> Em ferramentas que não geram transparência, peça fundo **branco puro (#FFFFFF)**. A imagem fica dentro de um cartão branco, então o resultado visual é o mesmo.

### Imagem 1: Descoberta, salvar como `assets/images/onboarding/discovery.png`

Página: *"Encontre opções adequadas a você"*

```text
Flat vector illustration for a mobile app onboarding screen, minimal and friendly,
soft rounded shapes, consistent line weight.
Strict color palette: deep navy blue (#263D4F), warm golden yellow (#D9A53A),
light warm gray (#F2F2F2) and white only.

Scene: a large magnifying glass hovering over a small, simplified city scene
with a cozy café storefront and a map location pin, next to two or three
simple packaged food items marked with a small golden check-mark badge.
A subtle, elegant golden wheat-leaf branch appears as a decorative accent
in one corner, echoing the brand logo.

Meaning: discovering places and products that are safe and suitable for
people with dietary restrictions. Optimistic and welcoming mood.

Composition: subject centered, generous empty space around it,
transparent background (or pure white #FFFFFF), square 1:1, 1024x1024.
Do not include: any text, letters, numbers, logos, real brands, bread,
regular wheat products, prohibition signs, photorealism, gradients,
drop shadows on the background.
```

### Imagem 2: Informação, salvar como `assets/images/onboarding/information.png`

Página: *"Entenda antes de escolher"*

```text
Flat vector illustration for a mobile app onboarding screen, minimal and friendly,
soft rounded shapes, consistent line weight.
Strict color palette: deep navy blue (#263D4F), warm golden yellow (#D9A53A),
light warm gray (#F2F2F2) and white only.

Scene: a simplified food package turned to show its nutrition label area
(represented only by abstract horizontal lines, nothing readable), next to
a clipboard with a short checklist of three items, each with a golden
check mark. A small magnifier or an information "i" circle rests near the label.
A subtle, elegant golden wheat-leaf branch appears as a decorative accent
in one corner, echoing the brand logo.

Meaning: understanding ingredients and reading food information before
choosing. Calm, trustworthy and informative mood.

Composition: subject centered, generous empty space around it,
transparent background (or pure white #FFFFFF), square 1:1, 1024x1024.
Do not include: any readable text, letters, numbers, logos, real brands,
bread, regular wheat products, prohibition signs, photorealism, gradients,
drop shadows on the background.
```

### Imagem 3: Personalização, salvar como `assets/images/onboarding/profile.png`

Página: *"Uma experiência feita para você"*

```text
Flat vector illustration for a mobile app onboarding screen, minimal and friendly,
soft rounded shapes, consistent line weight.
Strict color palette: deep navy blue (#263D4F), warm golden yellow (#D9A53A),
light warm gray (#F2F2F2) and white only.

Scene: a friendly abstract user profile card with a round avatar silhouette,
surrounded by three preference toggle switches (some on in golden yellow,
one off in gray) and a few small rounded tag chips made of abstract shapes.
A small golden heart and two subtle sparkles float near the card.
A subtle, elegant golden wheat-leaf branch appears as a decorative accent
in one corner, echoing the brand logo.

Meaning: a personalized experience tailored to each person's dietary needs.
Warm, personal and caring mood.

Composition: subject centered, generous empty space around it,
transparent background (or pure white #FFFFFF), square 1:1, 1024x1024.
Do not include: any text, letters, numbers, logos, real brands, bread,
regular wheat products, prohibition signs, photorealism, gradients,
drop shadows on the background.
```

### Se as imagens saírem inconsistentes entre si

Depois de aprovar a primeira imagem, gere as outras duas **na mesma conversa** e acrescente ao prompt:

```text
Use exactly the same illustration style, line weight, color palette and level
of detail as the previous image, so the three images look like one series.
```

No Midjourney, use a primeira imagem como referência de estilo com `--sref <url-da-imagem-1>`.

### Variação opcional: modo escuro

Se o app ganhar tema escuro depois (o `flutter_native_splash.yaml` já prevê `color_dark: #0B384B`), gere as versões `_dark` (ex.: `discovery_dark.png`) acrescentando a cada prompt: *"Designed to be displayed over a dark navy (#0B384B) screen: use white and golden yellow as the main colors, transparent background."*

---

## Roteiro sugerido para o vídeo

| Bloco | Etapas | Mensagem central | Duração aprox. |
|---|---|---|---|
| 1. Antes | 0 | "Funciona, mas não comunica" (mostrar o onboarding atual) | 2 min |
| 2. Identidade | 1 | "Identidade não pertence a uma tela" | 3 min |
| 3. Conteúdo | 2 | Narrativa, assets e prompts das imagens | 5 min |
| 4. Estrutura | 3–4 | Só o conteúdo desliza. O visual é reaproveitado da Splash | 8 min |
| 5. Progresso | 5 | Da barra de tempo aos dots de posição | 4 min |
| 6. Ações | 6 | Hierarquia primária/secundária + `AnimatedSwitcher` | 5 min |
| 7. Movimento | 7 (+9) | A coreografia da Splash, agora discreta | 5 min |
| 8. Conclusão | 8 | Persistir → `mounted` → navegar + refatoração `fadeRoute` | 4 min |
| 9. Validação | 10–11 | Telas pequenas, fonte grande, segunda execução | 4 min |

---

## Checklist final (material, seção 61)

- [ ] Três etapas com narrativa Descoberta → Informação → Personalização
- [ ] Uma ideia por página, títulos curtos, descrições que complementam
- [ ] Ilustrações coerentes com a mensagem e com a paleta da marca
- [ ] Mesma estrutura visual nas três páginas (`_OnboardingContent`)
- [ ] Mesmo fundo, cores e tipografia da Splash (`AppColors`)
- [ ] Indicador de progresso sincronizado com swipe e botão
- [ ] `FilledButton` primário fixo. "Pular" como `TextButton` secundário
- [ ] "Próximo" → "Começar" na última página
- [ ] Animação de entrada única e discreta
- [ ] `PageController` e `AnimationController` descartados
- [ ] Proteção contra toque duplo na conclusão
- [ ] Persistência antes da navegação. O onboarding não reaparece
- [ ] Layout validado em tela pequena, tela grande e fonte ampliada
- [ ] `flutter analyze` limpo
