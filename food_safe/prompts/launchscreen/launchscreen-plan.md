# Plano: Adaptar Launch Screen (splash) para light/dark

Objetivo: configurar a launch screen do aplicativo para suportar modos claro e escuro usando o pacote `flutter_native_splash` (já presente em `pubspec.yaml`) e os assets em `assets/images/splashscreen`.

Contexto:
- Imagens disponíveis:
  - `assets/images/splashscreen/splashscreen_light.png`
  - `assets/images/splashscreen/splashscreen_dark.png`
- O projeto já usa `flutter_native_splash` e possui `flutter_native_splash.yaml` na raiz.

Contrato (inputs/outputs):
- Input: imagens no caminho acima, `flutter_native_splash` listado no `pubspec.yaml`.
- Output: configurações nativas atualizadas para iOS/Android/Web com splash adequado para light e dark modes; documentação do processo.

Passos executáveis:

1) Verificar assets
   - Confirmar existência dos dois arquivos (light/dark) — já verificado.
   - Garantir que `pubspec.yaml` inclua `assets/` (já incluso). Se não, adicionar.

2) Atualizar `flutter_native_splash.yaml`
   - Definir `background_image: "assets/images/splashscreen/splashscreen_light.png"`
   - Definir `background_image_dark: "assets/images/splashscreen/splashscreen_dark.png"`
   - Garantir `android: true`, `ios: true`, `web: true` (mantido).

3) Gerar os arquivos nativos
   - Rodar: `dart run flutter_native_splash:create`
   - Em macOS/Linux: `flutter pub run flutter_native_splash:create` também funciona.

4) Testes rápidos
   - `flutter pub get`
   - `flutter clean`
   - `flutter run` em um emulador Android/iOS e verificar splash em light e dark mode; alternar tema do sistema para confirmar.
   - `flutter build apk` e abrir em dispositivo real (opcional).

5) Ajustes finos
   - Se a imagem precisar ser posicionada, ajustar `ios_content_mode`, `android_gravity` ou `branding` no YAML.
   - Para Android 12+ configure a seção `android_12.image`/`color` se quiser usar o ícone central.

6) Commit e documentação
   - Commitar mudanças no YAML e quaisquer arquivos nativos gerados em uma branch `feature/splash-celilac`.
   - Documentar o resultado em `prompts/launchscreen/launchscreen-execution.md`.

Edge cases / riscos
- Se o `flutter_native_splash` gerar conflitos com mudanças manuais nos arquivos nativos, revise antes de commitar.
- Verifique se dimensões das imagens são adequadas para múltiplas densidades (4x) ou crie variantes para alta resolução.

Comandos úteis

```bash
flutter pub get
dart run flutter_native_splash:create
flutter clean
flutter run
```

---

Se quiser, eu aplico automaticamente a alteração no `flutter_native_splash.yaml` e gero os artefatos nativos (executando `dart run flutter_native_splash:create`). Diga se deseja que eu rode a geração agora.
