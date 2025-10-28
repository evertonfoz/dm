import 'package:flutter/material.dart';

import '../home/home_page.dart';
import '../home/profile_page.dart';
import '../onboarding/onboarding_welcome_page.dart';
import '../onboarding/onboarding_routes.dart';
import '../splashscreen/splashscreen_page.dart';

class FoodSafeApp extends StatelessWidget {
  const FoodSafeApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Safe',
      theme: ThemeData(
        useMaterial3: true,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.standard,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      routes: {
        '/': (context) => const SplashScreenPage(),
        '/onboarding': (context) => const OnBoardingWelcomePage(),
        ...onboardingRoutes(),
        ProfilePage.routeName: (context) => const ProfilePage(),
        HomePage.routeName: (context) => const HomePage(title: 'Food Safe'),
        // onboarding routes are handled by OnboardingPage currently
      },
      // home: const SplashScreenPage(),
    );
  }
}
