Checklist de arquivos e integração para ícones (light / dark)

Nomes recomendados (coloque em `assets/images/brand`):
- icon_light.png  (recomendado 2048x2048 ou 1024x1024)
- icon_dark.png   (mesma dimensão)

Android
- Pastas geradas (exemplo):
  - android/mipmap-mdpi/ic_launcher.png (48x48)
  - android/mipmap-hdpi/ic_launcher.png (72x72)
  - android/mipmap-xhdpi/ic_launcher.png (96x96)
  - android/mipmap-xxhdpi/ic_launcher.png (144x144)
  - android/mipmap-xxxhdpi/ic_launcher.png (192x192)

- Para dark mode, você pode criar:
  - android/mipmap-mdpi-night/ic_launcher.png
  - ...

- Melhor prática: usar adaptive icons (foreground/background) e definir cores ou camadas que se adaptam ao tema. O `flutter_launcher_icons` pode gerar adaptive icons se configurado.

iOS
- Asset Catalog: AppIcon.appiconset (o script gera um `Contents.json` e arquivos)
- Para suportar Dark Appearance no Asset Catalog:
  - No Xcode, selecione o AppIcon asset, clique em "Attributes Inspector" e em "Appearances" selecione "Any, Dark".
  - Adicione as imagens escuras nas posições correspondentes. O script gera arquivos com sufixo `-dark.png`, você pode usar esses arquivos.

Observações finais
- Teste em dispositivos reais e simuladores com modo escuro ativado.
- Se preferir usar o plugin `flutter_launcher_icons`, rode duas execuções: uma com `image_path: icon_light.png` e outra com `image_path: icon_dark.png` e mova os arquivos gerados para `mipmap-night` / asset catalog dark slots conforme necessário.

Canonical YAML
- Há um template canônico em `prompts/app_icon/flutter_launcher_icons_canonical.yaml` e uma cópia em `yaml_to_pubspec/flutter_launcher_icons.yaml`.
- Use `dart run flutter_launcher_icons:main` conforme indicado no README para gerar os ícones.

Mesclagem iOS
- Após gerar as versões light e dark, use `prompts/app_icon/merge_appiconsets.sh generated_light generated_dark merged_appiconset` para combinar os AppIcon.appiconset em um único asset catalog com arquivos dark nomeados com `-dark.png` e entradas `appearances` no `Contents.json` quando `jq` estiver disponível.
