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
                    CircleAvatar(
                      radius: 56,
                      backgroundImage: AssetImage(
                        'assets/images/onboarding/profissional_gastronomico.png',
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
