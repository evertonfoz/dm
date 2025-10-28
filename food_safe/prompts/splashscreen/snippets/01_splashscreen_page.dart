// Cole em: lib/features/splashscreen/splashscreen_page.dart

import 'package:celilac_life/features/onboarding/onboarding_welcome_page.dart';
import 'package:celilac_life/services/shared_preferences_services.dart';
import 'package:flutter/material.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final marketingConsent =
          await SharedPreferencesService.getMarketingConsent();

      if (marketingConsent == true) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        });
        return;
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnBoardingWelcomePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).colorScheme.brightness;
    final isDark = brightness == Brightness.dark;
    final bg = Theme.of(context).colorScheme.background;
    final imagePath = isDark
        ? 'assets/images/splashscreen/splashscreen_dark.png'
        : 'assets/images/splashscreen/splashscreen_light.png';

    return Container(
      color: bg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, width: 200, height: 200),
          const SizedBox(height: 16),
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: Text(
              'Carregando...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
