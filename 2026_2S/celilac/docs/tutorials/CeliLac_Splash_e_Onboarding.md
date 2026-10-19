# CeliLac: Splash e Onboarding Profissionais
## Identidade visual, animação, navegação e persistência, passo a passo

---

# Como usar este material

Este material mostra, **na ordem em que foi construído**, tudo o que foi feito no CeliLac para transformar uma inicialização "funcional" em uma primeira experiência profissional:

```text
Ícone do app
↓
Splash nativa (sistema operacional)
↓
Splash Flutter (animada, com progresso)
↓
Onboarding (3 páginas, indicador, ações)
↓
Home
```

Cada parte traz:

- 📘 **Conceito**: a ideia por trás do código, que vale para qualquer projeto.
- 💻 **Código**: o que foi implementado no CeliLac.
- ⚠️ **Atenção**: armadilhas comuns.
- 🧩 **No seu projeto**: o que adaptar para o seu app.
- ▶️ **Execute**: o momento de rodar o app e verificar o resultado.

> O objetivo não é copiar o CeliLac. O objetivo é **entender cada decisão** para aplicá-la no seu projeto, com a sua marca, os seus textos e as suas imagens.

---

# Parte 0: Visão geral

## 0.1 O fluxo completo de inicialização

```text
[Toque no ícone]
      │
      ▼
Splash NATIVA ──────── desenhada pelo Android/iOS enquanto o Flutter carrega
      │                (cor de fundo + logo, sem animação, sem código Dart)
      ▼
SplashPage (Flutter) ─ logo animado, nome, slogan, barra de progresso
      │
      ├── onboarding já concluído? ── sim ──► HomePage
      │
      └── não ──► OnboardingPage ── 3 páginas ── "Começar" ──► HomePage
                                                    │
                                              salva "concluído"
```

## 0.2 Estrutura de pastas

```text
lib/
├── main.dart
├── app/
│   ├── celilac_app.dart                 ← MaterialApp
│   ├── theme/
│   │   └── app_colors.dart              ← cores da marca
│   └── common/
│       └── widgets/
│           ├── gold_accent.dart         ← barrinha dourada
│           └── image_card.dart          ← cartão com imagem (IllustrationCard)
└── features/
    ├── startup/
    │   └── presentation/
    │       └── splash_page.dart
    ├── onboarding/
    │   ├── data/
    │   │   └── onboarding_storage.dart  ← persistência
    │   ├── domain/
    │   │   └── onboarding_item.dart     ← modelo
    │   └── presentation/
    │       └── onboarding_page.dart
    └── home/
        └── presentation/
            └── pages/
                └── home_page.dart

assets/
└── images/
    ├── app_icons/                       ← ícones e artes da splash nativa
    ├── brand/
    │   └── logo_celilac.png
    └── onboarding/
        ├── discovery.png
        ├── information.png
        └── profile.png
```

### 📘 Conceito: organização por *feature*

O código é agrupado **pelo assunto** (startup, onboarding, home), e não pelo tipo de arquivo (todas as telas juntas, todos os modelos juntos). Dentro de cada feature há três camadas:

| Camada | Responsabilidade | Exemplo |
|---|---|---|
| `presentation` | Telas e widgets: o que o usuário vê | `onboarding_page.dart` |
| `domain` | Modelos e regras, **sem depender de Flutter** | `onboarding_item.dart` |
| `data` | Onde e como os dados são guardados | `onboarding_storage.dart` |

O que é **compartilhado entre features** (cores, widgets reutilizáveis) fica em `lib/app/`.

🧩 **No seu projeto:** crie `lib/app/theme/` e `lib/app/common/widgets/` desde o início. Toda vez que um trecho visual aparecer em duas telas, ele é candidato a ir para lá.

---

# Parte 1: Identidade visual

## 1.1 📘 Conceito: *design tokens*

Uma identidade visual é formada por decisões que se repetem: cores, espaçamentos, raios de borda, tipografia. Quando essas decisões aparecem como números "soltos" em cada tela (`Color(0xFF263D4F)` aqui, `Color(0xFF263D4F)` ali), três problemas surgem:

1. mudar a cor da marca exige procurar em todos os arquivos;
2. um erro de digitação cria uma cor "quase igual";
3. o código não comunica **intenção**: `Color(0xFF263D4F)` não diz nada, `AppColors.navy` diz.

Esses valores nomeados são chamados de **design tokens**.

## 1.2 💻 `AppColors`

`lib/app/theme/app_colors.dart`

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color navy = Color(0xFF263D4F);
  static const Color gold = Color(0xFFD9A53A);
  static const Color background = Color(0xFFF2F2F2);
}
```

### 📘 Conceitos no código

- **`abstract final class`** (Dart 3): `abstract` impede criar instâncias (`AppColors()` não compila) e `final` impede que outra classe a estenda ou implemente. É o jeito idiomático de declarar uma classe que é só um **agrupamento de constantes**.
- **`static const`**: o valor pertence à classe, não a um objeto, e é conhecido em tempo de compilação. Por isso pode ser usado dentro de widgets `const`.
- **`Color(0xFF263D4F)`**: o formato é `0xAARRGGBB`. `FF` é a opacidade total, e o resto é o hexadecimal da cor (`#263D4F`).

### 📘 De onde vieram as cores?

Do **logo**. Navy e dourado são as duas cores do logotipo do CeliLac. O cinza-claro `#F2F2F2` é o fundo usado na splash nativa. A identidade do app nasce da marca, não de uma escolha aleatória na tela.

🧩 **No seu projeto:** extraia 2 ou 3 cores do seu logo (um conta-gotas em qualquer editor de imagem resolve) e defina uma cor de fundo neutra. Comece com poucas cores.

## 1.3 Transparência a partir de uma cor da marca

No projeto, os tons secundários **não são novas cores**, mas o navy com transparência:

```dart
AppColors.navy.withValues(alpha: 0.7)   // descrição
AppColors.navy.withValues(alpha: 0.6)   // textos de status
AppColors.navy.withValues(alpha: 0.4)   // versão do app
AppColors.navy.withValues(alpha: 0.15)  // dots inativos
AppColors.navy.withValues(alpha: 0.08)  // trilho da barra de progresso
```

📘 Isso cria uma **escala de hierarquia** com uma única cor: quanto menos importante o elemento, mais transparente. O resultado é sempre harmônico, porque tudo deriva da mesma cor.

> `withValues(alpha:)` é a API atual. O antigo `withOpacity()` está *deprecated*.

## 1.4 Organização dos assets

### 📘 Conceito

*Assets* são arquivos empacotados junto com o app (imagens, fontes, JSON). Organizá-los por finalidade facilita encontrar, substituir e remover arquivos.

```text
assets/images/
├── app_icons/    ← usados pelas ferramentas de geração (ícone, splash nativa)
├── brand/        ← identidade: logo
└── onboarding/   ← ilustrações das páginas de onboarding
```

### 💻 `pubspec.yaml`

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/brand/logo_celilac.png
    - assets/images/onboarding/
```

- Um **arquivo** declara só aquele arquivo.
- Uma **pasta** (terminada em `/`) declara todos os arquivos **diretamente** dentro dela. **Subpastas não são incluídas** e precisam de uma linha própria.
- `app_icons/` não é declarada porque essas imagens são usadas pelas ferramentas de geração, **não pelo código Dart**. Declarar a pasta só aumentaria o tamanho do app.

### ⚠️ Atenção

- Depois de alterar o `pubspec.yaml`, faça um **Hot Restart** (ou pare e rode de novo). O Hot Reload não carrega assets novos.
- Um asset não declarado gera, em tempo de execução, o erro `Unable to load asset: "assets/..."`.
- **Mover assets de pasta quebra as configurações que apontam para eles.** Se você mover os arquivos, atualize também o `flutter_native_splash.yaml` e o `flutter_launcher_icons.yaml` (Parte 2).
- Otimize o tamanho: uma ilustração de onboarding não precisa ter 850 KB. Ferramentas como TinyPNG ou `pngquant` costumam reduzir 60–80% sem perda visível.

---

# Parte 2: Ícone e splash nativa

## 2.1 📘 Conceito: splash nativa × splash Flutter

Quando o usuário toca no ícone, o Flutter **ainda não está rodando**. Durante esse intervalo, que pode passar de um segundo em aparelhos mais lentos, quem desenha a tela é o **sistema operacional**.

| | Splash nativa | Splash Flutter (`SplashPage`) |
|---|---|---|
| Quem desenha | Android / iOS | Flutter |
| Quando | antes do primeiro frame Flutter | depois do primeiro frame |
| O que pode ter | cor de fundo + imagem estática | qualquer widget, animação, lógica |
| Como é criada | gerada por ferramenta (arquivos nativos) | código Dart |

Se as duas forem diferentes (por exemplo, a nativa branca e a Flutter cinza), o usuário vê um **"salto"** na troca. O objetivo é **continuidade**: a nativa termina com o mesmo fundo e o mesmo logo com que a Flutter começa.

## 2.2 💻 `flutter_native_splash`

`pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_native_splash: ^2.4.8
```

`flutter_native_splash.yaml` (na raiz do projeto):

```yaml
flutter_native_splash:
  color: "#F2F2F2"
  color_dark: "#0B384B"
  image: assets/images/brand/logo_celilac.png
  android: true
  ios: true
  android_12:
    color: "#F2F2F2"
    color_dark: "#0B384B"
    image: assets/images/brand/logo_celilac.png
```

Gerar os arquivos nativos:

```bash
dart run flutter_native_splash:create
```

### 📘 Conceitos

- **`dev_dependencies`**: ferramentas usadas durante o desenvolvimento. Não vão para dentro do app.
- **`color` / `color_dark`**: fundo no modo claro e no escuro.
- **`android_12`**: a partir do Android 12 o sistema **impõe** um formato de splash (ícone centralizado dentro de um círculo). Por isso ele tem configuração própria.
- A cor `#F2F2F2` é **a mesma** de `AppColors.background`. É isso que garante a continuidade.

### ⚠️ Atenção

- O comando precisa ser executado **de novo** sempre que o YAML ou a imagem mudarem.
- **Modo escuro:** a splash nativa tem `color_dark`, mas a `SplashPage` Flutter usa sempre o fundo claro. Em um aparelho no modo escuro, o usuário vê o azul-escuro nativo e depois um fundo claro. Para corrigir, ou a `SplashPage` também passa a ter tema escuro, ou você remove o `color_dark` e mantém tudo claro.
- No Android 12+, a imagem é recortada em círculo. Use uma imagem quadrada com o logo **centralizado e com margem** (o logo deve caber em cerca de 2/3 do quadrado).

## 2.3 💻 Ícone do app: `flutter_launcher_icons`

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.4
```

`flutter_launcher_icons.yaml`:

```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true

  image_path: "assets/images/app_icons/app_icon.png"

  adaptive_icon_background: "#FEE2B5"
  adaptive_icon_foreground: "assets/images/app_icons/adaptative_app_icon.png"
  adaptive_icon_monochrome: "assets/images/app_icons/monochrome_app_icon.png"

  min_sdk_android: 21

  remove_alpha_ios: true
```

```bash
dart run flutter_launcher_icons
```

### 📘 Conceitos

- **Ícone adaptativo (Android 8+):** o ícone tem duas camadas, `background` (cor ou imagem) e `foreground` (o símbolo). Cada fabricante recorta o conjunto em um formato diferente (círculo, quadrado arredondado, gota). Mantenha o símbolo na **zona segura central (≈ 66%)**.
- **`monochrome`:** versão de uma cor só, usada pelos "ícones temáticos" do Android 13+.
- **`remove_alpha_ios`:** a App Store não aceita ícones com transparência.

▶️ **Execute:** desinstale o app, rode de novo e observe o ícone e a splash nativa.

🧩 **No seu projeto:** comece pelo ícone e pela splash nativa, porque são a **primeira impressão** do app. Use o mesmo fundo em `flutter_native_splash.yaml` e na sua `SplashPage`.

---

# Parte 3: Widgets compartilhados

Antes de construir as telas, criamos duas peças visuais usadas **tanto na Splash quanto no Onboarding**.

## 3.1 📘 Conceito: composição e reutilização

Em Flutter, **tudo é widget**, e telas complexas são montadas **compondo** widgets pequenos. Quando o mesmo trecho visual aparece em mais de um lugar, extraí-lo para um widget próprio traz:

- **consistência**: é impossível as duas telas ficarem diferentes por acidente;
- **manutenção**: uma alteração vale para todo o app;
- **legibilidade**: `GoldAccent()` comunica mais do que 8 linhas de `Container`.

## 3.2 💻 `GoldAccent`: a assinatura visual

`lib/app/common/widgets/gold_accent.dart`

```dart
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class GoldAccent extends StatelessWidget {
  final double width;

  const GoldAccent({super.key, this.width = 40.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 3.0,
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(2.0),
      ),
    );
  }
}
```

### 📘 Conceitos

- **`StatelessWidget`**: um widget que só depende dos parâmetros que recebe e não guarda estado.
- **Parâmetro com valor padrão** (`this.width = 40.0`): quem não informa a largura recebe 40, e quem precisa de outra informa. Na Splash usamos `GoldAccent(width: 80.0)` sob o nome do app, e no onboarding `GoldAccent()` sob cada título.
- **Construtor `const`**: permite escrever `const GoldAccent()`. O Flutter reaproveita a mesma instância e evita reconstruções desnecessárias.
- **`super.key`**: repassa a `key` para a classe mãe. Todo widget público deve aceitá-la.
- **`BoxDecoration`**: define aparência (cor, borda, sombra, gradiente) de um `Container`. Quando há `decoration`, a cor vai **dentro** dela, e não no `color` do `Container`.

📘 Um elemento pequeno e repetido como esse funciona como **assinatura da marca**: o usuário passa a associá-lo ao produto.

## 3.3 💻 `IllustrationCard`: imagem em um cartão

`lib/app/common/widgets/image_card.dart`

```dart
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class IllustrationCard extends StatelessWidget {
  const IllustrationCard({
    super.key,
    required this.imagePath,
    required this.boxShaddowAlpha,
    this.width,
    this.height,
    this.padding,
  });

  final String imagePath;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double boxShaddowAlpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: boxShaddowAlpha),
            blurRadius: 32.0,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Image.asset(imagePath),
    );
  }
}
```

### 📘 Conceitos

- **Parâmetros `required` × opcionais (`?`)**: `imagePath` é obrigatório. `width`, `height` e `padding` podem ser `null`, e um `Container` com `width: null` **se adapta ao espaço que o pai oferece**. Assim o mesmo widget serve para:
  - a Splash, com tamanho fixo (`width: 160, height: 160`);
  - o Onboarding, com o tamanho definido pelo pai (`AspectRatio`, Parte 5).
- **Sombra colorida**: a sombra usa o **navy da marca** com transparência, em vez de preto. Sombras pretas "sujam" fundos claros, e sombras na cor da marca parecem integradas.
  - `blurRadius: 32`: sombra difusa e suave.
  - `offset: (0, 12)`: deslocada para baixo, como se a luz viesse de cima.
- **Transparência da sombra por parâmetro**: a Splash usa `0.12` (logo pequeno, sombra discreta) e o onboarding usa `0.22` (cartão grande, precisa de mais profundidade).
- **`Image.asset`**: carrega uma imagem declarada no `pubspec.yaml`.

### 📘 `BoxFit`: como a imagem ocupa o espaço

| `BoxFit` | Comportamento | Quando usar |
|---|---|---|
| `contain` | cabe inteira, mantém proporção, pode sobrar espaço | ilustrações (nada pode ser cortado) |
| `cover` | preenche tudo, mantém proporção, **pode cortar** | fotos de fundo |
| `fill` | preenche tudo, **distorce** | quase nunca |
| `scaleDown` | como `contain`, mas nunca aumenta a imagem | **padrão** quando `fit` não é informado |

No `IllustrationCard` o `fit` não foi informado, então vale o `scaleDown`. Como as imagens usadas são maiores que o cartão, o efeito é o mesmo de `contain`. Declarar `fit: BoxFit.contain` deixaria a **intenção explícita** (veja a Parte 6).

🧩 **No seu projeto:** se o seu logo tiver fundo transparente, o cartão branco cria uma "moldura" elegante. Se já tiver fundo próprio, considere acrescentar `clipBehavior: Clip.antiAlias` ao `Container` para recortar a imagem nos cantos arredondados.

---

# Parte 4: `SplashPage`

Vamos construir a Splash em cinco passos: layout estático → animação de entrada → progresso → navegação → limpeza.

## 4.1 📘 Conceito: `StatefulWidget` e ciclo de vida

A Splash precisa de **estado** (controladores de animação que mudam ao longo do tempo) e de **ciclo de vida** (começar ao abrir, liberar recursos ao sair). Por isso é um `StatefulWidget`:

```dart
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  // ...
}
```

O ciclo de vida que usaremos:

```text
createState()
↓
initState()   ← roda UMA vez: criar controllers, iniciar animações
↓
build()       ← roda sempre que algo precisa ser redesenhado
↓
...
↓
dispose()     ← roda UMA vez ao sair: liberar controllers
```

- **`mounted`**: `true` enquanto o `State` está na árvore de widgets. Depois de `dispose()`, passa a ser `false`.

## 4.2 Passo 1: Layout estático

### 💻 `build`

```dart
@override
Widget build(BuildContext context) {
  final textTheme = Theme.of(context).textTheme;

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const Spacer(flex: 3),
              IllustrationCard(
                imagePath: 'assets/images/brand/logo_celilac.png',
                boxShaddowAlpha: 0.12,
                width: 160.0,
                height: 160.0,
              ),
              const SizedBox(height: 32.0),
              Text(
                'CeliLac',
                style: textTheme.displaySmall?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8.0),
              const GoldAccent(width: 80.0),
              const SizedBox(height: 12.0),
              Text(
                'Alimentação sem glúten e sem lactose',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.navy.withValues(alpha: 0.7),
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(flex: 3),
              // barra de progresso: Passo 3
              const SizedBox(height: 40.0),
              Text(
                'versão 1.0.0',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.navy.withValues(alpha: 0.4),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    ),
  );
}
```

### 📘 Conceitos

**Gradiente de fundo.** `LinearGradient` do branco (topo) ao `#F2F2F2` (base). A diferença é sutil, mas dá **profundidade** e evita o aspecto "chapado". O `Container` com `width/height: double.infinity` garante que o gradiente ocupe a tela toda. O `backgroundColor` do `Scaffold` com a mesma cor é uma "rede de segurança" para o primeiro frame.

**`SafeArea`.** Adiciona o espaçamento necessário para que o conteúdo não fique sob a barra de status, o *notch* ou a barra de gestos. O gradiente fica **fora** do `SafeArea` (preenche a tela inteira) e o conteúdo fica **dentro** (protegido).

**`Spacer(flex:)`.** Um `Spacer` ocupa o espaço livre de uma `Column`/`Row`. Com dois `Spacer(flex: 3)`, o espaço livre é dividido igualmente acima e abaixo do bloco central, e o logo fica **centralizado opticamente** em qualquer altura de tela, sem nenhum número mágico.

```text
┌──────────────────┐
│  Spacer(flex: 3) │ ← espaço livre ÷ 2
│     [ LOGO ]     │
│     CeliLac      │
│     ───────      │
│  slogan          │
│  Spacer(flex: 3) │ ← espaço livre ÷ 2
│  ▬▬▬▬▬▬ 42%      │
│  versão 1.0.0    │
└──────────────────┘
```

**Tipografia com `textTheme` + `copyWith`.** Em vez de `TextStyle(fontSize: 36)`, usamos os estilos do tema do Material 3 (`displaySmall`, `bodyLarge`, `labelSmall`) e alteramos apenas o necessário com `copyWith`. Assim:

- a **escala** de tamanhos é coerente em todo o app;
- os textos respeitam o **tamanho de fonte** configurado pelo usuário no sistema.

| Estilo | Uso | Papel na hierarquia |
|---|---|---|
| `displaySmall` | nome do app | o mais importante |
| `bodyLarge` | slogan | complementa |
| `bodySmall` | status da carga | informativo |
| `labelSmall` | versão | quase invisível |

**`letterSpacing`.** Espaçamento maior no nome (1.2) transmite elegância. No rodapé (1.0), melhora a leitura de textos pequenos.

**`?.` (null-aware).** `textTheme.displaySmall` pode ser `null` no tipo. O `?.copyWith` só é chamado se não for.

▶️ **Execute:** a Splash aparece estática e centralizada. Teste em uma tela pequena e em uma grande.

## 4.3 Passo 2: Animação de entrada escalonada

### 📘 Conceito: animações explícitas

O Flutter tem dois tipos de animação:

| Implícitas | Explícitas |
|---|---|
| `AnimatedContainer`, `AnimatedOpacity`, `AnimatedSwitcher`… | `AnimationController` + `*Transition` |
| Animam **sozinhas** quando um valor muda | **Você controla** início, duração, sequência |
| Simples, sem controller | Coreografias, sequências, repetição |

Para uma entrada **coreografada** (primeiro o logo, depois o texto, depois o rodapé), precisamos de animação explícita.

### 📘 As peças

```text
AnimationController   → um "relógio" que vai de 0.0 a 1.0 na duração definida
       │
CurvedAnimation       → aplica uma curva (aceleração) e/ou um Interval (trecho)
       │
Tween                 → converte 0.0–1.0 no valor desejado (ex.: escala 0.85–1.0)
       │
*Transition           → widget que redesenha o filho a cada frame com o valor atual
```

- **`vsync` / Ticker**: o controller precisa de um "tique" a cada frame da tela. O `TickerProviderStateMixin` fornece esses tiques, que são **pausados automaticamente** quando a tela não está visível (economia de bateria).
- **`TickerProviderStateMixin` × `SingleTickerProviderStateMixin`**: o *Single* só permite **um** controller. A Splash tem **dois** (entrada e progresso), então usa o plural. O Onboarding tem um só e usa o *Single*.

### 💻 Campos e `initState`

```dart
late final AnimationController _introController;
late final AnimationController _progressController;

late final Animation<double> _logoFade;
late final Animation<double> _logoScale;
late final Animation<double> _textFade;
late final Animation<Offset> _textSlide;
late final Animation<double> _footerFade;

@override
void initState() {
  super.initState();

  _introController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  _logoFade = CurvedAnimation(
    parent: _introController,
    curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
  );

  _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
    CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ),
  );

  _textFade = CurvedAnimation(
    parent: _introController,
    curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
  );

  _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
      .animate(
        CurvedAnimation(
          parent: _introController,
          curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic),
        ),
      );

  _footerFade = CurvedAnimation(
    parent: _introController,
    curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
  );

  _progressController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  _initialize();
}
```

### 📘 `late final`

Os campos só podem ser criados dentro de `initState` (precisam do `this` para o `vsync`). `late` promete ao Dart que eles serão inicializados antes do uso, e `final` garante que serão atribuídos **uma única vez**.

### 📘 `Interval`: um controller, várias animações

Um único controller de 1400 ms coordena cinco animações. Cada `Interval` define **em que trecho** do tempo total a animação acontece:

```text
tempo →   0.0        0.35   0.5   0.6        0.8        1.0
          │──────────────────│                               logo: fade (0.0–0.5)
          │─────────────────────────│                        logo: escala (0.0–0.6)
                      │──────────────────────────│           texto: fade + slide (0.35–0.8)
                                          │──────────────────│ rodapé: fade (0.6–1.0)
```

As animações **se sobrepõem** parcialmente. Isso gera o efeito *staggered* (escalonado): cada elemento "puxa" o seguinte, em vez de todos aparecerem juntos ou um estritamente depois do outro.

### 📘 Curvas

| Curva | Efeito | Usada em |
|---|---|---|
| `easeOut` | começa rápido, desacelera no fim | fades |
| `easeOutCubic` | desaceleração mais marcada | deslizar do texto |
| `easeOutBack` | passa um pouco do final e volta | escala do logo (leve "quique") |

Movimentos do mundo real não têm velocidade constante. Curvas `easeOut` passam a sensação de algo que **chega e se acomoda**.

### 📘 `Offset` no `SlideTransition`

`Offset(0, 0.3)` significa **30% da altura do próprio widget** para baixo, e não 0.3 pixel. O texto começa um pouco abaixo e sobe até a posição final (`Offset.zero`).

### 💻 Aplicando no `build`

Envolva cada região com as transições:

```dart
FadeTransition(
  opacity: _logoFade,
  child: ScaleTransition(
    scale: _logoScale,
    child: IllustrationCard(/* ... */),
  ),
),
const SizedBox(height: 32.0),
FadeTransition(
  opacity: _textFade,
  child: SlideTransition(
    position: _textSlide,
    child: Column(
      children: [
        Text('CeliLac', /* ... */),
        const SizedBox(height: 8.0),
        const GoldAccent(width: 80.0),
        const SizedBox(height: 12.0),
        Text('Alimentação sem glúten e sem lactose', /* ... */),
      ],
    ),
  ),
),
// ...
FadeTransition(
  opacity: _footerFade,
  child: Text('versão 1.0.0', /* ... */),
),
```

📘 **As transições não mudam os widgets, só os envolvem.** O layout do Passo 1 continua o mesmo. Os `*Transition` redesenham **apenas o filho** a cada frame, sem chamar o `build` da tela inteira (mais eficiente que `setState` a cada frame).

▶️ **Execute:** logo surge com um leve "quique", o texto sobe e o rodapé aparece por último.

## 4.4 Passo 3: Barra de progresso

### 📘 Conceito: feedback de espera

O usuário tolera melhor uma espera quando **vê que algo está acontecendo**. A Splash mostra três formas de feedback ao mesmo tempo:

1. **barra** (quanto já foi);
2. **percentual** (número exato);
3. **mensagem** (o que está acontecendo).

### 💻 `_statusFor` e `_buildProgress`

```dart
String _statusFor(double progress) {
  if (progress < 0.35) {
    return 'Preparando sua experiência';
  }
  if (progress < 0.75) {
    return 'Carregando suas preferências';
  }
  return 'Quase pronto';
}

Widget _buildProgress(TextTheme textTheme) {
  return AnimatedBuilder(
    animation: _progressController,
    builder: (context, _) {
      final progress = _progressController.value;

      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _statusFor(progress),
                    key: ValueKey(_statusFor(progress)),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.navy.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.navy.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4.0,
                color: AppColors.gold,
                backgroundColor: AppColors.navy.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      );
    },
  );
}
```

E no `build`, no lugar do comentário do Passo 1:

```dart
FadeTransition(
  opacity: _footerFade,
  child: _buildProgress(textTheme),
),
```

### 📘 Conceitos

**`AnimatedBuilder`.** Reconstrói **apenas** o trecho dentro do `builder` sempre que o controller muda. É a forma de usar o **valor numérico** de uma animação (aqui, para calcular o percentual e escolher a mensagem), quando nenhum `*Transition` pronto resolve.

**`AnimatedSwitcher` + `ValueKey`.** O `AnimatedSwitcher` faz um *crossfade* quando o filho **muda de identidade**. Dois `Text` são o "mesmo" widget para o Flutter, a menos que tenham `key`s diferentes. Com `ValueKey(_statusFor(progress))`:

```text
progress 0.10 → key "Preparando…"   ┐ mesma key: nada acontece
progress 0.20 → key "Preparando…"   ┘
progress 0.36 → key "Carregando…"  ← key mudou: crossfade de 300 ms
```

Sem a `key`, o texto trocaria de forma seca. Com uma `key` que muda a cada frame, ele "piscaria" o tempo todo. **A `key` deve mudar exatamente quando o conteúdo muda.**

**`FontFeature.tabularFigures()`.** Por padrão, cada dígito tem largura diferente ("1" é mais estreito que "8"), e um contador `9% → 10% → 11%` faria o texto "tremer". Os algarismos tabulares têm **largura igual**, e o número fica estável.

**`ConstrainedBox(maxWidth: 280)`.** Em tablets, a barra não se estica até as bordas.

**`ClipRRect`.** O `LinearProgressIndicator` é retangular. O `ClipRRect` arredonda suas pontas.

**Cores.** Dourado (a marca) sobre um trilho navy quase transparente: a barra se destaca sem competir com o logo.

**Método `_buildX()` × widget.** `_buildProgress` é um **método** porque depende do estado da tela (`_progressController`, `_statusFor`). Regra prática:

> Se o trecho usa o estado da tela, ele vira um **método `_buildX()`** no `State`. Se só recebe dados por parâmetro, vira um **widget** (`StatelessWidget`).

## 4.5 Passo 4: Sequência de inicialização e navegação

### 💻 `_initialize` e `_goTo`

```dart
Future<void> _initialize() async {
  await _introController.forward();
  if (!mounted) {
    return;
  }

  await _progressController.forward();
  if (!mounted) {
    return;
  }

  _goTo(const OnboardingPage());
}

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

### 📘 Conceitos

**`async`/`await` com animações.** `controller.forward()` devolve um `Future` que completa quando a animação termina. Com `await`, a sequência fica linear e legível: entrada → progresso → navegação.

**Por que `_initialize()` não tem `await` no `initState`?** O `initState` não pode ser `async`. Chamamos `_initialize()` e deixamos o `Future` seguir em paralelo. O `build` acontece normalmente enquanto as animações rodam.

**`if (!mounted) return;` depois de cada `await`.** Durante a espera, o usuário pode fechar a tela. Se isso acontecer, o `State` foi descartado e usar o `context` causaria erro. **Regra: depois de todo `await`, antes de usar `context`, verifique `mounted`.**

**`pushReplacement` × `push`.** `push` empilha a nova tela, e o botão "voltar" retornaria à Splash. `pushReplacement` **substitui**: a Splash sai da pilha e "voltar" fecha o app. Splash e onboarding concluído **nunca** devem ser alcançáveis pelo "voltar".

**`PageRouteBuilder`.** O `MaterialPageRoute` usa a transição padrão da plataforma (deslizar). O `PageRouteBuilder` permite definir a sua. Aqui, um **fade de 500 ms**: a Splash "se dissolve" na próxima tela, reforçando a continuidade.

- `pageBuilder`: qual tela construir;
- `transitionsBuilder`: como animar a entrada. `animation` vai de 0 a 1 durante a transição;
- `(_, _, _)`: *wildcards* do Dart 3.7+, para parâmetros que não usamos.

**Extrair `_goTo`.** Isolar a navegação em um método permite chamá-la com qualquer destino (`HomePage` ou `OnboardingPage`) com a mesma transição.

### ⚠️ A decisão de rota (versão final)

No projeto da aula, a Splash foi configurada para **sempre** abrir o onboarding, para facilitar a demonstração. Em um app real, a Splash precisa **consultar a persistência** (Parte 5) e decidir:

```dart
Future<void> _initialize() async {
  await _introController.forward();
  if (!mounted) return;

  await _progressController.forward();
  if (!mounted) return;

  final completed = await OnboardingStorage().isCompleted();
  if (!mounted) return;

  _goTo(completed ? const HomePage() : const OnboardingPage());
}
```

> Se o código de decisão ficar comentado, o `flutter analyze` vai acusar *imports* sem uso (`home_page.dart`, `onboarding_storage.dart`). Esse aviso é um sinal de que algo ficou pela metade.

### ⚠️ Quanto tempo a splash deve durar?

Somando os dois controllers, a Splash dura **5,4 segundos**, e a barra de progresso é **simulada** (não mede nenhuma carga real). Isso é adequado para **estudar animação**, mas em produção:

- a splash deve durar **o tempo necessário, e não mais**;
- o progresso deve refletir **trabalho real** (ler preferências, autenticar, baixar configuração).

Um padrão comum é esperar pelo que terminar **por último**: a animação mínima ou o trabalho real.

```dart
final results = await Future.wait([
  _introController.forward(),              // duração mínima para a marca aparecer
  OnboardingStorage().isCompleted(),       // trabalho real
]);
final completed = results[1] as bool;
```

📘 Retomando o material de onboarding: *feedback só deve existir quando existe uma espera perceptível.* Uma barra de progresso de 4 segundos para uma leitura que leva 20 ms é uma espera **criada** pelo app.

## 4.6 Passo 5: `dispose`

```dart
@override
void dispose() {
  _introController.dispose();
  _progressController.dispose();
  super.dispose();
}
```

📘 Um `AnimationController` mantém um `Ticker` ativo. Se não for descartado, ele continua existindo depois que a tela saiu, e o Flutter acusa em modo debug: *"AnimationController.dispose() called… Ticker was active"*. **Todo controller criado no `initState` deve ser descartado no `dispose`**, antes do `super.dispose()`.

▶️ **Execute:** a Splash completa, com fade para a próxima tela. Aperte "voltar" no Android: o app deve fechar, e não voltar para a Splash.

🧩 **No seu projeto:**
- troque o logo, o nome e o slogan;
- revise as mensagens de `_statusFor` para que façam sentido no seu domínio;
- ajuste a duração: comece com algo em torno de 1,5 a 2 s no total;
- mantenha **sempre** as verificações de `mounted` e o `dispose`.

---

# Parte 5: Onboarding

## 5.1 📘 Conceito: o que é (e o que não é) um onboarding

O onboarding responde, em poucas telas:

1. **O que é** este aplicativo?
2. **Por que** ele é relevante para mim?
3. **O que esperar** da experiência?

Ele **não é um manual**. Se tentar explicar todos os menus e funções, ninguém lê.

Regras usadas no CeliLac:

- **três páginas**, com uma narrativa: Descoberta → Informação → Personalização;
- **uma ideia por página**: ilustração + título curto + descrição que **complementa** (sem repetir) o título;
- **mesma estrutura visual** nas três páginas: só o conteúdo muda;
- **progresso visível** (onde estou, quanto falta);
- **ação principal evidente** e sempre no mesmo lugar;
- aparece **uma única vez**.

## 5.2 Passo 1: O modelo (`domain`)

`lib/features/onboarding/domain/onboarding_item.dart`

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

### 📘 Conceitos

- **Modelo imutável**: todos os campos são `final` e o construtor é `const`. Um item de onboarding não muda depois de criado.
- **Sem `import 'package:flutter/...'`**: a versão inicial tinha `IconData icon`, que obrigava o modelo a importar Flutter. Com `imagePath` (uma `String`), a camada de domínio fica **independente da interface**. Esse é o critério da camada `domain`.
- **Ícone × ilustração**: ícones são leves e genéricos. Ilustrações criam **identidade** e comunicam contexto. No onboarding, onde a primeira impressão importa, a ilustração vale o custo.

## 5.3 Passo 2: A persistência (`data`)

`lib/features/onboarding/data/onboarding_storage.dart`

```dart
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStorage {
  OnboardingStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _completedKey = 'onboarding_completed';

  final SharedPreferencesAsync _preferences;

  Future<bool> isCompleted() async {
    return await _preferences.getBool(_completedKey) ?? false;
  }

  Future<void> markAsCompleted() async {
    await _preferences.setBool(_completedKey, true);
  }
}
```

### 📘 Conceitos

- **`shared_preferences`**: armazena pares chave-valor simples (bool, int, String) de forma persistente, usando `SharedPreferences` no Android e `NSUserDefaults` no iOS. Serve para preferências e *flags*. **Não** serve para dados sensíveis nem grandes volumes.
- **`SharedPreferencesAsync`**: a API atual. Cada chamada vai direto ao armazenamento, sem cache em memória, e por isso todos os métodos são `Future`.
- **`?? false`**: na primeira execução a chave não existe e `getBool` devolve `null`. "Não existe" significa "não concluído".
- **Chave como constante privada** (`_completedKey`): evita erro de digitação e mantém o nome da chave como detalhe interno da classe.
- **Injeção pelo construtor** (`{SharedPreferencesAsync? preferences}`): em produção, a classe cria a sua própria instância. Em um teste, é possível passar uma versão falsa. A tela não sabe **como** os dados são guardados, só pergunta `isCompleted()` e pede `markAsCompleted()`.

💡 **Durante o desenvolvimento**, para rever o onboarding, desinstale o app ou limpe os dados dele nas configurações do aparelho. Outra opção é adicionar temporariamente:

```dart
Future<void> reset() => _preferences.remove(_completedKey);
```

## 5.4 Passo 3: O conteúdo e a narrativa

Na `OnboardingPage`, os itens ficam em uma lista `static const`:

```dart
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static const List<OnboardingItem> items = [
    OnboardingItem(
      title: 'Encontre opções adequadas a você',
      description:
          'Descubra produtos e estabelecimentos '
          'considerando suas necessidades alimentares.',
      imagePath: 'assets/images/onboarding/discovery.png',
    ),
    OnboardingItem(
      title: 'Entenda antes de escolher',
      description:
          'Consulte informações alimentares e conheça '
          'melhor as opções disponíveis.',
      imagePath: 'assets/images/onboarding/information.png',
    ),
    OnboardingItem(
      title: 'Uma experiência mais relevante',
      description:
          'Seu perfil alimentar poderá ajudar o CeliLac '
          'a apresentar opções mais adequadas.',
      imagePath: 'assets/images/onboarding/profile.png',
    ),
  ];

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}
```

### 📘 Conceitos

- **`static const`**: a lista é única, pertence à classe e é criada em tempo de compilação. É acessível como `OnboardingPage.items`.
- **Strings adjacentes** (`'Descubra… ' 'considerando…'`): o Dart concatena literais vizinhos automaticamente. Serve para quebrar textos longos no código sem usar `+`.
- **A narrativa em uma frase por página:**

```text
1. Descoberta       → "Encontre opções adequadas a você"
2. Informação       → "Entenda antes de escolher"
3. Personalização   → "Uma experiência mais relevante"
```

Lidas em sequência, as três frases contam uma história. Faça esse teste **antes** de programar.

> ⚠️ No projeto da aula, as três páginas usam temporariamente `discovery.png`. Cada página precisa da **sua** ilustração. Os prompts para gerar `information.png` e `profile.png` estão no Apêndice A.

## 5.5 Passo 4: Estado, `PageView` e navegação entre páginas

### 💻 Estado e métodos

```dart
class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_currentPage < OnboardingPage.items.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }
    await _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    final storage = OnboardingStorage();
    await storage.markAsCompleted();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
    );
  }

  // build (Passos 5 a 9)
}
```

### 💻 O `PageView`

```dart
PageView.builder(
  controller: _pageController,
  onPageChanged: (index) {
    setState(() => _currentPage = index);
  },
  itemCount: OnboardingPage.items.length,
  itemBuilder: (context, index) {
    return _OnboardingContent(item: OnboardingPage.items[index]);
  },
)
```

### 📘 Conceitos

- **`PageView`**: uma lista de páginas com deslize horizontal e "encaixe" em cada página.
- **`.builder`**: constrói as páginas **sob demanda**, conforme o usuário se aproxima delas.
- **`PageController`**: permite **comandar** o `PageView` pelo código (`nextPage`, `animateToPage`, `jumpToPage`). Como o `AnimationController`, ele **precisa de `dispose`**.
- **`onPageChanged` + `setState`**: o `PageView` avisa quando a página muda, **seja por deslize ou pelo botão**. Guardamos o índice em `_currentPage` e chamamos `setState` para que o resto da tela (indicador, texto do botão) seja reconstruído.

```text
usuário desliza  ─┐
                  ├─► onPageChanged(index) ─► setState ─► build() ─► indicador e botão atualizados
botão "Próximo" ──┘   (via nextPage)
```

Os dois caminhos passam pelo **mesmo ponto**, e é por isso que swipe e botão ficam sempre sincronizados.

- **`_nextPage`**: se não é a última página, avança com animação de 300 ms (`easeInOut`: acelera e desacelera, como uma folha sendo virada). Se é a última, conclui.
- **`_finishOnboarding`**: **persistir → verificar `mounted` → navegar**. Salvar **antes** de navegar garante que, se o app for fechado no meio, o onboarding não reapareça por um erro de ordem.
- **Sem loading**: gravar um booleano leva milissegundos. Mostrar "Salvando…" criaria uma espera artificial.

## 5.6 Passo 5: `_OnboardingContent`, o layout de uma página

### 📘 Conceito: "a página decide, o widget renderiza"

`_OnboardingPageState` decide **qual** item mostrar. `_OnboardingContent` sabe **como** mostrar qualquer item. Como as três páginas usam o mesmo widget, **a consistência visual é garantida pelo código**, e não por disciplina.

### 💻 Código

```dart
class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent({required this.item});

  final OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Flexible(
            flex: 6,
            child: AspectRatio(
              aspectRatio: 1,
              child: IllustrationCard(
                imagePath: item.imagePath,
                boxShaddowAlpha: 0.22,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            item.title,
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const GoldAccent(),
          const SizedBox(height: 16),
          Text(
            item.description,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.navy.withValues(alpha: 0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

### 📘 Conceitos

**A mesma linguagem visual da Splash.** Compare:

| Elemento | Splash | Onboarding |
|---|---|---|
| Imagem | `IllustrationCard` 160×160, sombra 0.12 | `IllustrationCard` responsivo, sombra 0.22 |
| Título | `displaySmall`, navy, w700 | `headlineSmall`, navy, bold |
| Assinatura | `GoldAccent(width: 80)` | `GoldAccent()` (40) |
| Texto de apoio | `bodyLarge`, navy 70% | `bodyMedium`, navy 70% |

O usuário **reconhece** o produto de uma tela para a outra.

**Hierarquia visual.** A ordem em que o olho percorre a tela é: ilustração → título → barrinha → descrição → indicador → botão. Os espaçamentos reforçam os agrupamentos:
- **40** entre imagem e título (blocos diferentes);
- **12 e 16** entre título, barrinha e descrição (mesmo bloco).

Espaços maiores separam, espaços menores agrupam.

**`Flexible` + `AspectRatio`: responsividade sem números fixos.**

```text
Column
├── SizedBox(32)          ← fixo
├── Flexible(flex: 6)     ← "pode ocupar o espaço que sobrar, mas pode encolher"
│   └── AspectRatio(1)    ← "seja sempre quadrado"
│       └── IllustrationCard
├── SizedBox(40)          ← fixo
├── Text (título)         ← altura do texto
├── ...
```

- Em um celular **grande**, o cartão cresce até o limite da largura (quadrado).
- Em um celular **pequeno** ou com **fonte ampliada**, o `Flexible` deixa o cartão **encolher** para que título e descrição continuem visíveis.

Com um tamanho fixo (`height: 300`), o conteúdo **transbordaria** em telas pequenas (a faixa amarela e preta de *overflow*).

**`Expanded` × `Flexible`.** `Expanded` obriga o filho a ocupar **todo** o espaço livre. `Flexible` permite que ele ocupe **até** esse espaço. Para a ilustração, `Flexible` é o correto.

**`height: 1.4` na descrição.** É a altura da linha como múltiplo do tamanho da fonte. Textos de mais de uma linha ficam mais legíveis com um espaçamento entre linhas maior.

**`TextAlign.center`.** Funciona para textos curtos de onboarding. Para parágrafos longos, alinhamento à esquerda lê melhor.

## 5.7 Passo 6: Indicador de progresso (*dots*)

### 📘 Conceito

Na Splash, o progresso era uma **barra de tempo**. No onboarding, ele é uma **posição em uma sequência**. A ideia é a mesma ("onde estou, quanto falta") com outra representação.

```text
● ○ ○   →   ○ ● ○   →   ○ ○ ●
```

### 💻 Widget

```dart
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.currentPage, required this.totalPages});

  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: isActive ? 24.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.gold
                : AppColors.navy.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
```

### 💻 Onde usar

No `build` do `_OnboardingPageState`, **logo abaixo do `PageView`**:

```dart
Expanded(
  child: PageView.builder(/* ... */),
),
_PageIndicator(
  currentPage: _currentPage,
  totalPages: OnboardingPage.items.length,
),
```

### 📘 Conceitos

- **`List.generate(n, (index) => ...)`**: cria `n` widgets a partir do índice. O indicador funciona com qualquer número de páginas.
- **`AnimatedContainer` (animação implícita)**: basta mudar `width` e `color`, e ele anima sozinho, sem controller. Quando `_currentPage` muda, o dot ativo "estica" de 8 para 24 e o anterior "encolhe".
- **`BorderRadius.circular(999)`**: um raio maior que o próprio widget gera uma pílula (ou um círculo, quando largura = altura).
- **Stateless**: o indicador **não guarda estado**, só desenha o `currentPage` que recebe. Quem guarda o estado é a página.
- **Fora do `PageView`**: o indicador **não desliza** com as páginas, fica parado enquanto o conteúdo passa.
- **Cores iguais às da barra da Splash**: dourado ativo sobre navy translúcido.

### 📘 Acessibilidade

O dot ativo se diferencia pela **largura**, e não só pela cor. Isso é importante porque:

- o dourado sobre fundo claro tem **contraste baixo**;
- pessoas com daltonismo podem não distinguir as cores.

**Nunca comunique uma informação só por cor.**

## 5.8 Passo 7: A ação principal (`FilledButton`)

### 💻 Código

```dart
bottomNavigationBar: Padding(
  padding: const EdgeInsets.all(24),
  child: FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    onPressed: _nextPage,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Text(
        _currentPage < OnboardingPage.items.length - 1
            ? 'Próximo'
            : 'Começar',
        key: ValueKey<int>(_currentPage),
        style: const TextStyle(fontSize: 16),
      ),
    ),
  ),
),
```

### 📘 Conceitos

**Hierarquia de botões no Material 3:**

| Botão | Peso visual | Uso |
|---|---|---|
| `FilledButton` | máximo (fundo sólido) | **ação principal**, uma por tela |
| `FilledButton.tonal` | alto | ação importante secundária |
| `OutlinedButton` | médio | alternativa |
| `TextButton` | mínimo | ação secundária ("Pular", "Cancelar") |

O `ElevatedButton` da versão inicial tinha sombra e fundo claro, e não se destacava como ação principal.

**`styleFrom`.** Personaliza o botão com as cores da marca: navy (cor de maior contraste da paleta) com texto branco.

**`bottomNavigationBar`.** O `Scaffold` posiciona esse slot **sempre na base da tela**, fora do `body`. O botão **nunca muda de lugar**, em nenhuma das páginas.

**"Próximo" → "Começar".** Na última página, o usuário deixa de *navegar* e passa a *concluir*. O texto muda para comunicar essa **mudança de contexto**.

**`AnimatedSwitcher` + `transitionBuilder`.** É a mesma técnica do status da Splash: o texto troca com *crossfade*. O `transitionBuilder` define a transição (o padrão já é fade, mas deixá-lo explícito documenta a intenção e permite trocar por `ScaleTransition`, por exemplo).

> ⚠️ A `key` usada é `ValueKey<int>(_currentPage)`, que muda a cada página, então o texto "Próximo" faz fade para "Próximo" ao passar da página 1 para a 2. Veja a correção na Parte 6.

**Microcopy.** "Próximo" e "Começar" são curtos, verbos ou indicações de ação, e **consistentes**: não alterne entre "Avançar", "Seguinte" e "Continuar".

## 5.9 Passo 8: A ação secundária ("Pular")

### 📘 Conceito: decisão de produto

Incluir "Pular" **não é obrigatório**. Pergunte:
- o onboarding coleta algo essencial? (no CeliLac, não);
- quem reinstala o app precisa rever tudo? (não).

Se "Pular" existir, ele é **secundário**: `TextButton`, discreto, no canto superior.

### 💻 Código

```dart
Widget _buildTopBar() {
  final isLastPage = _currentPage == OnboardingPage.items.length - 1;
  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerRight,
        child: AnimatedOpacity(
          opacity: isLastPage ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: TextButton(
            onPressed: _finishOnboarding,
            child: const Text(
              'Pular',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
```

### 📘 Conceitos

- **Método, e não widget**: `_buildTopBar` depende do estado (`_currentPage`, `_finishOnboarding`). Pela regra da Parte 4.4, é um método.
- **`SafeArea` aqui**: como o `body` do `Scaffold` não tem `SafeArea` próprio, a barra superior precisa se proteger da barra de status e do *notch*.
- **`AnimatedOpacity` em vez de `if`**: na última página, "Pular" não faz sentido, porque "Começar" já faz a mesma coisa. Com um `if`, o botão sumiria **e o layout pularia** (o espaço dele desapareceria). Com opacidade 0, ele some com fade e **o espaço é preservado**.
- **"Pular" chama `_finishOnboarding`**: pular também é concluir. O onboarding não deve reaparecer.

> ⚠️ Um widget com opacidade 0 **continua recebendo toques**. Veja a correção na Parte 6.

## 5.10 Passo 9: Montando o `build` e a animação de entrada

### 📘 Conceito: movimento com moderação

A Splash tem uma coreografia rica, porque é o **momento da marca**. No onboarding, o foco é o **conteúdo**, então a animação de entrada é:
- **única** (só ao abrir, não a cada página);
- **curta** (800 ms);
- **discreta** (o conteúdo sobe só 5% da própria altura).

Evite animar tudo ao mesmo tempo: imagem entrando, título deslizando, botão pulando e indicador piscando competem pela atenção.

### 💻 Controller e animações

```dart
class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _introController;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _actionFade;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _contentSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
        );

    _actionFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _introController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _introController.dispose();
    super.dispose();
  }

  // _nextPage, _finishOnboarding, _buildTopBar, build
}
```

### 📘 Conceitos

- **`SingleTickerProviderStateMixin`**: há **um** controller de animação, então o *Single* basta. O `PageController` não é um `AnimationController` e não precisa de ticker do `State`.
- **Dois momentos**: conteúdo (0.0–0.5) e ações (0.4–1.0). Com a pequena sobreposição, as ações surgem enquanto o conteúdo termina de assentar.
- **`Tween<double>(0, 1)` em `_contentFade`**: um `CurvedAnimation` já produz valores de 0 a 1, então esse `Tween` é redundante (mas inofensivo). Compare com `_actionFade`, que usa o `CurvedAnimation` diretamente.
- **`_contentSlide` sem `Interval`**: o deslize dura os 800 ms inteiros, enquanto o fade termina na metade. O conteúdo fica visível rápido e termina de se acomodar suavemente.
- **Dois `dispose`**: `_pageController` **e** `_introController`.

### 💻 O `build` completo

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        FadeTransition(opacity: _actionFade, child: _buildTopBar()),
        Expanded(
          child: FadeTransition(
            opacity: _contentFade,
            child: SlideTransition(
              position: _contentSlide,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: OnboardingPage.items.length,
                itemBuilder: (context, index) {
                  return _OnboardingContent(
                    item: OnboardingPage.items[index],
                  );
                },
              ),
            ),
          ),
        ),
        FadeTransition(
          opacity: _actionFade,
          child: _PageIndicator(
            currentPage: _currentPage,
            totalPages: OnboardingPage.items.length,
          ),
        ),
      ],
    ),
    bottomNavigationBar: Padding(
      padding: const EdgeInsets.all(24),
      child: FilledButton(/* ... Passo 7 ... */),
    ),
  );
}
```

### 📘 A estrutura

```text
Scaffold
├── body: Column
│   ├── FadeTransition(_actionFade)          → "Pular"            (fixo)
│   ├── Expanded
│   │   └── Fade + Slide(_content*)
│   │       └── PageView                     → só isto desliza
│   │           └── _OnboardingContent × 3
│   └── FadeTransition(_actionFade)          → dots               (fixo)
└── bottomNavigationBar
    └── FilledButton                         → Próximo/Começar    (fixo)
```

- **`Expanded` no `PageView`**: o `PageView` precisa de uma altura definida. O `Expanded` dá a ele **todo o espaço** que sobra entre a barra superior e o indicador.
- **Só o conteúdo desliza**: "Pular", dots e botão ficam **parados** enquanto as páginas passam. Isso dá estabilidade e previsibilidade.
- **As transições envolvem regiões inteiras**, como na Splash.

▶️ **Execute e teste:**
- deslize para frente e para trás: dots e texto do botão acompanham;
- "Próximo" avança com animação;
- na página 3: "Pular" some e o botão diz "Começar";
- "Começar" leva à Home;
- feche e reabra o app (com a decisão de rota da Parte 4.5 ativa): o app vai direto para a Home;
- repita, agora usando "Pular" a partir da página 1.

---

# Parte 6: Revisão de código

Uma boa prática profissional é **revisar** o que foi implementado. A lista abaixo foi levantada a partir do código do CeliLac. Cada item traz o problema, a consequência e a correção. Faça como **exercício** no seu projeto.

## 6.1 🐞 "Pular" invisível continua clicável

**Problema.** Na última página, o "Pular" fica com opacidade 0, mas o `onPressed` continua ativo. Um toque no canto superior direito conclui o onboarding sem o usuário ver o botão.

**Correção:**

```dart
child: TextButton(
  onPressed: isLastPage ? null : _finishOnboarding,
  // ...
),
```

Com `onPressed: null` o botão fica **desabilitado**. Outra opção é envolver com `IgnorePointer(ignoring: isLastPage, child: ...)`.

📘 `Opacity` e `AnimatedOpacity` só afetam a **pintura**, e não a **interação**.

## 6.2 🐞 Botão sem proteção da área de gestos

**Problema.** O `bottomNavigationBar` do `Scaffold` **não aplica** `SafeArea` automaticamente (o `NavigationBar` do Material aplica, mas um `Padding` qualquer não). Em aparelhos com barra de gestos ou *home indicator*, o botão pode ficar colado ou sob essa área.

**Correção:**

```dart
bottomNavigationBar: SafeArea(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: FilledButton(/* ... */),
  ),
),
```

## 6.3 🐞 Toque duplo em "Começar"

**Problema.** Dois toques rápidos chamam `_finishOnboarding` duas vezes e fazem **dois** `pushReplacement` seguidos.

**Correção:**

```dart
bool _isFinishing = false;

Future<void> _finishOnboarding() async {
  if (_isFinishing) return;
  _isFinishing = true;

  await OnboardingStorage().markAsCompleted();
  if (!mounted) return;

  Navigator.of(context).pushReplacement(/* ... */);
}
```

## 6.4 ✨ `key` do `AnimatedSwitcher` mais precisa

**Problema.** `ValueKey<int>(_currentPage)` muda a cada página, então o texto faz fade de "Próximo" para "Próximo".

**Correção:** a `key` deve representar o **conteúdo** (como na Splash, onde a `key` é a própria mensagem):

```dart
bool get _isLastPage => _currentPage == OnboardingPage.items.length - 1;

// ...
child: Text(
  _isLastPage ? 'Começar' : 'Próximo',
  key: ValueKey<bool>(_isLastPage),
),
```

O getter `_isLastPage` também elimina a condição repetida em `_nextPage`, `_buildTopBar` e no botão.

## 6.5 ✨ Transição consistente para a Home

**Problema.** A Splash usa **fade** (`PageRouteBuilder`), mas o onboarding vai para a Home com `MaterialPageRoute` (deslize padrão). As transições ficam inconsistentes.

**Correção:** extrair a rota com fade para um lugar compartilhado e usá-la nos dois lugares:

```dart
// lib/app/routes/fade_route.dart
import 'package:flutter/material.dart';

PageRouteBuilder<void> fadeRoute(Widget page) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
```

```dart
Navigator.of(context).pushReplacement(fadeRoute(const HomePage()));
```

## 6.6 ✨ Fundo do onboarding igual ao da Splash

**Problema.** A Splash tem um gradiente branco → `#F2F2F2`, mas o onboarding usa o fundo padrão do `Scaffold`. Na transição, a cor de fundo muda.

**Correção:** aplicar o mesmo `Container` com `LinearGradient` no `body` do onboarding. Se o gradiente se repetir em mais telas, extraia um widget `BrandBackground` para `lib/app/common/widgets/`. Outra opção é definir `scaffoldBackgroundColor: AppColors.background` em um `ThemeData` no `MaterialApp`.

## 6.7 ✨ Botão com área de toque confortável

O `padding` vertical do botão ficou comentado. Garanta uma altura confortável (Material recomenda no mínimo 48 dp, e botões principais costumam ter entre 52 e 56):

```dart
style: FilledButton.styleFrom(
  minimumSize: const Size.fromHeight(56),
  // ...
),
```

`Size.fromHeight` também faz o botão ocupar **a largura toda**.

## 6.8 ✨ Nomes e organização

| Encontrado | Sugestão | Por quê |
|---|---|---|
| `boxShaddowAlpha` | `shadowAlpha` | corrige a grafia ("shadow") e encurta |
| classe `IllustrationCard` em `image_card.dart` | `illustration_card.dart` | o nome do arquivo deve refletir a classe (convenção Dart) |
| `IllustrationCard` sem `fit` | `Image.asset(imagePath, fit: BoxFit.contain)` | deixa a intenção explícita |
| `import 'package:celilac/...'` misturado com `import '../../...'` | escolher **um** estilo por projeto | consistência (o lint `prefer_relative_imports` ou `always_use_package_imports` pode impor isso) |
| `EdgeInsets.symmetric(horizontal: 32)` sem `const` | `const EdgeInsets...` | o lint `prefer_const_constructors` sinaliza |
| `late AnimationController _introController` | `late final` | ele nunca é reatribuído |

## 6.9 🧹 Limpeza

- [ ] Remover o código comentado em `SplashPage._initialize()` (ou ativar a versão da Parte 4.5).
- [ ] Remover os *imports* sem uso apontados pelo `flutter analyze`.
- [ ] Remover `flutter_spinkit` do `pubspec.yaml`: foi adicionado mas não é usado.
- [ ] Atualizar os caminhos em `flutter_native_splash.yaml` e `flutter_launcher_icons.yaml` após a reorganização dos assets (Parte 2).
- [ ] Otimizar o tamanho das imagens do onboarding.
- [ ] Rodar `flutter analyze` até obter **"No issues found!"**.

---

# Parte 7: Validação

## 7.1 Responsividade

Teste pelo menos:

| Cenário | Como | O que observar |
|---|---|---|
| Tela pequena | emulador ~4.7" (ex.: iPhone SE, Pixel 4a) | ilustração encolhe, sem faixa de *overflow*, botão visível |
| Tela grande | tablet | conteúdo não fica esticado; considere `ConstrainedBox(maxWidth: 480)` |
| Paisagem | girar o aparelho | nada cortado (ou trave a orientação em retrato) |

## 7.2 Acessibilidade

| Item | Como testar |
|---|---|
| Fonte ampliada | Configurações → Acessibilidade → tamanho da fonte no máximo |
| Leitor de tela | TalkBack (Android) / VoiceOver (iOS): a ordem de leitura faz sentido? |
| Contraste | navy sobre fundo claro: ótimo. **Nunca use dourado para texto** (contraste ≈ 2:1) |
| Não depender de cor | o dot ativo também é mais largo ✔ |

Duas melhorias simples:

```dart
// ilustração decorativa: o título já comunica a mensagem
Image.asset(imagePath, excludeFromSemantics: true)

// indicador anunciado pelo leitor de tela
Semantics(
  label: 'Etapa ${currentPage + 1} de $totalPages',
  child: Row(/* dots */),
)
```

## 7.3 Teste de clareza (com outra pessoa)

1. Mostre **uma** página e pergunte: *"o que esta tela quer te dizer?"*
2. Mostre as três em ordem e pergunte: *"existe uma progressão?"*

Se as respostas estiverem longe do objetivo, revise título, descrição e imagem **antes** do código.

## 7.4 Teste de fluxo completo

- [ ] Primeira execução: ícone → splash nativa → Splash → Onboarding
- [ ] Swipe para frente e para trás
- [ ] Botão "Próximo" e indicador sincronizados
- [ ] "Começar" → Home
- [ ] "Pular" → Home
- [ ] "Voltar" na Home fecha o app (não volta ao onboarding)
- [ ] Segunda execução: Splash → **Home direto**

---

# Parte 8: Aplicando no seu projeto

## Roteiro

1. **Identidade:** extraia as cores do seu logo e crie `AppColors`.
2. **Assets:** organize em `brand/`, `onboarding/` e `app_icons/` e declare no `pubspec.yaml`.
3. **Ícone e splash nativa:** configure `flutter_launcher_icons` e `flutter_native_splash` com o **mesmo fundo** da sua `SplashPage`.
4. **Widgets compartilhados:** crie o seu "cartão" e a sua "assinatura" (não precisa ser uma barrinha dourada: pode ser um ícone, um traço, uma forma da sua marca).
5. **Splash:** layout → animação escalonada → feedback de progresso → decisão de rota → `dispose`.
6. **Narrativa:** escreva as 3 frases do onboarding e teste se contam uma história.
7. **Ilustrações:** gere as 3 imagens com o **mesmo estilo** e a **paleta da marca** (Apêndice A).
8. **Onboarding:** modelo → persistência → `PageView` → conteúdo → indicador → botões → animação de entrada.
9. **Revisão:** aplique os itens da Parte 6.
10. **Validação:** Parte 7.

## Checklist final

- [ ] Cores centralizadas em `AppColors`, sem cores soltas no código
- [ ] Splash nativa e Splash Flutter com o mesmo fundo
- [ ] Splash com animação escalonada e duração razoável
- [ ] `mounted` verificado após todo `await` que antecede o uso de `context`
- [ ] Todos os controllers com `dispose`
- [ ] `pushReplacement` para a Splash e o onboarding (sem "voltar" para eles)
- [ ] Onboarding com 3 páginas, uma ideia por página, mesma estrutura
- [ ] Ilustrações coerentes com a mensagem e com a marca
- [ ] Indicador de progresso sincronizado com swipe e botão
- [ ] `FilledButton` como ação principal, fixo na base, com `SafeArea`
- [ ] "Pular" (se houver) como `TextButton`, desabilitado quando invisível
- [ ] Conclusão persistida **antes** de navegar
- [ ] Onboarding não reaparece na segunda execução
- [ ] Layout testado em tela pequena, grande e com fonte ampliada
- [ ] `flutter analyze` sem avisos

---

# Apêndice A: Prompts para gerar as ilustrações

### Especificação técnica

- **Formato:** PNG com fundo transparente (ou branco puro, já que a imagem fica dentro de um cartão branco), **1024×1024**, quadrado.
- **Peso:** otimize para menos de 200 KB cada.
- **Consistência:** gere as três **na mesma sessão**. Os prompts compartilham o mesmo bloco de estilo.
- **Evite:** texto dentro da imagem, marcas reais, símbolos de proibição. No caso do CeliLac, evite também pão e trigo comuns em destaque, porque em um app para celíacos eles comunicariam o oposto.

> Os prompts estão em inglês porque os geradores de imagem costumam seguir melhor as instruções nessa língua.
>
> 🧩 **No seu projeto:** troque os códigos de cor pelos da sua marca, o "wheat-leaf branch" pelo elemento do seu logo e a descrição da cena pela mensagem de cada página.

### Imagem 1: Descoberta (`assets/images/onboarding/discovery.png`)

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

### Imagem 2: Informação (`assets/images/onboarding/information.png`)

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

### Imagem 3: Personalização (`assets/images/onboarding/profile.png`)

Página: *"Uma experiência mais relevante"*

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

### Se as imagens saírem inconsistentes

Depois de aprovar a primeira imagem, gere as outras **na mesma conversa** acrescentando:

```text
Use exactly the same illustration style, line weight, color palette and level
of detail as the previous image, so the three images look like one series.
```

No Midjourney, use a primeira imagem como referência de estilo com `--sref <url-da-imagem-1>`.

---

# Apêndice B: Glossário

| Termo | Significado |
|---|---|
| **Asset** | Arquivo empacotado com o app (imagem, fonte, JSON), declarado no `pubspec.yaml` |
| **Design token** | Valor de design nomeado e reutilizável (ex.: `AppColors.navy`) |
| **Splash nativa** | Tela desenhada pelo sistema operacional enquanto o Flutter inicializa |
| **`StatefulWidget` / `State`** | Widget com estado mutável e ciclo de vida (`initState`, `build`, `dispose`) |
| **`mounted`** | Indica se o `State` ainda está na árvore; verificar após `await` |
| **`AnimationController`** | "Relógio" de 0.0 a 1.0 que dirige animações explícitas |
| **Ticker / `vsync`** | Sinal a cada frame; o *mixin* `TickerProvider` o fornece e o pausa fora de tela |
| **`Tween`** | Converte 0.0–1.0 em um intervalo de valores (escala, posição, cor) |
| **`CurvedAnimation`** | Aplica uma curva de aceleração a uma animação |
| **`Interval`** | Faz uma animação acontecer só em um trecho do tempo do controller |
| **Staggered animation** | Animações escalonadas, parcialmente sobrepostas |
| **Animação implícita** | Widget `Animated*` que anima sozinho quando um valor muda |
| **Animação explícita** | Controlada por um `AnimationController` + widgets `*Transition` |
| **`AnimatedBuilder`** | Reconstrói um trecho a cada mudança de uma animação |
| **`AnimatedSwitcher`** | Anima a troca de um filho por outro (identificado pela `key`) |
| **`Key` / `ValueKey`** | Identidade de um widget; diz ao Flutter quando é "outro" widget |
| **`PageView` / `PageController`** | Páginas com deslize horizontal / controle programático delas |
| **`pushReplacement`** | Navega substituindo a tela atual (sem "voltar" para ela) |
| **`PageRouteBuilder`** | Rota com transição personalizada |
| **`SafeArea`** | Afasta o conteúdo de notch, barra de status e área de gestos |
| **`Spacer` / `Expanded` / `Flexible`** | Distribuem o espaço livre de `Row`/`Column` (ocupar tudo × até tudo) |
| **`AspectRatio`** | Força uma proporção (ex.: 1 = quadrado) |
| **`BoxFit`** | Como uma imagem ocupa o espaço (`contain`, `cover`, …) |
| **`shared_preferences`** | Armazenamento persistente simples de chave-valor |
| **Microcopy** | Pequenos textos da interface ("Próximo", "Começar", "Pular") |
| **Hierarquia visual** | Ordem em que o olho percebe os elementos da tela |
