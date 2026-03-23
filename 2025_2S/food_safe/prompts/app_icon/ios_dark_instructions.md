# iOS: instruções para suportar App Icon Light/Dark

Este documento descreve passos detalhados e boas práticas para garantir que o App Icon do iOS suporte aparências Light e Dark, usando apenas ferramentas Flutter, um script de merge e o Xcode para validação final.

Pré-requisitos
- `dart` (para executar `dart run flutter_launcher_icons:main`)
- Xcode (para importar e validar o Asset Catalog)
- `jq` (opcional, usado pelo `merge_appiconsets.sh`)

Passos recomendados
1. Prepare duas imagens base em `assets/images/brand/`:
   - `icon_light.png` (recomendado 2048x2048 ou 1024x1024)
   - `icon_dark.png` (mesmas dimensões)

2. Gere a versão Light usando o plugin:
   - No projeto, configure `prompts/app_icon/flutter_launcher_icons.yaml` com `image_path: assets/images/brand/icon_light.png`.
   - Rode: `dart run flutter_launcher_icons:main`.
   - Copie `ios/Runner/Assets.xcassets/AppIcon.appiconset` para `prompts/app_icon/generated_light/`.

3. Gere a versão Dark:
   - Atualize `image_path` para `assets/images/brand/icon_dark.png`.
   - Rode: `dart run flutter_launcher_icons:main`.
   - Copie `ios/Runner/Assets.xcassets/AppIcon.appiconset` para `prompts/app_icon/generated_dark/`.

4. Mescle as duas coleções:
   - Rode: `prompts/app_icon/merge_appiconsets.sh prompts/app_icon/generated_light prompts/app_icon/generated_dark prompts/app_icon/merged_appiconset`
   - Se `jq` estiver instalado, o script criará um `Contents.json` que inclui entradas de `appearances` para as versões dark (com `appearance: luminosity, value: dark`). Caso contrário, ele copia o `Contents.json` do light e adiciona os arquivos dark com sufixo `-dark.png`.

5. Importação final no Xcode:
   - No Xcode, abra `ios/Runner.xcworkspace`.
   - Navegue até `Runner/Assets.xcassets` e substitua o `AppIcon.appiconset` pelo conteúdo de `prompts/app_icon/merged_appiconset/` (ou importe os arquivos manualmente).
   - Selecione o App Icon asset e, no Attributes Inspector, ajuste `Appearances` para `Any, Dark`.
   - Valide que as imagens com sufixo `-dark.png` ou as entradas com `appearances` estão corretamente atribuídas.

6. Teste:
   - Rode o app no simulador ou dispositivo com modo Dark ativado e verifique o ícone.
   - Para App Store e display de ícone na home, use também a build TestFlight para validar em dispositivos reais.

Notas e limitações
- Nem todas as versões de iOS ou launchers respeitam variações automáticas de ícone. Em geral, Asset Catalogs com `Appearances` funcionam nas versões atuais do iOS.
- O `flutter_launcher_icons` não gera automaticamente as entradas `appearances` para AppIcon; por isso fornecemos o script de merge que adiciona essas entradas quando possível.
- Sempre verifique os nomes dos arquivos e backups antes de sobrescrever `ios/Runner/Assets.xcassets/AppIcon.appiconset`.
