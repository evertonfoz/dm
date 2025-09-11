import 'package:flutter/material.dart';

import '../home/home_page.dart';
import '../onboarding/onboarding_page.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routes: {
        '/': (context) => const SplashScreenPage(),
        OnboardingPage.routeName: (context) => const OnboardingPage(),
        HomePage.routeName: (context) => const HomePage(title: 'Food Safe'),
      },
      // home: const SplashScreenPage(),
    );
  }
}
