# Como gerar os ícones (passo-a-passo rápido)

Pré-requisitos:
- Flutter instalado
- dart (vem com Flutter)
- `jq` (opcional, recomendado para merge automático)
- ImageMagick (`convert`) se quiser usar `generate_icons.sh` (opcional)

No zsh:

1) Instale o package (uma vez):

   flutter pub add flutter_launcher_icons --dev
   flutter pub get

2) Gerar versão LIGHT:

   # Aponte para a imagem light no yaml canônico (ou em yaml_to_pubspec)
   sed -i '' 's|image_path: .*|image_path: "assets/images/brand/icon_light.png"|' yaml_to_pubspec/flutter_launcher_icons.yaml
   dart run flutter_launcher_icons:main

   # Copie o appiconset gerado
   mkdir -p prompts/app_icon/generated_light
   cp -r ios/Runner/Assets.xcassets/AppIcon.appiconset prompts/app_icon/generated_light/

3) Gerar versão DARK:

   sed -i '' 's|image_path: .*|image_path: "assets/images/brand/icon_dark.png"|' yaml_to_pubspec/flutter_launcher_icons.yaml
   dart run flutter_launcher_icons:main

   mkdir -p prompts/app_icon/generated_dark
   cp -r ios/Runner/Assets.xcassets/AppIcon.appiconset prompts/app_icon/generated_dark/

4) Mesclar para iOS (gera merged_appiconset):

   chmod +x prompts/app_icon/merge_appiconsets.sh
   prompts/app_icon/merge_appiconsets.sh prompts/app_icon/generated_light/AppIcon.appiconset prompts/app_icon/generated_dark/AppIcon.appiconset prompts/app_icon/merged_appiconset

5) Substituir no Xcode:

   - Abra `ios/Runner.xcworkspace` no Xcode
   - No Finder, arraste o conteúdo de `prompts/app_icon/merged_appiconset` para `Runner/Assets.xcassets` substituindo o `AppIcon.appiconset` existente (faça backup antes)
   - No Xcode, selecione o AppIcon asset e escolha `Appearances: Any, Dark`

6) Teste:

   flutter run -d <simulator-or-device>

Observações:
- Os comandos `sed -i ''` são para macOS/zsh. Se estiver em Linux, use `sed -i` sem `''`.
- Se preferir, edite manualmente `yaml_to_pubspec/flutter_launcher_icons.yaml` para alternar entre `icon_light.png` e `icon_dark.png`.
