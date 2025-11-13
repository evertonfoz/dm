import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'privacy_and_terms_screen.dart';

class WelcomeScreen extends StatelessWidget {
  static const routeName = '/onboarding/welcome';

  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallHeight = size.height < 700;
    final topImageHeight = (size.height * 0.45).clamp(200.0, 420.0);

    return Scaffold(
      body: Stack(
        children: [
          // Optional full-screen background image (covers entire scaffold)
          Positioned.fill(
            child: Image.asset(
              'assets/images/onboarding/background_on_boarding.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: topImageHeight,
                  child: Center(
                    child: Image.asset(
                      'assets/images/onboarding/on_boarding_01.png',
                      fit: BoxFit.contain,
                      width: size.width * 0.9,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: AutoSizeText(
                    'Bem-vindo ao FoodSafe',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: AutoSizeText(
                    'Encontre produtos e estabelecimentos compatíveis com suas sensibilidades alimentares. Vamos configurar seu perfil rápido.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: isSmallHeight ? 3 : 4,
                    textAlign: TextAlign.center,
                  ),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pushNamed(PrivacyAndTermsScreen.routeName);
                      },
                      child: const Text('Começar'),
                    ),
                  ),
                ),

                // Footer version
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    'v0.0.0',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
