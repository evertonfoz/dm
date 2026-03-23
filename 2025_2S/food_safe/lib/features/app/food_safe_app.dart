// TEMPORÁRIO: Import comentado enquanto usamos rota fixa para login
// import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../theme/color_schemes.dart';

import '../home/home_page.dart';
import '../home/profile_page.dart';
import '../login/presentation/login.dart';
import '../onboarding/onboarding_welcome_page.dart';
import '../onboarding/onboarding_routes.dart';
import '../splashscreen/splashscreen_page.dart';

class FoodSafeApp extends StatelessWidget {
  const FoodSafeApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // TEMPORÁRIO: Rota para visualizar a página de login
    String initialRoute = LoginPage.routeName;
    // TODO: Descomentar a linha abaixo para voltar ao fluxo normal
    // String initialRoute = kDebugMode ? HomePage.routeName : '/';

    // DEBUG: Verificar qual rota está sendo usada
    print('═══════════════════════════════════════════════════════');
    print('Initial Route: $initialRoute');
    print('LoginPage.routeName: ${LoginPage.routeName}');
    print('═══════════════════════════════════════════════════════');

    return MaterialApp(
      title: 'Food Safe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.standard,
        colorScheme: lightColorScheme,
        appBarTheme: AppBarTheme(
          backgroundColor: lightColorScheme.primary,
          // Use a high-contrast foreground for app bar titles.
          // lightColorScheme.onPrimary was white which had poor contrast
          // with the chosen primary color. onSurface provides better
          // contrast without affecting dialog button colors.
          foregroundColor: lightColorScheme.onSurface,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.standard,
        colorScheme: darkColorScheme,
        appBarTheme: AppBarTheme(
          backgroundColor: darkColorScheme.primary,
          // Align dark theme app bar foreground with onSurface for
          // consistent high-contrast titles.
          foregroundColor: darkColorScheme.onSurface,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      themeMode: ThemeMode.system,
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const SplashScreenPage(),
        '/onboarding': (context) => const OnBoardingWelcomePage(),
        ...onboardingRoutes(),
        LoginPage.routeName: (context) => const LoginPage(),
        ProfilePage.routeName: (context) => const ProfilePage(),
        HomePage.routeName: (context) => const HomePage(title: 'Food Safe'),
      },
    );
  }
}
