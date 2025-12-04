# Prompt: Toggle de Tema (claro/escuro)

## Introdução

Neste guia, você aprenderá a implementar um sistema completo de alternância de tema (claro/escuro) em um aplicativo Flutter. Este é um recurso essencial em apps modernos, pois:

- 🌙 **Conforto visual** — Tema escuro reduz fadiga ocular em ambientes com pouca luz
- 🔋 **Economia de bateria** — Em telas OLED, pixels escuros consomem menos energia
- ♿ **Acessibilidade** — Alguns usuários têm necessidades visuais específicas
- 🎨 **Experiência do usuário** — Dar controle ao usuário aumenta satisfação

O guia está dividido em **6 etapas progressivas**, cada uma construindo sobre a anterior. Você pode parar em qualquer etapa e ter um resultado funcional.

---

## Pré-requisitos

Antes de começar, você deve estar familiarizado com:

| Conceito | Nível | Onde revisar |
|----------|-------|-------------|
| Widgets Stateful vs Stateless | Básico | [Flutter Docs](https://docs.flutter.dev/development/ui/interactive) |
| `setState()` e ciclo de vida | Básico | [Lifecycle](https://api.flutter.dev/flutter/widgets/State-class.html) |
| Navegação e rotas | Básico | [Navigation](https://docs.flutter.dev/development/ui/navigation) |
| `MaterialApp` e `ThemeData` | Intermediário | [Theming](https://docs.flutter.dev/cookbook/design/themes) |

---

## Objetivo

Adicionar um toggle de tema claro/escuro no Drawer principal (`HomePage`) e conectá-lo ao `MaterialApp` para aplicar no app inteiro, com opção de persistir via `SharedPreferencesService`.

### O que você vai aprender

- ✅ Criar um toggle visual com `SwitchListTile`
- ✅ Sincronizar UI com o tema do sistema operacional
- ✅ Usar `ColorScheme.fromSeed()` do Material 3
- ✅ Criar paletas de cores personalizadas
- ✅ Implementar gerenciamento de estado com `ChangeNotifier`
- ✅ Persistir preferências com `SharedPreferences`

---

## Onde olhar antes de codar

| Arquivo | Descrição |
|---------|-----------|
| `lib/features/app/food_safe_app.dart` | `themeMode` fixo em `ThemeMode.system` com `lightColorScheme`/`darkColorScheme`. |
| `lib/features/home/home_page.dart` | Drawer com header e ListTiles (Editar perfil, Privacidade & consentimentos, Reexibir tutorial, Política de Privacidade). Local ideal para o toggle. |
| `lib/services/shared_preferences_services.dart` | Utilitários de persistência. |
| `lib/services/preferences_keys.dart` | Chaves de persistência; adicionar `themeMode` se decidir salvar a preferência. |

---

## Como funciona o tema atualmente

O app **já responde automaticamente** às mudanças de tema do sistema porque `food_safe_app.dart` está configurado com:

```dart
theme: ThemeData(..., colorScheme: lightColorScheme),
darkTheme: ThemeData(..., colorScheme: darkColorScheme),
themeMode: ThemeMode.system,
```

### Fluxo do rebuild automático de tema

Quando o usuário alterna o tema no simulador/emulador:

1. O sistema operacional notifica a mudança de `platformBrightness`.
2. O Flutter recebe essa notificação via binding nativo.
3. O `MediaQuery` é atualizado com o novo valor de `Brightness`.
4. O `MaterialApp` (e todos os widgets que dependem do tema) são **rebuilt** automaticamente.
5. O `MaterialApp` escolhe entre `theme` ou `darkTheme` baseado no `themeMode: ThemeMode.system`.

> **Nota:** Não é um hot reload — é o próprio framework reagindo à mudança de configuração do sistema (similar a quando a orientação da tela muda). Isso é muito mais leve que um hot reload completo.

---

## Plano de implementação

### Etapa 1 — Toggle visual (sem funcionalidade)

**Objetivo:** Inserir no Drawer um `SwitchListTile` rotulado "Tema escuro", apenas para visualização, sem alterar o tema global.

**Arquivo:** `lib/features/home/home_page.dart`

**Posicionamento:** Depois do `Divider` e antes de "Política de Privacidade".

#### Código sugerido

Estado local para o switch:

```dart
bool _isDarkMode = false;
```

Switch no Drawer:

```dart
SwitchListTile(
  secondary: const Icon(Icons.dark_mode_outlined),
  title: const Text('Tema escuro'),
  value: _isDarkMode,
  onChanged: (value) {
    setState(() {
      _isDarkMode = value;
    });
  },
),
```

**Por que:** `SwitchListTile` é o padrão de alternância em mobile. O `setState` aqui apenas reflete o toggle local, sem alterar `themeMode` global nem persistir dados.

#### Sugestões de UI/UX

- Usar `Switch.adaptive` dentro do `SwitchListTile` para respeitar o estilo iOS/Android nativo.
- Adicionar `subtitle` com texto curto ("Acompanhar tema do sistema" / "Ativar tema escuro") para reforçar contexto.
- Alternar `secondary` entre `Icons.dark_mode_outlined` e `Icons.light_mode_outlined` conforme o valor, para feedback visual imediato.
- Ajustar `contentPadding` do `SwitchListTile` para alinhar com demais itens do Drawer.
- Alternativa: usar `ListTile` + `Switch` no `trailing` com `dense: true` para reduzir ruído visual.

---

### Etapa 2 — Sincronizar toggle com o tema do sistema

**Objetivo:** Atualizar o estado local `_isDarkMode` para refletir o tema atual do sistema operacional ao iniciar e quando ele mudar.

**Arquivo:** `lib/features/home/home_page.dart`

#### Esclarecimento

O app já aplica o tema correto automaticamente (conforme explicado acima). Esta etapa apenas sincroniza o **estado visual do toggle** com o tema atual, para que o switch reflita corretamente se o app está em modo claro ou escuro.

#### Código sugerido

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final brightness = MediaQuery.platformBrightnessOf(context);
  setState(() {
    _isDarkMode = brightness == Brightness.dark;
  });
}
```

**Por que:** `didChangeDependencies` é chamado após `initState` e sempre que as dependências mudam (ex.: tema do sistema alterado enquanto o app está em primeiro plano). Usar `MediaQuery.platformBrightnessOf` é a forma idiomática no Flutter.

#### Alternativas

- `WidgetsBinding.instance.platformDispatcher.platformBrightness`
- `SchedulerBinding.instance.platformDispatcher.platformBrightness` (se precisar antes do primeiro frame, em `initState`)

#### Observações

- Se o usuário trocar o tema do sistema enquanto o app está aberto, o `didChangeDependencies` será chamado novamente e o toggle será atualizado automaticamente.
- Nesta etapa, o toggle ainda é apenas visual; a aplicação do tema via toggle virá nas etapas seguintes.

---

### Etapa 3 — Usar ColorScheme.fromSeed para gerar temas automaticamente

**Objetivo:** Substituir os `ColorScheme` manuais por `ColorScheme.fromSeed()`, que gera automaticamente um esquema de cores harmonioso para claro e escuro a partir de uma única cor base (seed color).

**Arquivo:** `lib/theme/color_schemes.dart`

#### Por que usar `fromSeed`?

O Material 3 introduziu o conceito de **Dynamic Color**, onde a partir de uma cor semente (seed color), o sistema gera automaticamente:
- Todas as cores do `ColorScheme` (primary, secondary, tertiary, surface, etc.)
- Versões claras e escuras harmoniosas
- Contraste adequado entre foreground/background

Isso elimina a necessidade de definir manualmente cada cor e garante consistência visual.

#### Código sugerido

```dart
import 'package:flutter/material.dart';

// Cor semente do app (baseada na identidade visual)
const Color _seedColor = Color(0xFFDF9E1C); // Dourado/Âmbar do app

// Gera ColorScheme claro automaticamente
final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: _seedColor,
  brightness: Brightness.light,
);

// Gera ColorScheme escuro automaticamente
final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: _seedColor,
  brightness: Brightness.dark,
);
```

**Por que:** Com uma única `_seedColor`, o Flutter gera automaticamente todas as 29+ cores do `ColorScheme` para ambos os modos, garantindo:
- Harmonia cromática
- Contraste acessível (WCAG)
- Consistência entre claro/escuro

#### Observações

- A `_seedColor` deve representar a cor principal da identidade visual do app.
- Se precisar customizar cores específicas após o `fromSeed`, use o método `copyWith()`:
  ```dart
  final lightColorScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.light,
  ).copyWith(
    error: Colors.red,  // sobrescrever apenas o que precisar
  );
  ```
- A função `lightInputDecorationTheme()` existente pode continuar usando as cores do scheme gerado.

#### Atualizar `food_safe_app.dart`

Após alterar `color_schemes.dart`, verificar se `food_safe_app.dart` continua funcionando normalmente, pois ele já importa `lightColorScheme` e `darkColorScheme`.

---

### Etapa 4 — Criar temas personalizados com cores específicas

**Objetivo:** Demonstrar como criar `ColorScheme` totalmente customizados, definindo cada cor manualmente. Isso é útil quando o designer fornece uma paleta específica ou quando se deseja controle total sobre as cores do app.

**Arquivo:** `lib/theme/color_schemes.dart`

#### Quando usar temas manuais vs `fromSeed`?

| Abordagem | Quando usar |
|-----------|-------------|
| `ColorScheme.fromSeed()` | Prototipagem rápida, apps sem designer dedicado, garantia de harmonia cromática automática |
| `ColorScheme()` manual | Paleta fornecida pelo designer, identidade visual rígida, controle total sobre cada cor |

#### Anatomia do ColorScheme

O `ColorScheme` do Material 3 possui **29+ propriedades de cor**. As principais são:

| Propriedade | Descrição |
|-------------|-----------|
| `primary` | Cor principal do app (botões, FAB, elementos de destaque) |
| `onPrimary` | Cor do texto/ícones sobre `primary` |
| `primaryContainer` | Versão mais suave de `primary` para containers |
| `onPrimaryContainer` | Cor do texto/ícones sobre `primaryContainer` |
| `secondary` | Cor secundária (elementos menos proeminentes) |
| `onSecondary` | Cor do texto/ícones sobre `secondary` |
| `tertiary` | Cor terciária (acentos, badges) |
| `surface` | Cor de fundo de cards, sheets, dialogs |
| `onSurface` | Cor do texto/ícones sobre `surface` |
| `error` | Cor para estados de erro |
| `onError` | Cor do texto/ícones sobre `error` |
| `outline` | Cor para bordas e divisores |

#### Código sugerido — Tema claro personalizado

```dart
const ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  
  // Cores primárias
  primary: Color(0xFF6750A4),           // Roxo Material
  onPrimary: Color(0xFFFFFFFF),         // Branco para contraste
  primaryContainer: Color(0xFFEADDFF),  // Roxo claro
  onPrimaryContainer: Color(0xFF21005D),// Roxo escuro
  
  // Cores secundárias
  secondary: Color(0xFF625B71),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFE8DEF8),
  onSecondaryContainer: Color(0xFF1D192B),
  
  // Cores terciárias
  tertiary: Color(0xFF7D5260),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFFFD8E4),
  onTertiaryContainer: Color(0xFF31111D),
  
  // Superfícies
  surface: Color(0xFFFFFBFE),
  onSurface: Color(0xFF1C1B1F),
  surfaceContainerHighest: Color(0xFFE6E0E9),
  onSurfaceVariant: Color(0xFF49454F),
  
  // Erro
  error: Color(0xFFB3261E),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFF9DEDC),
  onErrorContainer: Color(0xFF410E0B),
  
  // Outros
  outline: Color(0xFF79747E),
  outlineVariant: Color(0xFFCAC4D0),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF313033),
  onInverseSurface: Color(0xFFF4EFF4),
  inversePrimary: Color(0xFFD0BCFF),
  surfaceTint: Color(0xFF6750A4),
);
```

#### Código sugerido — Tema escuro personalizado

```dart
const ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  
  // Cores primárias (invertidas para dark)
  primary: Color(0xFFD0BCFF),           // Roxo claro
  onPrimary: Color(0xFF381E72),         // Roxo escuro para contraste
  primaryContainer: Color(0xFF4F378B),  // Roxo médio
  onPrimaryContainer: Color(0xFFEADDFF),// Roxo muito claro
  
  // Cores secundárias
  secondary: Color(0xFFCCC2DC),
  onSecondary: Color(0xFF332D41),
  secondaryContainer: Color(0xFF4A4458),
  onSecondaryContainer: Color(0xFFE8DEF8),
  
  // Cores terciárias
  tertiary: Color(0xFFEFB8C8),
  onTertiary: Color(0xFF492532),
  tertiaryContainer: Color(0xFF633B48),
  onTertiaryContainer: Color(0xFFFFD8E4),
  
  // Superfícies (escuras)
  surface: Color(0xFF1C1B1F),
  onSurface: Color(0xFFE6E1E5),
  surfaceContainerHighest: Color(0xFF49454F),
  onSurfaceVariant: Color(0xFFCAC4D0),
  
  // Erro
  error: Color(0xFFF2B8B5),
  onError: Color(0xFF601410),
  errorContainer: Color(0xFF8C1D18),
  onErrorContainer: Color(0xFFF9DEDC),
  
  // Outros
  outline: Color(0xFF938F99),
  outlineVariant: Color(0xFF49454F),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFE6E1E5),
  onInverseSurface: Color(0xFF313033),
  inversePrimary: Color(0xFF6750A4),
  surfaceTint: Color(0xFFD0BCFF),
);
```

#### Dicas para criar paletas personalizadas

1. **Use ferramentas online:**
   - [Material Theme Builder](https://m3.material.io/theme-builder) — gera paletas M3 completas
   - [Coolors](https://coolors.co/) — gerar paletas harmoniosas
   - [Adobe Color](https://color.adobe.com/) — explorar harmonias cromáticas

2. **Regra de contraste:**
   - Cores `on*` devem ter contraste mínimo de 4.5:1 com sua cor base (WCAG AA)
   - Usar ferramentas como [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)

3. **Padrão de nomenclatura:**
   - `primary` → cor base
   - `onPrimary` → cor do conteúdo sobre `primary`
   - `primaryContainer` → versão mais suave para backgrounds
   - `onPrimaryContainer` → cor do conteúdo sobre `primaryContainer`

4. **Abordagem híbrida:**
   ```dart
   // Gerar base com fromSeed e customizar apenas o necessário
   final lightColorScheme = ColorScheme.fromSeed(
     seedColor: Color(0xFF6750A4),
     brightness: Brightness.light,
   ).copyWith(
     primary: Color(0xFFFF5722),  // Sobrescrever primary
     error: Color(0xFFD32F2F),    // Sobrescrever error
   );
   ```

#### Exercício sugerido para alunos

1. Escolher uma cor principal (ex: cor da marca de uma empresa fictícia)
2. Usar o [Material Theme Builder](https://m3.material.io/theme-builder) para gerar a paleta
3. Exportar as cores e criar um `ColorScheme` manual
4. Testar alternando entre claro e escuro no simulador
5. Comparar com a versão gerada por `fromSeed()` usando a mesma cor

---

### Etapa 5 — Controlador de tema com ChangeNotifier

**Objetivo:** Criar um controlador para gerenciar o estado do tema de forma centralizada, permitindo que o toggle altere efetivamente o tema do app.

---

#### O problema atual

Nas etapas 1 e 2, criamos um toggle visual que:
- Mostra um `SwitchListTile` no Drawer
- Sincroniza o estado visual com o tema do sistema

**Porém**, quando o usuário clica no toggle, nada acontece além de mudar a posição do switch. O tema do app **não muda** porque:
1. O `themeMode` está fixo em `ThemeMode.system` no `MaterialApp`
2. O estado `_isDarkMode` é local à `HomePage` e não afeta o `MaterialApp`
3. Não há comunicação entre o Drawer e o widget raiz (`FoodSafeApp`)

---

#### A solução: Gerenciamento de Estado

Precisamos de uma forma de:
1. **Armazenar** o modo de tema escolhido em um lugar acessível
2. **Notificar** o `MaterialApp` quando o modo mudar
3. **Reconstruir** a árvore de widgets para aplicar o novo tema

No Flutter, existem várias formas de fazer isso (Provider, Riverpod, BLoC, GetX, etc.). Aqui usaremos a abordagem mais simples e nativa: **`ChangeNotifier`**.

---

#### O que é ChangeNotifier?

`ChangeNotifier` é uma classe do Flutter que implementa o padrão **Observer** (observador). Ela permite:
- Armazenar estado mutável
- Notificar "ouvintes" quando o estado muda
- Reconstruir widgets que dependem desse estado

```
┌─────────────────┐      notifyListeners()     ┌─────────────────┐
│ ThemeController │ ─────────────────────────▶ │   MaterialApp   │
│  (ChangeNotifier)│                            │   (rebuilds)    │
└─────────────────┘                            └─────────────────┘
        ▲                                              │
        │ setMode()                                    │
        │                                              ▼
┌─────────────────┐                            ┌─────────────────┐
│  SwitchListTile │                            │  Novo ThemeMode │
│    (no Drawer)  │                            │    aplicado     │
└─────────────────┘                            └─────────────────┘
```

---

#### Anatomia de um ChangeNotifier

```dart
class ThemeController extends ChangeNotifier {
  // 1. Estado privado
  ThemeMode _mode = ThemeMode.system;

  // 2. Getter público (somente leitura)
  ThemeMode get mode => _mode;

  // 3. Método para alterar o estado
  void setMode(ThemeMode newMode) {
    if (_mode != newMode) {      // Evita rebuilds desnecessários
      _mode = newMode;
      notifyListeners();         // 🔔 Notifica todos os ouvintes
    }
  }
}
```

**Pontos importantes:**
- O estado `_mode` é **privado** (não pode ser alterado diretamente de fora)
- O getter `mode` permite **ler** o valor atual
- O método `setMode()` é a única forma de **alterar** o estado
- `notifyListeners()` é o que **dispara a reconstrução** dos widgets ouvintes

---

#### Arquivos envolvidos

| Arquivo | Ação |
|---------|------|
| `lib/features/app/theme_controller.dart` | **Criar** — o controlador de tema |
| `lib/features/app/food_safe_app.dart` | **Modificar** — escutar o controller |
| `lib/main.dart` | **Modificar** — criar e passar o controller |
| `lib/features/home/home_page.dart` | **Modificar** — usar o controller no toggle |

---

#### Passo 1: Criar o ThemeController

**Arquivo:** `lib/features/app/theme_controller.dart`

```dart
import 'package:flutter/material.dart';

/// Controlador de tema do aplicativo.
/// 
/// Gerencia o [ThemeMode] atual e notifica ouvintes quando ele muda.
/// Isso permite que o [MaterialApp] reconstrua com o novo tema.
class ThemeController extends ChangeNotifier {
  /// Modo de tema atual. Começa seguindo o sistema.
  ThemeMode _mode = ThemeMode.system;

  /// Retorna o modo de tema atual.
  ThemeMode get mode => _mode;

  /// Retorna true se o modo atual é escuro.
  bool get isDarkMode => _mode == ThemeMode.dark;

  /// Retorna true se o modo atual segue o sistema.
  bool get isSystemMode => _mode == ThemeMode.system;

  /// Altera o modo de tema e notifica os ouvintes.
  /// 
  /// Exemplo:
  /// ```dart
  /// controller.setMode(ThemeMode.dark);
  /// ```
  void setMode(ThemeMode newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      notifyListeners();
    }
  }

  /// Alterna entre claro e escuro.
  /// 
  /// Se estiver em modo sistema, detecta o tema atual e inverte.
  void toggle(Brightness currentBrightness) {
    if (_mode == ThemeMode.system) {
      // Se estava em sistema, vai para o oposto do atual
      _mode = currentBrightness == Brightness.dark 
          ? ThemeMode.light 
          : ThemeMode.dark;
    } else {
      // Alterna entre claro e escuro
      _mode = _mode == ThemeMode.dark 
          ? ThemeMode.light 
          : ThemeMode.dark;
    }
    notifyListeners();
  }
}
```

**Por que assim:**
- `isDarkMode` e `isSystemMode` são helpers para facilitar uso na UI
- `toggle()` é um método conveniente para o `SwitchListTile`
- Documentação com `///` ajuda IDEs e outros desenvolvedores

---

#### Passo 2: Modificar o main.dart

**Arquivo:** `lib/main.dart`

O controller precisa ser **criado antes** do `runApp` e **passado** para o `FoodSafeApp`.

```dart
import 'package:flutter/material.dart';
import 'features/app/food_safe_app.dart';
import 'features/app/theme_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Criar o controlador de tema
  final themeController = ThemeController();
  
  runApp(FoodSafeApp(themeController: themeController));
}
```

**Por que criar no `main()`:**
- O controller deve existir **antes** do `MaterialApp`
- Garante uma única instância (singleton implícito)
- Facilita testes (pode injetar um controller mockado)

---

#### Passo 3: Modificar o FoodSafeApp

**Arquivo:** `lib/features/app/food_safe_app.dart`

O `MaterialApp` precisa **escutar** o controller e **reconstruir** quando o tema mudar.

```dart
import 'package:flutter/material.dart';
import 'theme_controller.dart';
// ... outros imports

class FoodSafeApp extends StatelessWidget {
  final ThemeController themeController;

  const FoodSafeApp({
    super.key,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder reconstrói quando o controller notifica
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, child) {
        return MaterialApp(
          title: 'Food Safe',
          debugShowCheckedModeBanner: false,
          
          // Usa o modo do controller em vez de fixo
          themeMode: themeController.mode,
          
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
            // ... resto do tema claro
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
            // ... resto do tema escuro
          ),
          
          // ... rotas
        );
      },
    );
  }
}
```

**O que é `ListenableBuilder`:**
- Widget que escuta um `Listenable` (como `ChangeNotifier`)
- Quando `notifyListeners()` é chamado, o `builder` é executado novamente
- Isso faz o `MaterialApp` reconstruir com o novo `themeMode`

**Alternativas ao `ListenableBuilder`:**
- `AnimatedBuilder` (mais antigo, mesma funcionalidade)
- `ValueListenableBuilder` (para `ValueNotifier`)
- Packages como `Provider`, `Riverpod`, etc.

---

#### Passo 4: Passar o controller para a HomePage

Precisamos que a `HomePage` tenha acesso ao controller para usar no toggle.

**Opção A — Via construtor (simples):**

```dart
// Em food_safe_app.dart, na definição da rota:
HomePage.routeName: (context) => HomePage(
  title: 'Food Safe',
  themeController: themeController,
),
```

```dart
// Em home_page.dart:
class HomePage extends StatefulWidget {
  final String title;
  final ThemeController themeController;

  const HomePage({
    super.key,
    required this.title,
    required this.themeController,
  });
  
  // ...
}
```

**Opção B — Via InheritedWidget/Provider (escalável):**

Para apps maiores, é melhor usar um `InheritedWidget` ou o package `Provider` para disponibilizar o controller em toda a árvore sem passar por construtores.

---

#### Passo 5: Usar o controller no toggle

**Arquivo:** `lib/features/home/home_page.dart`

Substituir o estado local pelo controller:

```dart
class _HomePageState extends State<HomePage> {
  // Remover: bool _isDarkMode = false;
  // Remover: didChangeDependencies() com setState

  @override
  Widget build(BuildContext context) {
    // Pegar o brightness atual para o toggle
    final brightness = MediaQuery.platformBrightnessOf(context);
    final controller = widget.themeController;
    
    // Calcular se está em modo escuro
    final isDark = controller.mode == ThemeMode.dark ||
        (controller.mode == ThemeMode.system && brightness == Brightness.dark);

    return Scaffold(
      // ...
      drawer: Drawer(
        child: ListView(
          children: [
            // ... outros itens
            
            SwitchListTile(
              secondary: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode_outlined,
              ),
              title: const Text('Tema escuro'),
              subtitle: Text(
                controller.isSystemMode 
                    ? 'Seguindo o sistema' 
                    : (isDark ? 'Ativado' : 'Desativado'),
              ),
              value: isDark,
              onChanged: (value) {
                controller.toggle(brightness);
                // Opcional: fechar o drawer após alternar
                // Navigator.of(context).pop();
              },
            ),
            
            // ... outros itens
          ],
        ),
      ),
    );
  }
}
```

**Por que funciona:**
1. Quando o usuário toca no switch, `controller.toggle()` é chamado
2. O controller atualiza `_mode` e chama `notifyListeners()`
3. O `ListenableBuilder` no `FoodSafeApp` é notificado
4. O `MaterialApp` reconstrói com o novo `themeMode`
5. O tema muda em todo o app!

---

#### Resumo visual do fluxo

```
┌─────────────┐     toggle()      ┌──────────────────┐
│   Usuario   │ ────────────────▶ │  ThemeController │
│ toca switch │                   │  _mode = dark    │
└─────────────┘                   │  notifyListeners │
                                  └────────┬─────────┘
                                           │
                           ┌───────────────┴───────────────┐
                           ▼                               ▼
                  ┌─────────────────┐            ┌─────────────────┐
                  │ ListenableBuilder│            │    HomePage     │
                  │    rebuilds     │            │ isDark = true   │
                  └────────┬────────┘            │ switch atualiza │
                           │                     └─────────────────┘
                           ▼
                  ┌─────────────────┐
                  │   MaterialApp   │
                  │ themeMode: dark │
                  └────────┬────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │   App inteiro   │
                  │  com tema dark  │
                  └─────────────────┘
```

---

#### Exercícios para fixação

1. **Adicionar opção "Seguir sistema":** Criar um terceiro estado no toggle (claro/escuro/sistema) usando um `SegmentedButton` ou menu popup.

2. **Animar a transição:** Envolver o `MaterialApp` em um `AnimatedTheme` para suavizar a mudança de cores.

3. **Debug:** Adicionar um `print()` no `setMode()` para ver quando o tema muda no console.

---

### Etapa 6 — Persistência da preferência de tema

**Objetivo:** Salvar a escolha de tema do usuário para manter entre reinícios do app.

---

#### Por que persistir?

Sem persistência:
- Usuário escolhe "tema escuro" ✅
- Fecha o app
- Abre novamente → volta para "seguir sistema" ❌

Com persistência:
- Usuário escolhe "tema escuro" ✅
- Fecha o app
- Abre novamente → continua em "tema escuro" ✅

---

#### O que é SharedPreferences?

`SharedPreferences` é uma forma simples de armazenar **dados primitivos** (strings, ints, bools, doubles, listas de strings) de forma **persistente** no dispositivo.

| Característica | Descrição |
|----------------|-----------|
| **Tipo de dados** | Primitivos apenas (String, int, double, bool, List<String>) |
| **Persistência** | Sobrevive ao fechamento do app |
| **Segurança** | Não é criptografado (não use para senhas!) |
| **Performance** | Rápido para dados pequenos |
| **Uso típico** | Preferências do usuário, flags, configurações simples |

**Localização dos dados:**
- **iOS:** `NSUserDefaults`
- **Android:** `SharedPreferences` (arquivo XML)
- **Web:** `localStorage`

---

#### Arquivos envolvidos

| Arquivo | Ação |
|---------|------|
| `lib/services/preferences_keys.dart` | **Modificar** — adicionar chave para tema |
| `lib/services/shared_preferences_services.dart` | **Modificar** — adicionar métodos get/set |
| `lib/features/app/theme_controller.dart` | **Modificar** — integrar com persistência |
| `lib/main.dart` | **Modificar** — carregar preferência antes do runApp |

---

### Opção A — Usando o SharedPreferencesService (recomendado se já tiver)

Se você já tem um serviço de preferências como o `SharedPreferencesService`, é melhor seguir o mesmo padrão para manter consistência.

#### Passo 1: Adicionar a chave

**Arquivo:** `lib/services/preferences_keys.dart`

```dart
class PreferencesKeys {
  static const String onboardingCompleted = 'onboarding_completed';
  static const String marketingConsent = 'marketing_consent';
  // ... outras chaves existentes ...
  
  // 👇 Adicionar esta linha
  static const String themeMode = 'theme_mode';
}
```

**Por que usar constantes:**
- Evita erros de digitação (`'theme_mode'` vs `'themeMode'`)
- Centraliza todas as chaves em um lugar
- Facilita renomear ou encontrar usos

---

#### Passo 2: Adicionar métodos no serviço

**Arquivo:** `lib/services/shared_preferences_services.dart`

Adicionar os métodos para salvar e recuperar o tema:

```dart
/// Salva o modo de tema preferido.
/// 
/// Valores aceitos: 'system', 'light', 'dark'
static Future<void> setThemeMode(String mode) async {
  if (_instance == null) {
    await getInstance();
  }
  await _instance!._prefs.setString(PreferencesKeys.themeMode, mode);
}

/// Recupera o modo de tema salvo.
/// 
/// Retorna 'system' se nenhum valor foi salvo.
static Future<String> getThemeMode() async {
  if (_instance == null) {
    await getInstance();
  }
  return _instance!._prefs.getString(PreferencesKeys.themeMode) ?? 'system';
}

/// Remove a preferência de tema (volta para 'system').
static Future<void> removeThemeMode() async {
  if (_instance == null) {
    await getInstance();
  }
  await _instance!._prefs.remove(PreferencesKeys.themeMode);
}
```

**Por que salvar como String:**
- `ThemeMode` é um enum, não pode ser salvo diretamente
- String é mais legível no debug (`'dark'` vs `2`)
- Fácil de entender se inspecionar o armazenamento

---

#### Passo 3: Atualizar o ThemeController

**Arquivo:** `lib/features/app/theme_controller.dart`

```dart
import 'package:flutter/material.dart';
import '../../services/shared_preferences_services.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;
  bool get isDarkMode => _mode == ThemeMode.dark;
  bool get isSystemMode => _mode == ThemeMode.system;

  /// Carrega o tema salvo do armazenamento.
  /// 
  /// Deve ser chamado antes do runApp() no main.dart.
  Future<void> load() async {
    final savedMode = await SharedPreferencesService.getThemeMode();
    _mode = _stringToThemeMode(savedMode);
    // Não chama notifyListeners() aqui pois ainda não há ouvintes
  }

  /// Altera o modo de tema, salva e notifica os ouvintes.
  Future<void> setMode(ThemeMode newMode) async {
    if (_mode != newMode) {
      _mode = newMode;
      await SharedPreferencesService.setThemeMode(_themeModeToString(newMode));
      notifyListeners();
    }
  }

  /// Alterna entre claro e escuro.
  Future<void> toggle(Brightness currentBrightness) async {
    ThemeMode newMode;
    if (_mode == ThemeMode.system) {
      newMode = currentBrightness == Brightness.dark 
          ? ThemeMode.light 
          : ThemeMode.dark;
    } else {
      newMode = _mode == ThemeMode.dark 
          ? ThemeMode.light 
          : ThemeMode.dark;
    }
    await setMode(newMode);
  }

  /// Converte String para ThemeMode.
  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Converte ThemeMode para String.
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
```

**Mudanças importantes:**
- `load()` é `async` e deve ser chamado no `main()`
- `setMode()` agora é `async` pois salva no armazenamento
- `toggle()` também é `async` pois chama `setMode()`
- Métodos auxiliares para converter entre `ThemeMode` e `String`

---

#### Passo 4: Carregar no main.dart

**Arquivo:** `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'features/app/food_safe_app.dart';
import 'features/app/theme_controller.dart';
import 'services/shared_preferences_services.dart';

void main() async {
  // 👇 Necessário para usar async antes do runApp
  WidgetsFlutterBinding.ensureInitialized();
  
  // 👇 Inicializar o serviço de preferências
  await SharedPreferencesService.getInstance();
  
  // 👇 Criar e carregar o controller
  final themeController = ThemeController();
  await themeController.load();
  
  runApp(FoodSafeApp(themeController: themeController));
}
```

**Por que `WidgetsFlutterBinding.ensureInitialized()`:**
- Necessário quando você usa `await` antes do `runApp()`
- Inicializa os bindings do Flutter que são necessários para plugins nativos
- Sem isso, `SharedPreferences.getInstance()` pode falhar

---

#### Passo 5: Ajustar o toggle na HomePage

**Arquivo:** `lib/features/home/home_page.dart`

Como `toggle()` agora é `async`, precisamos ajustar a chamada:

```dart
SwitchListTile(
  secondary: Icon(
    isDark ? Icons.dark_mode : Icons.light_mode_outlined,
  ),
  title: const Text('Tema escuro'),
  subtitle: Text(
    controller.isSystemMode 
        ? 'Seguindo o sistema' 
        : (isDark ? 'Ativado' : 'Desativado'),
  ),
  value: isDark,
  onChanged: (value) async {
    await controller.toggle(brightness);
    // Opcional: fechar o drawer após alternar
    // if (context.mounted) Navigator.of(context).pop();
  },
),
```

**Nota sobre `context.mounted`:**
- Após um `await`, o widget pode ter sido descartado
- `context.mounted` verifica se ainda é seguro usar o context
- Disponível a partir do Flutter 3.7+

---

### Opção B — Usando SharedPreferences diretamente (sem serviço)

Se você não tem um serviço de preferências, pode usar o `SharedPreferences` diretamente no controller.

#### Passo 1: Adicionar dependência

**Arquivo:** `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2  # ou versão mais recente
```

Executar:
```bash
flutter pub get
```

---

#### Passo 2: ThemeController com SharedPreferences direto

**Arquivo:** `lib/features/app/theme_controller.dart`

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  // Chave usada para armazenar o tema
  static const String _themeModeKey = 'theme_mode';
  
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;
  bool get isDarkMode => _mode == ThemeMode.dark;
  bool get isSystemMode => _mode == ThemeMode.system;

  /// Carrega o tema salvo do SharedPreferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themeModeKey) ?? 'system';
    _mode = _stringToThemeMode(savedMode);
  }

  /// Altera o modo de tema, salva e notifica os ouvintes.
  Future<void> setMode(ThemeMode newMode) async {
    if (_mode != newMode) {
      _mode = newMode;
      
      // Salvar no SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, _themeModeToString(newMode));
      
      notifyListeners();
    }
  }

  /// Alterna entre claro e escuro.
  Future<void> toggle(Brightness currentBrightness) async {
    ThemeMode newMode;
    if (_mode == ThemeMode.system) {
      newMode = currentBrightness == Brightness.dark 
          ? ThemeMode.light 
          : ThemeMode.dark;
    } else {
      newMode = _mode == ThemeMode.dark 
          ? ThemeMode.light 
          : ThemeMode.dark;
    }
    await setMode(newMode);
  }

  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
```

---

#### Passo 3: main.dart simplificado

**Arquivo:** `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'features/app/food_safe_app.dart';
import 'features/app/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final themeController = ThemeController();
  await themeController.load();
  
  runApp(FoodSafeApp(themeController: themeController));
}
```

---

### Comparação das abordagens

| Aspecto | Opção A (com serviço) | Opção B (direto) |
|---------|----------------------|------------------|
| **Código** | Mais modular | Mais simples |
| **Reutilização** | Fácil adicionar outras preferências | Cada feature repete código |
| **Testabilidade** | Pode mockar o serviço | Precisa mockar SharedPreferences |
| **Consistência** | Padrão único no projeto | Pode variar entre features |
| **Recomendação** | Apps médios/grandes | Apps pequenos ou protótipos |

---

### Testando a persistência

1. Rodar o app
2. Alternar para tema escuro
3. **Parar o app completamente** (não apenas hot restart)
4. Rodar novamente
5. Verificar se o tema escuro está ativo ✅

**Dica de debug:** Adicionar um print no `load()`:

```dart
Future<void> load() async {
  final savedMode = await SharedPreferencesService.getThemeMode();
  _mode = _stringToThemeMode(savedMode);
  debugPrint('🎨 Tema carregado: $savedMode → $_mode');
}
```

---

### Exercícios para fixação

1. **Adicionar opção de reset:** Criar um botão que chama `removeThemeMode()` e volta para "seguir sistema".

2. **Mostrar feedback:** Exibir um `SnackBar` quando o tema for alterado ("Tema escuro ativado").

3. **Migração:** Se o app já tinha usuários com tema salvo de outra forma, criar lógica de migração no `load()`.

---

## Como testar alternância de tema nos simuladores/emuladores

### iOS Simulator

| Método | Como fazer |
|--------|------------|
| **Atalho rápido** | `⌘ + Shift + A` — alterna instantaneamente entre claro e escuro |
| **Via Ajustes** | Ajustes → Tela e Brilho → escolher Claro ou Escuro |
| **Via Terminal** | `xcrun simctl ui booted appearance dark` ou `light` |

### Android Emulator

| Método | Como fazer |
|--------|------------|
| **Via Configurações** | Configurações → Tela → Tema escuro → ativar/desativar |
| **Quick Settings** | Deslizar de cima para baixo 2x → tocar em "Tema escuro" |
| **Via ADB** | `adb shell "cmd uimode night yes"` ou `no` |
| **Android Studio** | Extended Controls (…) → Settings → Theme |

---

## Notas gerais

- Sempre usar chaves em `if/else`.
- Preferir `super.key` em construtores.
- Usar `dart run` para ferramentas/scripts conforme AGENTS.md.
- Manter constantes privadas em lowerCamelCase com underscore inicial.

---

## Resumo das etapas

| Etapa | O que faz | Complexidade |
|-------|-----------|-------------|
| 1 | Toggle visual (apenas UI) | ⭐ |
| 2 | Sincronizar com tema do sistema | ⭐ |
| 3 | Gerar temas com `fromSeed()` | ⭐⭐ |
| 4 | Criar paletas personalizadas | ⭐⭐ |
| 5 | Gerenciamento de estado (`ChangeNotifier`) | ⭐⭐⭐ |
| 6 | Persistência (`SharedPreferences`) | ⭐⭐⭐ |

---

## Conclusão

Parabéns! 🎉 Você agora tem um sistema completo de temas que:

- ✅ Permite ao usuário alternar entre claro e escuro
- ✅ Segue automaticamente o tema do sistema (se desejado)
- ✅ Usa cores harmoniosas do Material 3
- ✅ Persiste a preferência entre reinícios do app

### Próximos passos sugeridos

1. **Adicionar animação de transição** — Usar `AnimatedTheme` ou `TweenAnimationBuilder` para suavizar a mudança de cores.

2. **Implementar tema dinâmico** — No Android 12+, usar [`dynamic_color`](https://pub.dev/packages/dynamic_color) para extrair cores do wallpaper do usuário.

3. **Criar configurações avançadas** — Permitir escolher entre "Claro", "Escuro" e "Seguir sistema" com um `SegmentedButton` ou `RadioListTile`.

4. **Aplicar em outros elementos** — Criar temas customizados para `AppBar`, `BottomNavigationBar`, `FloatingActionButton`, etc.

5. **Testar acessibilidade** — Usar o [Accessibility Scanner](https://developer.android.com/guide/topics/ui/accessibility/testing) para verificar contraste de cores.

---

## Recursos adicionais

### Documentação oficial
- [Material 3 Design - Color](https://m3.material.io/styles/color/overview)
- [Flutter - Use themes](https://docs.flutter.dev/cookbook/design/themes)
- [ColorScheme class](https://api.flutter.dev/flutter/material/ColorScheme-class.html)

### Ferramentas
- [Material Theme Builder](https://m3.material.io/theme-builder) — Gerar paletas M3
- [Coolors](https://coolors.co/) — Criar paletas harmoniosas
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/) — Verificar acessibilidade

### Packages úteis
- [`dynamic_color`](https://pub.dev/packages/dynamic_color) — Cores dinâmicas do Android 12+
- [`flex_color_scheme`](https://pub.dev/packages/flex_color_scheme) — Temas pré-construídos
- [`adaptive_theme`](https://pub.dev/packages/adaptive_theme) — Gerenciamento de tema simplificado

---

## Créditos

Este material foi elaborado para fins didáticos, com foco em boas práticas e progressão gradual de complexidade.

**Bons estudos!** 🚀
