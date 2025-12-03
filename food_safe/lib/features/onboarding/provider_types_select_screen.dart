// TODOs — Itens necessários do projeto original
// 1) Arquivo de constantes de onboarding (ex.: `on_boarding/constants.dart`) que define:
//    - `kProfessionalImage` (caminho do asset para o avatar)
//    - quaisquer outras constantes visuais usadas nesta página
// 2) Widgets que vinham do projeto original (trazer estes arquivos):
//    - `widgets/header.dart` (ProviderTypeSelectHeader)
//    - `widgets/options.dart` (ProviderTypesOptions)
//    - `widgets/save.dart` (ProviderTypesSaveButton)
// 3) Ícone de voltar compartilhado:
//    - `app_libraries/shared/icons/back_icon.dart` (BackIconToAllPages)
// 4) Esquemas de cores e tema:
//    - `app_libraries/theme/color_schemes.dart` ou `../../theme/color_schemes.dart` com `lightColorScheme`/`darkColorScheme`
// 5) Responsividade / helpers utilizados no original:
//    - Extensões `screenHeight` / `screenWidth` (ex.: do `responsive_builder` ou helpers do projeto). Se não trouxer, adaptaremos para `MediaQuery`.
// 6) Navegação modular (opcional):
//    - `package:flutter_modular/flutter_modular.dart` — se preferir usar o `Modular.to.navigate(...)` como no original,
//      caso contrário substitua por `Navigator.of(context).pushNamed(...)`.
// 7) Assets de imagem usados nos cards (se diferente do `kProfessionalImage`).
// 8) Notas visuais/esperadas:
//    - A página usa um fundo oval grande (`Container` com `borderRadius`) e um avatar circular sobreposto;
//    - Verificar dimensões relativas (`40.screenHeight`, `73.screenHeight`, `100.screenWidth`) e mapear para as extensões originais ou trocar por `MediaQuery`.
// Ação necessária para prosseguir: por favor traga os arquivos listados (1 a 4) ou confirme que quer que eu adapte
// as chamadas `screenHeight/screenWidth` para `MediaQuery` e substituir `Modular.to.navigate` por `Navigator`.

import 'package:flutter/material.dart';

class ProviderTypesSelectScreen extends StatelessWidget {
  static const routeName = '/onboarding/provider_types_select';

  const ProviderTypesSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.height < 700;

    Widget providerCard(String label, String asset, VoidCallback onTap) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(radius: 28, backgroundImage: AssetImage(asset)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tipo de fornecedor')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: isSmall ? 8 : 24),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha((0.08 * 255).round()),
                      ),
                    ),
                    SizedBox(
                      width: 112,
                      height: 112,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/onboarding/profissional_gastronomico.png',
                          fit: BoxFit.cover,
                          // align slightly upwards to favor head placement in the crop
                          alignment: Alignment(0, -0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Selecione o tipo de fornecedor',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              providerCard(
                'Restaurante / Comércio',
                'assets/images/onboarding/profissional_gastronomico.png',
                () {
                  Navigator.of(
                    context,
                  ).pushNamed('/onboarding/consumer_type_sensibilities');
                },
              ),
              const SizedBox(height: 12),
              providerCard(
                'Serviço de catering',
                'assets/images/onboarding/profissional_gastronomico.png',
                () {
                  Navigator.of(
                    context,
                  ).pushNamed('/onboarding/consumer_type_sensibilities');
                },
              ),
              const SizedBox(height: 12),
              providerCard(
                'Indústria / Fornecedor',
                'assets/images/onboarding/profissional_gastronomico.png',
                () {
                  Navigator.of(
                    context,
                  ).pushNamed('/onboarding/consumer_type_sensibilities');
                },
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed('/onboarding/profile_select'),
                  child: const Text('Continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
