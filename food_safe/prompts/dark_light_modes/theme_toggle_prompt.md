# Prompt: Toggle de Tema (claro/escuro)

## Objetivo
Adicionar um toggle de tema claro/escuro no Drawer principal (`HomePage`) e conectá-lo ao `MaterialApp` para aplicar no app inteiro, com opção de persistir via `SharedPreferencesService`.

## Onde olhar antes de codar
- `lib/features/app/food_safe_app.dart`: `themeMode` fixo em `ThemeMode.system` com `lightColorScheme`/`darkColorScheme`.
- `lib/features/home/home_page.dart`: Drawer com header e ListTiles (Editar perfil, Privacidade & consentimentos, Reexibir tutorial, Política de Privacidade). É o lugar ideal para inserir o toggle.
- `lib/services/shared_preferences_services.dart` e `lib/services/preferences_keys.dart`: utilitários de persistência; adicionar uma chave para `themeMode` se decidir salvar a preferência.

## Plano de implementação (quando for executar)
### 1) Adicionar o toggle visual (sem funcionalidade)
- Inserir no Drawer em `lib/features/home/home_page.dart` um `SwitchListTile` rotulado “Tema”/“Tema escuro”, apenas para visualização, sem chamar controlador ou persistência (padrão mobile).
- Posicionamento sugerido: depois do `Divider` e antes de Política de Privacidade.
- Não alterar `ThemeMode` nem conectar nada ainda; é só UI para validar layout.

#### Trechos implementados na etapa 1 (apenas UI)
- Estado local para o switch:
  ```dart
  bool _isDarkMode = false;
  ```
  Por que: manter o switch interativo na UI sem alterar o tema global; é apenas visualização para validar posição/UX.

- Switch no Drawer:
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
Por que: `SwitchListTile` é o padrão de alternância em mobile, ficando logo após o `Divider` para dar contexto antes de “Política de Privacidade”. O `setState` aqui apenas reflete o toggle local, sem alterar `themeMode` global nem persistir dados.

Sugestões para variar o visual de implementação, seguindo boas práticas de UI/UX
- Usar `Switch.adaptive` dentro do `SwitchListTile` para respeitar o estilo iOS/Android nativo.
- Adicionar `subtitle` com texto curto (“Acompanhar tema do sistema” / “Ativar tema escuro”) para reforçar contexto.
- Incluir `secondary` alternando entre `Icons.dark_mode_outlined` e `Icons.light_mode_outlined` conforme o valor, para feedback visual imediato.
- Ajustar `contentPadding` do `SwitchListTile` para alinhar com demais itens do Drawer, mantendo espaçamento consistente.
- Se quiser reduzir ruído visual, usar `ListTile` + `Switch` no `trailing` e `dense: true`, mantendo a hierarquia visual dos demais itens.

### 2) Aplicar o tema do sistema operacional ao iniciar (sem persistência ainda)
- Detectar o tema atual do sistema operacional (claro ou escuro) no momento da inicialização do app.
- Atualizar o estado local `_isDarkMode` do toggle para refletir o tema do sistema, mantendo a UI sincronizada.
- Não alterar `ThemeMode` global ainda; apenas garantir que o switch visual inicie na posição correta conforme o SO.

#### Esclarecimento importante
O app **já responde automaticamente** às mudanças de tema do sistema porque `food_safe_app.dart` está configurado com:
- `theme:` → ThemeData com `lightColorScheme`
- `darkTheme:` → ThemeData com `darkColorScheme`
- `themeMode: ThemeMode.system`

Quando o usuário alterna o tema no simulador/emulador, o Flutter detecta a mudança via `MediaQuery` e dispara um **rebuild** dos widgets que dependem do tema. Não é um hot reload — é o próprio framework reagindo à mudança de configuração do sistema (similar a quando a orientação da tela muda). O `MaterialApp` recebe a nova `platformBrightness` e aplica o `theme` ou `darkTheme` correspondente.

#### Como funciona o rebuild automático de tema
1. O sistema operacional notifica a mudança de `platformBrightness`.
2. O Flutter recebe essa notificação via binding nativo.
3. O `MediaQuery` é atualizado com o novo valor de `Brightness`.
4. O `MaterialApp` (e todos os widgets que dependem do tema) são **rebuilt** automaticamente.
5. O `MaterialApp` escolhe entre `theme` ou `darkTheme` baseado no `themeMode: ThemeMode.system`.

É o mesmo mecanismo que acontece quando você rotaciona o dispositivo — o Flutter detecta a mudança de configuração e reconstrói a árvore de widgets afetada. Isso é muito mais leve que um hot reload completo.

**O objetivo desta etapa** é apenas sincronizar o estado do toggle (`_isDarkMode`) com o tema atual do sistema, para que o switch visual reflita corretamente se o app está em modo claro ou escuro. As etapas seguintes criarão o controle manual para o usuário escolher um tema independente do sistema.

#### Detalhes de implementação
- Usar `WidgetsBinding.instance.platformDispatcher.platformBrightness` ou `MediaQuery.platformBrightnessOf(context)` para obter `Brightness.dark` ou `Brightness.light`.
- No `initState` ou `didChangeDependencies` da `HomePage`, verificar o brightness do sistema e definir `_isDarkMode = brightness == Brightness.dark`.
- Alternativa: usar `SchedulerBinding.instance.platformDispatcher.platformBrightness` se precisar antes do primeiro frame (ex.: em `initState`).

#### Trecho sugerido para a etapa 2
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
Por que: `didChangeDependencies` é chamado após `initState` e sempre que as dependências mudam (ex.: tema do sistema alterado enquanto o app está aberto). Usar `MediaQuery.platformBrightnessOf` é a forma idiomática no Flutter para obter o brightness atual do contexto.

#### Observações
- Se o usuário trocar o tema do sistema enquanto o app está em primeiro plano, o `didChangeDependencies` será chamado novamente e o toggle será atualizado automaticamente.
- Nesta etapa, o toggle ainda é apenas visual; a aplicação do tema no `MaterialApp` virá nas etapas seguintes.

### 3) Controlador de tema
- Criar `lib/features/app/theme_controller.dart` com `ChangeNotifier` guardando `ThemeMode _mode` e getters/setters; inicializa lendo valor salvo ou `system`.
- Expor métodos `load/set` que leem/gravam `SharedPreferencesService` (nova chave em `PreferencesKeys`, ex.: `themeMode = 'theme_mode'`).
- Manter constantes privadas em lowerCamelCase com underscore inicial, conforme AGENTS.md.

### 4) Conectar no root
- Em `main.dart`, antes de `runApp`, inicializar o controller (carregar modo salvo) e passá-lo para `FoodSafeApp`.
- Em `lib/features/app/food_safe_app.dart`, aceitar o controller no construtor; envolver o `MaterialApp` em `AnimatedBuilder`/`ValueListenableBuilder` ligado ao controller para definir `themeMode`; manter os `ThemeData` claro/escuro existentes.

### 5) Toggle no Drawer
- Em `lib/features/home/home_page.dart`, injetar o controller (via parâmetro de construtor ou padrão herdado; mais simples: passar o controller do `FoodSafeApp` para `HomePage` pelas rotas).
- Usar o mesmo `SwitchListTile` para chamar `controller.setMode(ThemeMode.dark)` / `ThemeMode.light` e fechar o Drawer se quiser.

### 6) Persistência opcional
- Salvar `ThemeMode` como string (`'system' | 'light' | 'dark'`) no `SharedPreferencesService` para manter entre reinícios; default em `system` se vazio.
- Nada mais precisa ser persistido.

### 7) Checks para rodar
- `dart analyze`
- `flutter test` (se existir)

## Como testar alternância de tema nos simuladores/emuladores

### iOS Simulator
- **Atalho rápido**: `⌘ + Shift + A` (Command + Shift + A) — alterna instantaneamente entre claro e escuro.
- **Via Ajustes**: Ajustes → Tela e Brilho → escolher Claro ou Escuro.
- **Via Terminal**:
  ```bash
  # Tema escuro
  xcrun simctl ui booted appearance dark
  
  # Tema claro
  xcrun simctl ui booted appearance light
  ```

### Android Emulator
- **Via Configurações**: Configurações → Tela → Tema escuro → ativar/desativar.
- **Quick Settings**: Deslize de cima para baixo duas vezes para abrir o painel de configurações rápidas e tocar no ícone de "Tema escuro" (pode ser necessário editar os quick tiles para adicionar).
- **Via ADB (Terminal)**:
  ```bash
  # Tema escuro
  adb shell "cmd uimode night yes"
  
  # Tema claro
  adb shell "cmd uimode night no"
  ```
- **Atalho no Android Studio**: No painel do emulador (barra lateral), clicar em "..." (Extended Controls) → Settings → Theme → escolher Light ou Dark.

## Notas
- Sempre usar chaves em `if/else`.
- Preferir `super.key` em construtores.
- Usar `dart run` para ferramentas/scripts conforme AGENTS.md.
