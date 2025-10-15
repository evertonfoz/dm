```markdown
# Lesson — Implementando a ProfilePage (exercício guiado)

1. Revise `SharedPreferencesService` e confirme as chaves disponíveis (`user_name`, `user_email`, `privacyPolicyAllRead`).
2. Cole o snippet `snippets/02_profile_page.dart` em `lib/features/home/profile_page.dart` (ou adapte se já existir).
3. Teste manualmente:
   - Abra o Drawer e selecione "Editar perfil".
   - Preencha nome e e-mail inválidos para ver validação.
   - Marque a caixa de privacidade e salve.
   - Confirme que o Drawer exibe o novo nome e e-mail.

Dicas pedagógicas
- Peça aos alunos para primeiro escreverem testes widget simples antes de implementar (TDD leve): validar que o botão "Salvar" fica desabilitado quando formulário inválido.
- Discuta implicações de LGPD: quando é adequado apagar dados localmente?
```