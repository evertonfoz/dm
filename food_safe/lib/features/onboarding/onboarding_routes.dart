import 'package:flutter/widgets.dart';
import 'welcome_screen.dart';
import 'privacy_and_terms_screen.dart';
import 'profile_select_screen.dart';

Map<String, WidgetBuilder> onboardingRoutes() {
  return {
    WelcomeScreen.routeName: (ctx) => const WelcomeScreen(),
    PrivacyAndTermsScreen.routeName: (ctx) => const PrivacyAndTermsScreen(),
    ProfileSelectScreen.routeName: (ctx) => const ProfileSelectScreen(),
  };
}
