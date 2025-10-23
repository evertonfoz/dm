Tarefas (to-do)
=================

1. Preparação do repositório
   - [x] Criar pasta `lib/features/onboarding/` para os módulos e telas.  
     (já existe na estrutura do projeto)
   - [x] Criar pasta `assets/images/onboarding/` e copiar os assets listados no prompt.  
     (arquivos copiados de `celilac-life-mobile/.../assets/images/on_boarding`; nomes normalizados)

2. Pubspec
   - [ ] Adicionar assets em `pubspec.yaml` (imagens e lotties).
   - [ ] Adicionar dependências necessárias no `pubspec.yaml`.

3. Implementação das telas
  - [x] `WelcomeScreen` (`/`)
    - Background full-screen e imagem top (~45% height)
    - Título, descrição com `AutoSizeText` e botão primário arredondado
    - Nota: implementado em `lib/features/onboarding/welcome_screen.dart`
   - [x] `PrivacyAndTermsScreen` (`/privacy_and_use_terms/`)
     - Carregar `use_terms_and_privacy.md` com `flutter_markdown`
     - Checkbox "Li e Concordo" para habilitar botão "Continuar"
     - FAB que rola até o final
     - Nota: implementado em `lib/features/onboarding/privacy_and_terms_screen.dart`
   - [x] `ProfileSelectScreen` (`/profile_select/`)
     - Logo e três botões grandes roteando para os destinos corretos
     - Nota: implementado em `lib/features/onboarding/profile_select_screen.dart`
   - [x] `ProviderTypesSelectScreen` (`/provider_types_select/`)
     - Seleção de tipo de provedor com imagem circular sobreposta
   - [x] `ConsumerTypeSensibilitiesScreen` (`/consumer_type_sensibilities/`)
     - Seleção de sensibilidades com imagem circular sobreposta
   - [ ] `LoginScreen` (`/login/`)
     - Campo de e-mail, botão com `AsyncButtonBuilder` e navegação ao dashboard

4. Rotas e navegação
   - [x] Registrar rotas (usar `flutter_modular` ou rotas nomeadas)
     - Nota: as rotas de onboarding são mescladas em `MaterialApp.routes` via `...onboardingRoutes()` no arquivo `lib/features/app/food_safe_app.dart`.
   - [x] Garantir que o fluxo segue: Welcome -> Terms -> ProfileSelect
     - Nota: as telas estão nomeadas e roteadas; Welcome -> PrivacyAndTerms -> ProfileSelect é o fluxo implementado.

5. UI/UX e responsividade
   - [ ] Usar MediaQuery para adaptar telas pequenas (height < 700)
   - [ ] Todos os botões com borderRadius: 40 e elevation: 0
   - [ ] Footer com `AppVersionWidget` em todas as telas

6. Testes e documentação
   - [ ] Criar documento de teste manual com passos para validar o fluxo
   - [ ] Anotar diferenças visuais/adaptações feitas

7. Revisão final
   - [ ] Executar linter e testes existentes
   - [ ] Corrigir problemas de build

Notas
-----
- Marcar nesta lista os itens conforme forem implementados. Mantê-la atualizada ajuda na revisão de PR.