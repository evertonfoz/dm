# Documentação Técnica - HomePage Feature

## Visão Geral

Este documento descreve a implementação da HomePage no projeto LanParty-Planner, a tela inicial do aplicativo Flutter para gerenciamento de eventos de jogos. A HomePage serve como hub central, exibindo status de eventos e fornecendo acesso a funcionalidades principais via botões e menu lateral (Drawer).

## Estrutura do Projeto

A HomePage está localizada em `lib/features/home/home_page.dart` e integra outras features do projeto.

### Arquivos Principais

- `lib/features/home/home_page.dart`: Implementação da tela inicial.
- `lib/services/storage_service.dart`: Usado para carregar dados do usuário no Drawer.
- `lib/features/profile/profile_page.dart`: Acessada via Drawer.
- `lib/features/events/event_crud_screen.dart`: Tela de gerenciamento de eventos.
- `lib/features/consent/consent_history_screen.dart`: Tela de histórico de consentimentos.

## Implementação Técnica

### HomePage Widget

A `MyHomePage` é um `StatefulWidget` que gerencia estado local para dados do usuário:

- **Estado**: Carrega `userName` e `userEmail` no `initState` via `StorageService`.
- **Layout**: `Scaffold` com `AppBar`, `Drawer` e `body` centralizado.
- **Body**: `Column` com texto informativo e botões de ação.

### Drawer Lateral

Implementado como propriedade `drawer` do `Scaffold`:

- **Header**: `UserAccountsDrawerHeader` com nome, e-mail e avatar padrão.
- **Itens**: `ListTile` para "Editar Perfil" e "Privacidade & Consentimentos".
- **Navegação**: Push para `ProfilePage` ou abertura de diálogo.

### Diálogo de Privacidade

Método `_showPrivacyDialog()`:

- Usa `StatefulBuilder` para checkbox stateful.
- Sempre revoga marketing (`setConsentMarketing(false)`).
- Opcionalmente apaga dados pessoais (`removeUserName`, `removeUserEmail`).
- Feedback via `SnackBar`.
- Navegação condicional: se dados apagados, `pushReplacement` para `OnboardingScreen`.

### Botões de Ação

Dois `ElevatedButton.icon` no body:

- **Gerenciar Eventos**: Navega para `EventCrudScreen`.
- **Revogar Consentimento**: Navega para `ConsentHistoryScreen` (funcionalidade legada).

## Dependências

- `flutter/material.dart`: Widgets UI.
- `shared_preferences`: Via `StorageService` para dados do usuário.

## Como Usar

1. **Renderização**: A HomePage é a tela inicial definida em `main.dart`.
2. **Interação**: Botões navegam para outras telas; Drawer acessa perfil e privacidade.
3. **Estado**: Dados do usuário são carregados automaticamente.

## Boas Práticas Implementadas

- **Estado Gerenciado**: `StatefulWidget` para dados dinâmicos.
- **Navegação Clara**: `MaterialPageRoute` para transições.
- **Feedback**: Snackbars para ações do usuário.
- **Acessibilidade**: Ícones e textos descritivos.

## Testes

Para testar a HomePage:

1. Execute o app; HomePage deve carregar.
2. Verifique Drawer: nome/e-mail devem aparecer.
3. Teste navegação: "Editar Perfil" abre ProfilePage.
4. Teste privacidade: Diálogo funciona, revoga e opcionalmente apaga dados.
5. Botões: Devem navegar corretamente.

## Futuras Expansões

- Adicionar lista de eventos recentes no body.
- Integrar notificações ou anúncios.
- Expandir Drawer com mais opções (ex: configurações, ajuda).

## Contato

Consulte `prompts/issues/drawer/` para histórico ou o código fonte para detalhes.