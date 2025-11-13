import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../services/shared_preferences_services.dart';
import '../onboarding/onboarding_welcome_page.dart';

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
      try {
        if (kDebugMode) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
          return;
        }
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
      } catch (e, st) {
        // Log the error in debug so we can see the actual exception when running on web
        if (kDebugMode) {
          // ignore: avoid_print
          print('SplashScreen init error: $e');
          // ignore: avoid_print
          print(st);
        }

        // Fallback navigation to onboarding so the app remains usable
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnBoardingWelcomePage()),
          );
        }
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

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image that covers the whole screen
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(color: bg),
          ),
          // Overlay bottom content (progress + text)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Carregando...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
