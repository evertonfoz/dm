# Plano de execução — Renomear projeto para `celilac_life`

Objetivo: substituir todas as referências ao nome do projeto `food_safe` por `celilac_life` no repositório, garantindo builds Android/iOS/Dart funcionais e mantendo histórico em branch separado.

Resumo do contrato (inputs/outputs):
- Input: repositório atual com nome do projeto `food_safe`.
- Output: repositório com nome e identificadores atualizados para `celilac_life`, builds válidos.
- Critérios de sucesso: `flutter pub get` e um build simples (`flutter build apk`) funcionam; testes básicos passam.
- Erros previstos: conflitos de package name Android/iOS, CI externo (Firebase) requer reconfiguração.

Etapas (ordem recomendada):

1) Preparação
   - Criar uma branch dedicada: `rename/food_safe-to-celilac_life`.
   - Fazer um backup/commit do estado atual.

2) Procurar por referências
   - Usar uma busca global por `food_safe` e `food-safe` (caso existam variantes) para localizar ocorrências em:
     - `pubspec.yaml`, `README.md`, `android/`, `ios/`, `lib/`, `assets/`, `prompts/`, `docs/`, `CI`.
   - Gerar um relatório (opcional): `git grep -n "food_safe\|food-safe" > rename-report.txt`.

3) Atualizar Dart/Flutter
   - `pubspec.yaml`: alterar `name: food_safe` para `name: celilac_life`. Atualizar `description` se necessário.
   - Procurar e substituir `package:food_safe` por `package:celilac_life` nos arquivos `.dart`.

4) Android
   - Atualizar `applicationId` em `android/app/build.gradle.kts` (ou `build.gradle`) para novo reverse domain se desejar (ex: `com.example.celilac_life`).
   - Atualizar `AndroidManifest.xml` (path: `android/app/src/main/AndroidManifest.xml`) se houver menções ao nome ou package.
   - Refatorar o package Java/Kotlin: renomear diretórios sob `android/app/src/main/kotlin/...` ou `java/...` para refletir o novo pacote. Atualizar `package` no topo dos arquivos `.kt`/`.java`.
   - Revisar `gradle.properties` e `local.properties` para chaves relacionadas.

5) iOS
   - Atualizar bundle identifier em Xcode ou diretamente em `ios/Runner.xcodeproj/project.pbxproj` (buscar `PRODUCT_BUNDLE_IDENTIFIER`).
   - Atualizar `CFBundleName`/`Info.plist` se necessário (`ios/Runner/Info.plist`).
   - Verificar e atualizar nomes em `ios/Podfile` e arquivos de configuração relacionados.

6) Assets e strings
   - Atualizar `README.md`, `assets/`, `pubspec` asset paths e qualquer referência textual em `assets/images` ou `onboarding` que contenha o nome antigo.

7) Serviços externos
   - Firebase: substituir `google-services.json` (Android) e `GoogleService-Info.plist` (iOS) se registrou app com novo bundleId/applicationId.
   - Atualizar quaisquer secrets/variáveis de ambiente e pipelines CI (GitHub Actions, Fastlane) que referenciem `food_safe`.

8) Testes e builds
   - Rodar `flutter pub get`.
   - Rodar `flutter clean`.
   - Build local: `flutter build apk` e `flutter build ios` (ou via Xcode simulator).
   - Executar testes: `flutter test`.

9) Revisão e commit
   - Fazer commits claros e atômicos (ex: `chore: rename pubspec and package imports to celilac_life`).
   - Abrir PR para a branch principal com descrição das mudanças e checklist de verificação.

10) Pós-merge
   - Atualizar documentos públicos (README, play store / app store listings), políticas (`prompts/policies/*`) e alterar nomes em plataformas externas (Play Console, App Store Connect).

Checklist de verificação rápida:
- [ ] `pubspec.yaml` com `name: celilac_life`
- [ ] Todos os `package:food_safe` atualizados
- [ ] `applicationId` e bundle id atualizados para Android/iOS
- [ ] Assets e strings verificadas
- [ ] Firebase/CI ajustados
- [ ] Build Android/iOS bem-sucedidos
- [ ] Tests executados

Notas e riscos:
- Mudar package names no Android/iOS pode exigir reorganização de diretórios Kotlin/Java e edição de referências. Essa etapa costuma ser a mais trabalhosa.
- Certifique-se de criar e testar em uma branch separada para permitir reversão fácil.
- Renomeações em histórico Git não são recomendadas; é melhor manter commits e trabalhar em branch novo.

Comandos úteis:

```bash
# Criar branch
git checkout -b rename/food_safe-to-celilac_life

# Buscar ocorrências
git grep -n "food_safe\|food-safe" > rename-report.txt || true

# Substituir (exemplo com ripgrep + perl)
rg -l "food_safe" | xargs -n1 sed -i '' 's/food_safe/celilac_life/g'

# Flutter commands
flutter pub get
flutter clean
flutter build apk
```

---

Se quiser, posso aplicar automaticamente as substituições simples (arquivos de texto, `pubspec.yaml`, imports Dart) em uma branch separada — diga se quer que eu proceda com mudanças automáticas agora ou só gere o plano e os comandos.
