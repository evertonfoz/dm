# Registro de Solicitações e Implementações

Este arquivo documenta todas as solicitações feitas ao assistente e as implementações realizadas no projeto LanParty-Planner.

## Solicitações e Ações

1. **Criar pasta "prompts" na raiz do projeto**
   - Criada a pasta `/prompts` no diretório raiz.

2. **Criar pasta "issues" dentro de "prompts" e subpasta "drawer"**
   - Criadas as pastas `/prompts/issues/drawer`.

3. **Criar arquivo "tarefas.md" em `/prompts/issues/drawer/`**
   - Arquivo criado com template para registrar tarefas pendentes.

4. **Identificar serviço de preferências e implementar userName/userEmail no StorageService**
   - Identificado SharedPreferences como serviço.
   - Adicionados métodos `get/set/remove` para `userName` e `userEmail` em `StorageService`, mantendo consentimentos separados.
   - Registrado como tarefa e atualizado progresso.

5. **Criar ProfilePage como nova feature**
   - Criada pasta `/lib/features/profile/`.
   - Implementada `ProfilePage` com formulário acessível (Nome, E-mail), validação simples, aviso de privacidade, botões Salvar/Cancelar.
   - Salvar persiste `userName` e `userEmail` via `StorageService`.
   - Registrado como tarefa e atualizado progresso.

6. **Adicionar Drawer em HomePage**
   - Modificada `HomePage` para Stateful, carregando nome/e-mail.
   - Adicionado Drawer exibindo nome/e-mail, com itens "Editar Perfil" (navega para ProfilePage) e "Privacidade & Consentimentos" (abre diálogo).
   - Registrado como tarefa e atualizado progresso.

7. **Implementar diálogo granular de privacidade**
   - Expandido `StorageService` com métodos para `consent_marketing`.
   - Modificado diálogo para sempre revogar marketing e opcionalmente apagar dados pessoais (remove `userName` e `userEmail`).
   - Feedback via snackbar; se dados apagados, navega para `OnboardingScreen`.
   - Registrado como tarefa e atualizado progresso.

## Arquivos Criados/Modificados

- `/prompts/` (pasta)
- `/prompts/issues/` (pasta)
- `/prompts/issues/drawer/` (pasta)
- `/prompts/issues/drawer/tarefas.md`
- `/prompts/issues/drawer/progresso.md`
- `/lib/features/profile/` (pasta)
- `/lib/features/profile/profile_page.dart`
- `/lib/services/storage_service.dart` (modificado)
- `/lib/features/home/home_page.dart` (modificado)

## Notas Finais

Todas as implementações seguem as melhores práticas de Flutter, com validação, acessibilidade e persistência adequada. O projeto mantém separação por features e usa SharedPreferences para armazenamento local.