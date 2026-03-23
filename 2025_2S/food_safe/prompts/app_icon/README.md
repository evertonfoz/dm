Este diretório contém instruções e scripts úteis para gerar os ícones do aplicativo a partir das imagens em `assets/images/brand`.

Objetivo
- Gerar ícones iOS e Android nas resoluções corretas a partir de dois arquivos de base (light e dark) para suportar modos claro/escuro.

O que este pacote fornece
- `flutter_launcher_icons.yaml` — exemplo de configuração para o package `flutter_launcher_icons` (Flutter) com instruções.
- `generate_icons.sh` — script opcional usando ImageMagick para gerar manualmente os tamanhos para Android e iOS (mipmap e AppIcon.appiconset).
- `FILES.md` — checklist com nomes de arquivos e instruções de integração para Android e iOS.

Pré-requisitos
- Flutter (para executar `flutter pub run flutter_launcher_icons:main` se usar o plugin)
- ImageMagick (`convert` e `mogrify`) para o script `generate_icons.sh` (opcional)
- `jq` (opcional, usado no script para gerar JSON do AppIcon)

Passo-a-passo (rápido)
1. Coloque as imagens base em `assets/images/brand/` com os seguintes nomes:
   - `icon_light.png` — versão para modo claro (recomendado 2048x2048 ou 1024x1024)
   - `icon_dark.png` — versão para modo escuro (mesmas dimensões)

2. Usando o plugin do Flutter (fácil):
   - Abra `prompts/app_icon/flutter_launcher_icons.yaml` e confirme os caminhos.
    - No terminal, rode (uso recomendado de `dart run` para evitar deprecações):

       flutter pub add flutter_launcher_icons --dev
       flutter pub get
       dart run flutter_launcher_icons:main

   O plugin vai escrever os ícones para Android e iOS usando a imagem definida. Se desejar alternar manualmente entre light/dark, veja a seção "Dark/Light strategy" em `FILES.md`.

3. Usando o script manual (ImageMagick):
   - Torne o script executável: `chmod +x prompts/app_icon/generate_icons.sh`
   - Execute: `prompts/app_icon/generate_icons.sh`
   - O script gera `generated_icons/android/` e `generated_icons/ios/AppIcon.appiconset/`.

Dark/Light strategy
- Android: recomenda-se gerar `mipmap` padrão a partir de `icon_light.png` e criar um diretório `mipmap-night` ou `drawable-night` com as variantes dark para dispositivos que respeitam a qualificação de recurso noturno. Nem todos os launchers usam `-night`; outra opção é usar adaptive icons com layers que podem carregar diferentes foreground/background em runtime.

- iOS: use Asset Catalogs (AppIcon.appiconset) e suporte ao "Appearance" para fornecer imagens com variações de Light/Dark (Asset Catalogs suportam diferentes "appearances"). O script gera o `Contents.json` básico. Para ativar a variação, edite o asset no Xcode e adicione as imagens de Dark com a aparência "Dark Appearance".

Fluxo recomendado para iOS usando `dart run` + merge automático
1. Configure `prompts/app_icon/flutter_launcher_icons.yaml` com `image_path: assets/images/brand/icon_light.png`.
2. Rode `dart run flutter_launcher_icons:main` para gerar o AppIcon a partir de `icon_light.png`.
3. Mova a pasta `ios/Runner/Assets.xcassets/AppIcon.appiconset` para `prompts/app_icon/generated_light/` (ou copie).
4. Atualize `image_path` para `assets/images/brand/icon_dark.png` e rode `dart run flutter_launcher_icons:main` novamente.
5. Mova/copie a nova `AppIcon.appiconset` para `prompts/app_icon/generated_dark/`.
6. Rode `prompts/app_icon/merge_appiconsets.sh prompts/app_icon/generated_light prompts/app_icon/generated_dark prompts/app_icon/merged_appiconset` para criar um `Contents.json` combinando as versões light e dark.
7. Substitua `ios/Runner/Assets.xcassets/AppIcon.appiconset` no projeto Xcode pelo diretório `prompts/app_icon/merged_appiconset` gerado.

O script `merge_appiconsets.sh` (fornecido) mescla os arquivos e atualiza o `Contents.json` para incluir as entradas de aparição (Dark) quando um arquivo com sufixo `-dark` existir.

Notas
- Sempre mantenha backup das imagens originais.
- Teste em dispositivos reais e simuladores com modo escuro ativado.

Conteúdo do diretório
- `flutter_launcher_icons.yaml` — arquivo de configuração de exemplo
- `generate_icons.sh` — script ImageMagick
- `FILES.md` — checklist e instruções adicionais
