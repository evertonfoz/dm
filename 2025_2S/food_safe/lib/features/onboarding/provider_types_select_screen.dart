import 'package:flutter/material.dart';
import 'constants.dart';

// TODOs — Itens pendentes do projeto original
// ✅ 1) Arquivo de constantes: RESOLVIDO - usando constants.dart
// ⏳ 2) Widgets que vinham do projeto original (trazer estes arquivos):
//    - widgets/header.dart (ProviderTypeSelectHeader)
//    - widgets/options.dart (ProviderTypesOptions)
//    - widgets/save.dart (ProviderTypesSaveButton)
// ⏳ 3) Ícone de voltar compartilhado:
//    - app_libraries/shared/icons/back_icon.dart (BackIconToAllPages)
// ✅ 4) Esquemas de cores: DISPONÍVEL - usando ../../theme/color_schemes.dart
// ⏳ 5) Responsividade / helpers:
//    - Extensões screenHeight / screenWidth ou adaptar para MediaQuery
// ✅ 6) Navegação: RESOLVIDO - usando Navigator padrão
// ⏳ 7) Assets de imagem: Verificar se há imagens específicas por tipo de fornecedor
// ⏳ 8) Melhorias visuais esperadas:
//    - Fundo oval grande com avatar circular sobreposto (atualmente simplificado)
//    - Verificar dimensões relativas e layout original

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
                          kProfessionalImage,
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
                kProfessionalImage,
                () {
                  Navigator.of(
                    context,
                  ).pushNamed('/onboarding/consumer_type_sensibilities');
                },
              ),
              const SizedBox(height: 12),
              providerCard(
                'Serviço de catering',
                kProfessionalImage,
                () {
                  Navigator.of(
                    context,
                  ).pushNamed('/onboarding/consumer_type_sensibilities');
                },
              ),
              const SizedBox(height: 12),
              providerCard(
                'Indústria / Fornecedor',
                kProfessionalImage,
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
