import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/shared_preferences_services.dart';
import '../onboarding/onboarding_page.dart';

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
        Navigator.of(context).pushReplacementNamed(OnboardingPage.routeName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/splash.png', width: 200, height: 200),
          const CircularProgressIndicator(strokeWidth: 3),
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
