````markdown
Aula prática — Profile Page (Handout)

Objetivo

Este README fornece um passo-a-passo para os alunos implementarem a página de perfil do app: um formulário acessível para nome e e-mail, validações, confirmação de política de privacidade e persistência em SharedPreferences.

Estrutura do material
- Conceito e contrato (inputs/outputs/erros)
- Passos de implementação com snippets prontos para colar
- Testes sugeridos e comandos
- Exercícios pedagógicos

Resumo do contrato
- Inputs: nome (string), email (string), confirmação de leitura da política (boolean).
- Outputs: gravação em SharedPreferences das chaves `user_name`, `user_email`, e `privacyPolicyAllRead`.
- Erros: e-mail inválido, falha de persistência, usuário cancela.

Snippets
- `snippets/02_profile_page.dart` — arquivo completo para colar em `lib/features/home/profile_page.dart`.

Testes e comandos
- flutter test test/profile_page_test.dart
- flutter run

Exercícios
- Adicionar campo telefone com máscara e validação.
- Extrair widget de confirmação de privacidade e testar isoladamente.

````