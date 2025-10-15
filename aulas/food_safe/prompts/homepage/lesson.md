Aula prática — Implementando perfil, Drawer e gerenciamento de consentimentos (LGPD)

Objetivo

Fornecer aos alunos um roteiro passo-a-passo para implementar um fluxo mínimo (MVP) que inclua:
- Armazenamento local de dados mínimos do usuário (nome e e-mail) usando SharedPreferences.
- Uma rota de edição de perfil (`ProfilePage`) com validação e aviso de privacidade.
- Um `Drawer` na `HomePage` que exibe o nome/e-mail do usuário e oferece ações: Editar perfil e Privacidade & consentimentos.
- Revogação granular: sempre revogar o consentimento de marketing e opcionalmente apagar dados pessoais locais.
- Testes unitários e widget para validar comportamento.

Arquivos produzidos / alterados (referência)
- `lib/services/preferences_keys.dart` — novas chaves: `userName`, `userEmail`.
- `lib/services/shared_preferences_services.dart` — helpers: set/get/remove para userName/userEmail; `revokeMarketingConsent()` e `resetForTests()`.
- `lib/features/home/profile_page.dart` — rota com formulário acessível (Nome, E-mail), validação e aviso de privacidade.
- `lib/features/home/home_page.dart` — adicionado `Drawer` com informações do usuário e diálogo de privacidade/revogação.
- `test/prefs_service_test.dart` — testes unitários para preferences.
- `test/profile_page_test.dart` — testes widget para `ProfilePage`.
- `prompts/homepage/plan.md` — plano de execução e justificativas.
- `prompts/homepage/record.md` — registro didático (pedido original e respostas/decisões).

Pré-requisitos para os alunos
- Ter Flutter instalado e configurado (siga flutter.dev).
- Abrir este projeto no VS Code/Android Studio.
- Certificar-se que `shared_preferences` está listado em `pubspec.yaml` (já está neste projeto).

Passo a passo (5 passos MVP)

1) Chaves e API de Preferências
- Arquivo: `lib/services/preferences_keys.dart`
- Adicione duas chaves:
  - `static const String userName = 'user_name';`
  - `static const String userEmail = 'user_email';`

- Arquivo: `lib/services/shared_preferences_services.dart`
- Exponha helpers síncronos assíncronos (fácil de usar):
  - `setUserName(String)`, `getUserName()`, `removeUserName()`
  - `setUserEmail(String)`, `getUserEmail()`, `removeUserEmail()`
- Mantenha chaves de consentimento separadas (marketing) e evite `removeAll()`.
- Para testes, adicione `resetForTests()` que zera a instância singleton usada pelo serviço.

2) ProfilePage (rota)
- Arquivo: `lib/features/home/profile_page.dart`
- Crie uma `StatefulWidget` com um `Form` contendo:
  - `TextFormField` para Nome (não vazio, <=100 chars)
  - `TextFormField` para E-mail (RegExp simples para validar)
  - Checkbox para aceitar Política de Privacidade e/ou um diálogo de confirmação antes de salvar
  - Botões: Salvar (persiste via `SharedPreferencesService`) e Cancelar (pop)
- Ao salvar com sucesso, chame `SharedPreferencesService.setUserName` e `setUserEmail` e mostre `SnackBar`.
- Use rota (não modal) para manter foco acessível e histórico de navegação.

3) HomePage + Drawer
- Arquivo: `lib/features/home/home_page.dart`
- No `State` carregue nome/e-mail no `initState()` chamando `getUserName()`/`getUserEmail()` e guarde em estado local.
- Adicione `Drawer` com `UserAccountsDrawerHeader` mostrando name/email (ou placeholder se ausente).
- Itens do Drawer:
  - `Editar perfil` → `Navigator.pushNamed(context, '/profile')` e `setState()` após retorno se atualizado.
  - `Privacidade & consentimentos` → abre diálogo (ver passo 4).
  - `Política de Privacidade` → abre rota/asset com o texto da política.

4) Revogação granular e LGPD
- Implemente um diálogo que explique a ação e ofereça:
  - Checkbox/Opção para também apagar dados pessoais locais (nome/e-mail) — opcional.
  - Confirmação final.
- Ao confirmar: sempre chame `revokeMarketingConsent()` para remover a chave de consentimento;
  se o usuário escolheu apagar dados, chame `removeUserName()` e `removeUserEmail()`.
- Mostre um `SnackBar` com ação `Desfazer` que restaura consentimento e (se necessário) os dados pessoais previamente guardados.
- Evite `removeAll()` para não apagar outras preferências do app.

5) Testes essenciais
- `test/prefs_service_test.dart` (unit):
  - Teste set/get/remove de userName/userEmail.
  - Teste que `revokeMarketingConsent()` não remove userName/userEmail.
- `test/profile_page_test.dart` (widget):
  - Teste fluxo de salvar: preencher campos, marcar checkbox, salvar -> verificar `SharedPreferencesService.getUserName()`/`getUserEmail()`.
  - Teste tentativa de salvar com campos vazios não persiste dados.
- Use `SharedPreferences.setMockInitialValues({})` para mocks nos testes e limpe o singleton com `SharedPreferencesService.resetForTests()` entre testes.

Comandos úteis (para alunos)

- Rodar todos os testes:

```bash
flutter test
```

- Rodar um teste específico:

```bash
flutter test test/profile_page_test.dart
```

- Rodar a app em um emulador/dispositivo:

```bash
flutter run
```

Exercícios propostos (para sala)

1) Extensão de campos: Adicione um campo `telefone` (mínimo e máximo) e valide o formato.
2) Mover o diálogo de privacidade para um widget separado e escrever testes unitários para ele.
3) Implementar uma página de políticas com o conteúdo de `assets/policies/privacy_policy.md` e abrir a partir do Drawer.
4) Internacionalização: extrair textos para `arb`/localization e adicionar inglês.
5) Acessibilidade profunda: rodar `flutter a11y` ou usar ferramentas do Android/iOS para checar foco, descrições e navegação por teclado.

Material de referência / leitura
- `lib/services/shared_preferences_services.dart` (exemplo de wrappers para SharedPreferences)
- `lib/features/home/profile_page.dart` (exemplo de formulário acessível)
- `lib/features/home/home_page.dart` (exemplo de Drawer e diálogo de privacidade)
- `prompts/homepage/plan.md` e `prompts/homepage/record.md` — plano e registro didático

Como usar em aula (sugestão de roteiro 90 minutos)
- 0–10 min: Apresentação do objetivo e LGPD (breve)
- 10–20 min: Mostrar `plan.md` e dividir tarefas
- 20–50 min: Hands-on — implementar chaves e `SharedPreferencesService` helpers
- 50–80 min: Hands-on — criar `ProfilePage` e integrar Drawer
- 80–90 min: Testes e revisão (executar `flutter test`)

---

Esse arquivo é um handout. Posso também gerar um `README` pronto para o repositório ou um `lesson.pdf` se preferir. Deseja que eu:

A) Gere um `prompts/homepage/lesson.pdf` (requererá conversão local que não posso executar aqui — eu posso gerar markdown e instruções para converter);
B) Gere um `prompts/homepage/README.md` com instruções topo-a-botton para incluir no repositório; ou
C) Crie snippets prontos para colar no editor (um por etapa) e um roteiro passo-a-passo mais detalhado para cada exercício.
