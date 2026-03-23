# Documentação Técnica - User Profile Feature

## Visão Geral

Este documento descreve a implementação da feature "User Profile" no projeto LanParty-Planner, um aplicativo Flutter para gerenciamento de eventos de jogos. A feature permite aos usuários gerenciar suas informações pessoais, incluindo nome e e-mail, com foco em privacidade e acessibilidade.

## Estrutura do Projeto

O projeto segue uma arquitetura organizada por features, localizada em `lib/features/`. A feature User Profile está em `lib/features/profile/`.

### Arquivos Principais

- `lib/features/profile/profile_page.dart`: Página principal do perfil do usuário.
- `lib/services/storage_service.dart`: Serviço de armazenamento local usando SharedPreferences.
- `lib/features/home/home_page.dart`: Página inicial com Drawer integrado.

## Implementação Técnica

### StorageService

O `StorageService` gerencia o armazenamento local de dados do usuário usando `SharedPreferences`. Métodos implementados:

- `getUserName()` / `setUserName(String)` / `removeUserName()`: Gerenciamento do nome do usuário.
- `getUserEmail()` / `setUserEmail(String)` / `removeUserEmail()`: Gerenciamento do e-mail do usuário.
- `getConsentMarketing()` / `setConsentMarketing(bool)`: Controle de consentimento para marketing.
- `getConsentAccepted()` / `setConsentAccepted(bool)`: Consentimento geral (legado).

Todos os métodos são assíncronos e retornam `Future`.

### ProfilePage

A `ProfilePage` é um `StatefulWidget` que exibe um formulário para edição de perfil:

- **Formulário**: Usa `Form` com `TextFormField` para nome e e-mail.
- **Validação**: Nome obrigatório, e-mail válido via regex.
- **Acessibilidade**: Labels e hints adequados.
- **Persistência**: Salva dados via `StorageService` ao confirmar.
- **Navegação**: Botão "Salvar" valida e salva, "Cancelar" volta sem salvar.

### Drawer na HomePage

A `HomePage` inclui um `Drawer` lateral:

- **Header**: `UserAccountsDrawerHeader` exibindo nome e e-mail carregados dinamicamente.
- **Itens**:
  - "Editar Perfil": Navega para `ProfilePage`.
  - "Privacidade & Consentimentos": Abre diálogo granular.

### Diálogo de Privacidade

Implementado em `_showPrivacyDialog()` da `HomePage`:

- **Revogação de Marketing**: Sempre revoga (seta `consent_marketing` para false).
- **Apagar Dados Pessoais**: Checkbox opcional para remover `userName` e `userEmail`.
- **Feedback**: Snackbar com mensagem de sucesso.
- **Navegação**: Se dados apagados, redireciona para `OnboardingScreen`.

## Dependências

- `shared_preferences`: Para armazenamento local.
- `flutter/material.dart`: Widgets padrão do Flutter.

## Como Usar

1. **Adicionar à Navegação**: Para acessar `ProfilePage`, use `Navigator.push(MaterialPageRoute(builder: (context) => const ProfilePage()))`.

2. **Gerenciar Dados**: Use `StorageService` para operações CRUD em dados do usuário.

3. **Privacidade**: O diálogo no Drawer permite revogação granular de consentimentos.

## Boas Práticas Implementadas

- **Separação de Concerns**: Serviço dedicado para armazenamento.
- **Acessibilidade**: Formulários com labels e validação clara.
- **Privacidade**: Consentimentos granulares, remoção opcional de dados.
- **Feedback ao Usuário**: Snackbars e navegação adequada.
- **Estado**: Widgets stateful para gerenciar estado local.

## Testes

Para testar:

1. Execute o app e navegue para HomePage.
2. Abra o Drawer (ícone de menu no AppBar).
3. Verifique nome/e-mail no header.
4. Clique em "Editar Perfil" e edite dados.
5. Use "Privacidade & Consentimentos" para testar revogação.

## Futuras Expansões

- Adicionar mais campos de perfil (ex: foto, data de nascimento).
- Integrar com backend para sincronização.
- Expandir consentimentos (ex: notificações, analytics).

## Contato

Para dúvidas, consulte o código fonte ou os arquivos em `prompts/issues/drawer/` para histórico de desenvolvimento.