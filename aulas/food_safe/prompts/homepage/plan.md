# Plano de Execução — Homepage / Drawer / Perfil

Objetivo: Planejar e definir a implementação do Drawer na `HomePage`, com fluxo de perfil (nome + email), verificação se o usuário está registrado, opção para revogar concessões, conformidade com LGPD e requisitos de acessibilidade.

Resumo curto (contrato):
- Inputs: nome (string), email (string) fornecidos pelo usuário via formulário. Ações do usuário via Drawer (abrir Perfil, Registrar/Editar, Revogar concessões).
- Output: armazenamento local dos dados mínimos (nome, email) e preferências (marketingConsent, privacyPolicyAllRead, termsOfUseAllRead) usando `SharedPreferencesService`.
- Estados de erro: email inválido, armazenamento falhou, usuário cancela; deve mostrar feedback acessível.
- Critérios de sucesso: Drawer integrado, botão Perfil visível, fluxo de registrar/editar funcionando (persistência local), opção de revogação que remove dados e consentimentos, mensagens e links para política de privacidade.

Requisitos e restrições
- Só armazenar o mínimo: `name` e `email`.
- Tratar email como dado pessoal sensível conforme LGPD: apresentar aviso sobre uso e link para a política de privacidade antes de salvar (ou como parte do fluxo de registro).
- Permitir revogação de concessões (marketing) e deleção dos dados locais.
- Acessibilidade: todos os controles devem ter `semanticsLabel`, foco claro, contraste adequado e respostas por SnackBar com `action` e `semanticsLabel` quando aplicável.

Modelo de dados (local):
- Key suggestions em `PreferencesKeys` (ex.: `userName`, `userEmail`) — preferir prefixo `user_`.
- Estrutura local (SharedPreferences)
  - user_name: string
  - user_email: string
  - marketingConsent: bool (já existe)
  - privacyPolicyAllRead: bool (já existe)
  - termsOfUseAllRead: bool (já existe)

Validação
- Nome: não vazio, trim, comprimento máximo (ex.: 100 chars).
- Email: usar `RegExp` simples para validar formato; exigir confirmação de política de privacidade antes de confirmar o registro.

UX / Drawer (comportamento)
- Drawer header: app logo / title e abaixo o estado do usuário:
  - Se usuário registrado: mostrar avatar com iniciais, nome (headline), email (subhead) e botão "Editar Perfil".
  - Se não registrado: mostrar um placeholder e botão "Registrar Perfil".
- Opções do Drawer (ordem recomendada):
  1. Perfil (abrir página/modal de perfil)
  2. Revogar concessões (abre diálogo de confirmação; faz `SharedPreferencesService.removeAll()` ou removals mais específicas)
  3. Política de Privacidade (abre `prompts/policies/privacy_policy.md` ou página interna)
  4. Termos de Uso
  5. Sair / Logout (se houver auth futuro)

Fluxos de UI mínimos
- Abrir Perfil -> Modal/Route `ProfilePage` com campos nome e email e botão Salvar (ou Registrar). Incluir explicação curta sobre por que coletamos os dados e link para política.
- Salvar: validar, então chamar `SharedPreferencesService` para persistir `user_name` e `user_email`.
- Depois de salvar: Drawer atualiza automaticamente (usar `setState`/Provider/ValueNotifier dependendo da arquitetura atual).
- Revogar concessões: ao confirmar, apresentar opção "Desfazer" via SnackBar (como já existe em `home_page.dart`). Após efetivar, redirecionar para onboarding ou tela inicial apropriada.

LGPD e privacidade
- Mostrar texto curto antes de armazenar, por exemplo: "Usamos seu nome e email apenas para personalizar a experiência. Consulte nossa Política de Privacidade." com link.
- Possibilitar ao usuário revogar consentimentos e deletar seus dados locais via Drawer.
- Registro de consentimentos: manter `marketingConsent` como chave separada; revogação deve limpar `user_*` keys também (se for requerido pelo produto).

Acessibilidade (a11y)
- Todos os botões e itens do Drawer devem ter `tooltip` e `semanticLabel`.
- Form fields devem ter `labelText` e `helperText` quando necessário.
- Garantir navegação por teclado/foco: testar with TalkBack/VoiceOver.
- Contraste e tamanho de toque: alvos >= 48x48 dp.

Testes (mínimo)
- Widget test: Drawer mostra estado correto quando `user_name` presente e ausente.
- Unidade: validação de email/nome.
- E2E (opcional): fluxo de registrar -> ver perfil no Drawer -> revogar -> confirmar que dados foram removidos.

Tarefas técnicas (passos de implementação)
1. Criar/atualizar `PreferencesKeys` com `userName` e `userEmail` (nome das chaves). (pequena alteração se necessário)
2. Criar componente `ProfilePage` (ou `ProfileDialog`) responsável por coletar nome/email e exibir texto de LGPD + link para política.
3. Modificar `HomePage` para adicionar `Drawer` conforme wireframe, usar `SharedPreferencesService.get...` para buscar dados e exibir. Atualizar `home_page.dart` UI.
4. Implementar revogação no Drawer apontando para `_revokeMarketingConsent` já presente; adaptar para também remover `user_*` keys.
5. Adicionar testes unitários/widget.
6. Verificação rápida de acessibilidade e ajustes.

Wireframe simples (ASCII):

[Drawer]
-------------------------
| Logo App              |
| John Doe              |
| john@example.com      |
|-----------------------|
| Perfil                |
| Revogar concessões    |
| Política de Privacidade |
| Termos de Uso         |
-------------------------

Considerações e decisões recomendadas
- Armazenamento local com `SharedPreferencesService` é suficiente por agora.
- Preferir um modal para perfil para não criar muitas rotas inicialmente.
- Remover apenas chaves específicas ao revogar, em vez de `removeAll()`, a não ser que o produto exija limpar tudo (evitar limpar outras configurações do usuário sem confirmação).
- Para LGPD, salvar também um registro booleano que o usuário concordou com a política (`privacyPolicyAllRead` já existe) e mostrar facilmente o link para políticas.

Próximos passos imediatos (curto prazo)
- Implementar `PreferencesKeys.userName` e `userEmail` (se não existirem).
- Criar `lib/features/home/profile_page.dart` com formulário acessível.
- Adicionar Drawer à `lib/features/home/home_page.dart` e integrar com `SharedPreferencesService`.
- Criar testes básicos para os fluxos principais.

Referências no repositório
- `lib/services/shared_preferences_services.dart` — para persistência.
- `lib/features/policies/` — contém as políticas já presentes em `assets/policies`.

Aceitação
- Drawer integrado e visível na `HomePage`.
- Perfil editável e persistido localmente (nome+email).
- Revogação de consentimentos com confirmação e opção desfazer.
- Elementos acessíveis e link para política de privacidade.

