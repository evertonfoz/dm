Objetivo
--------
Adaptar o onboarding do projeto para reproduzir o onboarding do app "CeliLac Life" conforme o design e fluxo deste repositório.

Requisitos detalhados
---------------------
Estrutura/Fluxo (ordem):

1. / (Welcome):
   - Background full-screen com imagem (`background_on_boarding.png`) usando BoxFit.cover.
   - Imagem no topo ocupando aproximadamente 45% da altura da tela (`on_boarding_01.png`).
   - Título central e texto explicativo (usar `AutoSizeText` para blocos longos).
   - Botão principal arredondado (borderRadius: 40) que leva para `/privacy_and_use_terms/`.

2. /privacy_and_use_terms/ (Política & Termos):
   - Carregar `use_terms_and_privacy.md` como Markdown (usar `flutter_markdown`).
   - Usuário deve rolar/ler o conteúdo.
   - Checkbox "Li e Concordo" — somente quando marcado, o botão "Continuar" é habilitado.
   - FAB que rola até o final do conteúdo.

3. /profile_select/ (Escolha de Perfil):
   - Mostrar logo e três botões grandes: "Sou empresa/empreendedor", "Sou consumidor", "Quero conhecer o App antes".
   - Cada botão roteia para:
     - empresa -> /provider_types_select/
     - consumidor -> /consumer_type_sensibilities/
     - conhecer -> navegar direto ao dashboard

4. /provider_types_select/ e /consumer_type_sensibilities/:
   - Telas de seleção com imagem circular sobreposta no topo, formulário/opções e botão "Salvar".

5. /login/ (opcional):
   - Tela de login por e-mail (sem senha).
   - Campo de e-mail centralizado e botão assíncrono que mostra animação de carregamento (ex.: `AsyncButtonBuilder`) e, em sucesso, navega para o dashboard.

Assets a copiar para o projeto
------------------------------
- background_on_boarding.png
- on_boarding_01.png
- image_splashscreen.png
- sensitivity.png
- trigo.png
- profissional_gastronomico.png
- assets/lotties/welcome.json
- use_terms_and_privacy.md

Dependências a garantir (adicionar em `pubspec.yaml`)
------------------------------------------------------
- flutter_modular (ou adaptador de rotas equivalente)
- responsive_builder
- auto_size_text
- async_button_builder
- animated_text_kit
- flutter_keyboard_visibility
- flutter_markdown
- font_awesome_flutter
- lottie (opcional)

 
 Regras de UI/UX e comportamento
 -------------------------------
 - Responsividade: usar proporções de tela (ex.: top image ~45% height). Em telas pequenas (height < 700) adaptar o espaço.
 - Botões principais: usar sempre `borderRadius: 40` e `elevation: 0` (sem sombra), com cores vindas do tema.
 - Cards, ListTiles e componentes de seleção podem usar `borderRadius` menor (ex: 14 ou 16), mantendo visual consistente com Material Design.
 - Background no Welcome: `Image.asset` com `BoxFit.cover`, ocupando 100% width/height.
 - Login: apenas e-mail, texto informando que será enviado um e-mail com instruções.
 - Termos: só permitir avançar quando checkbox marcado.
 - Todas as telas devem mostrar a versão do app no rodapé via `AppVersionWidget`.
 
 **Nota para LLMs:**
 Ao gerar código para onboarding, mantenha o padrão de `borderRadius: 40` e `elevation: 0` nos botões principais (ElevatedButton). Para cards, listas e seletores, valores menores de borderRadius são aceitáveis para preservar a hierarquia visual e a identidade do Material Design.

Regras de rotas
---------------
- Respeitar esquema relativo: rotas internas usam `./privacy_and_use_terms/`, etc.
- Se `flutter_modular` não for usado, usar rotas nomeadas equivalentes.

Critérios de aceitação
----------------------
- Fluxo Welcome → Termos → ProfileSelect navegável e na ordem correta.
- Em Termos: carregue o markdown e desbloqueie o botão somente com o checkbox marcado.
- Em ProfileSelect: cada botão roteia corretamente.
- Login: ao inserir e-mail e apertar Entrar, exibir animação de loading e navegar para dashboard em sucesso.
- Responsividade: validar em telas pequenas (<700px) e grandes (>1000px).
- Assets carregam sem erros.

Observações técnicas
--------------------
- Preserve o nome do scaffold se preferir (p.ex. `CeliLacScaffold`) ou adapte para o scaffold do projeto, mantendo comportamento principal.
- Para o campo de e-mail, manter validação visual e selecionar o texto ao focar.
- Use `AutoSizeText` para blocos longos.

Entregáveis
-----------
- Pasta `onboarding/` com telas implementadas e rotas registradas.
- Assets copiados/registrados no `pubspec.yaml`.
- Teste manual documentado: passos para reproduzir o fluxo.
- Lista de diferenças visuais, se houver adaptações por tema.

Notas finais
-----------
Implemente as telas no módulo do app seguindo as convenções do repositório. Este prompt documenta o que deve ser feito pelo desenvolvedor que implementará o fluxo.