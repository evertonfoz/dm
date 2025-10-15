Aula prática — Implementando Perfil, Drawer e Gestão de Consentimentos (Handout)

Objetivo

Este README guia os alunos passo-a-passo para reproduzir o trabalho feito no projeto: armazenar nome e e-mail, criar uma rota de edição de perfil, adicionar um Drawer que mostra o estado do usuário, e implementar revogação granular de consentimentos (LGPD). Inclui também snippets prontos para colar.

Estrutura deste handout
- Parte 1 — Contexto e contrato (curto)
- Parte 2 — Passos de implementação (com links para snippets)
- Parte 3 — Testes e comandos úteis
- Parte 4 — Exercícios propostos

Parte 1 — Contexto e contrato

Inputs: nome (string), email (string) via formulário. Outputs: persistência local (SharedPreferences) das chaves `user_name`, `user_email` e chaves de consentimento separadas (marketing). Erros: email inválido; problemas de escrita em prefs.

Parte 2 — Passos (com snippets)

1) Preferências (snippet: `snippets/01_prefs_helper.dart`)
- Adicione as chaves `userName` e `userEmail` em `lib/services/preferences_keys.dart`.
- Exponha helpers em `lib/services/shared_preferences_services.dart`: `setUserName`, `getUserName`, `removeUserName`, `setUserEmail`, `getUserEmail`, `removeUserEmail`.
- Adicione `revokeMarketingConsent()` para revogar consentimento específico.

2) ProfilePage (rota) (snippet: `snippets/02_profile_page.dart`)
- Crie `lib/features/home/profile_page.dart` como rota.
- Form com validação de nome e e-mail, checkbox ou diálogo de privacidade antes de salvar.
- Persistir via `SharedPreferencesService`.

3) Home + Drawer (snippet: `snippets/03_home_drawer.dart`)
- Carregue nome/email em `initState` e exiba no Drawer.
- Itens: Editar perfil (navega para `/profile`), Privacidade & consentimentos (abre diálogo).

4) Diálogo de privacidade (snippet: `snippets/04_privacy_dialog.dart`)
- Diálogo que sempre revoga marketing e opcionalmente apaga dados pessoais locais (nome/email).
- Preserve possibilidade de "Desfazer" via SnackBar.

5) Testes (snippet: `snippets/05_tests.md`)
- Unit: prefs helpers (set/get/remove; revokeMarketingConsent não apaga dados pessoais).
- Widget: ProfilePage (validação e fluxo de salvar).

Parte 3 — Comandos úteis

Rodar todos os testes:

```bash
flutter test
```

Rodar um teste específico:

```bash
flutter test test/profile_page_test.dart
```

Rodar a app:

```bash
flutter run
```

Parte 4 — Exercícios propostos

- Adicionar telefone no perfil (validação). 
- Extrair o diálogo de privacidade para widget e testar isoladamente.
- Implementar page de políticas a partir de `assets/policies`.
- Internacionalizar textos.

---

Arquivos de snippets (prontos em `prompts/homepage/snippets/`) — cole nos lugares indicados no projeto.

Boa aula! Se quiser, monto uma sequência de slides a partir desse README.
