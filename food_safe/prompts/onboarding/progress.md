Progresso de evolução
=====================

Status atual (início):
- Criada pasta `prompts/onboarding` com os arquivos `prompt.md`, `tasks.md` e `progress.md`.
- To-do list principal atualizada para usar `onboarding` (em vez de `on_boarding`).
 - A pasta `lib/features/onboarding/` já existe no projeto; marquei a tarefa correspondente como concluída.

Próximos passos imediatos:
1. Registrar assets no `pubspec.yaml` e copiar os arquivos para `assets/images/onboarding/`.
	- Arquivos copiados de `../celilac-life-mobile/.../assets/images/on_boarding` e normalizados (ex.: `background_on_boarding.png`, `on_boarding_01.png`, `profissional_gastronomico.png`, `sensitivity.png`, `trigo.png`, `image_splashscreen.png`, `background_blue.png`, `background_grey.png`).
2. Adicionar as dependências necessárias no `pubspec.yaml`.
3. Implementar as telas em `lib/features/onboarding/` (Welcome, Privacy & Terms, Profile Select, Provider Types, Consumer Sensibilities, Login).

Notas de bloqueio/assunções:
- Não copiei os assets reais ainda — preciso que os arquivos estejam disponíveis no repositório ou que eu gere placeholders.
- Vou adicionar dependências ao `pubspec.yaml` quando autorizado ou se detectar que é apropriado atualizar o arquivo do projeto.

Registros de alterações:
- [x] Criado `prompts/onboarding/prompt.md`
- [x] Criado `prompts/onboarding/tasks.md`
- [x] Criado `prompts/onboarding/progress.md`
- [x] Atualizei o gerenciador de tarefas para usar `onboarding`

Quando eu avançar, atualizarei este arquivo com commits/resumos de mudanças e resultados de testes de build.