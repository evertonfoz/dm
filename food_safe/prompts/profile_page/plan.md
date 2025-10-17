```markdown
# Plano de Aula — Profile Page

Objetivos de aprendizagem
- Entender como interagir com `SharedPreferences`.
- Construir formulários com validação e boa UX (feedback, loaders).
- Implementar diálogo de privacidade que bloqueia salvar até aceitação.

Passos rápidos
1. Criar `ProfilePage` (veja snippet em `snippets/02_profile_page.dart`).
2. Registrar rota `/profile` (em `lib/features/app/food_safe_app.dart`).
3. Testar fluxo: abrir Drawer -> Editar perfil -> salvar -> confirmar valores no Drawer.

Critério de aceitação
- Dados persistidos e exibidos ao retornar ao Drawer.
- Validações aplicadas e diálogo de privacidade mostrado quando necessário.

Materiais de apoio
- `lib/services/shared_preferences_services.dart` — API de persistência.
- `prompts/homepage` — handout maior com contexto e exercícios.
```