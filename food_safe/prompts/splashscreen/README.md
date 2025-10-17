````markdown
Aula prática — Splashscreen (Handout)

Objetivo

Explicar e demonstrar como implementar uma splashscreen no Flutter que combine com o LaunchScreen nativo, suportando imagens diferentes para light/dark mode e respeitando o tema do app.

Conteúdo
- Conceito e contrato: quando usar uma splashscreen vs LaunchScreen.
- Passos para sincronizar assets e comportamento entre nativo e Flutter.
- Snippet pronto em `snippets/01_splashscreen_page.dart`.

Tópicos didáticos
- Diferença entre LaunchScreen (nativo) e splash dentro de Flutter.
- Como detectar tema (Brightness) e escolher assets correspondentes.
- Boas práticas: tempo mínimo, evitar bloqueios na inicialização, fallback para missing assets.

Teste manual
- flutter run e verificar comportamento em light/dark mode.

````