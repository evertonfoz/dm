import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/profile/data/local_profile_repository.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/profile/presentation/profile_controller.dart';
import '../features/profile/presentation/profile_scope.dart';
import '../features/startup/presentation/splash_page.dart';
import 'theme/app_theme.dart';

class CeliLacApp extends StatefulWidget {
  const CeliLacApp({super.key, this.profileRepository});

  final ProfileRepository? profileRepository;

  @override
  State<CeliLacApp> createState() => _CeliLacAppState();
}

class _CeliLacAppState extends State<CeliLacApp> {
  late final ProfileController _profileController;

  @override
  void initState() {
    super.initState();
    _profileController = ProfileController(
      widget.profileRepository ?? LocalProfileRepository(),
    );
  }

  @override
  void dispose() {
    _profileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Acima do MaterialApp: as rotas empilhadas também enxergam o perfil.
    return ProfileScope(
      controller: _profileController,
      child: MaterialApp(
        title: 'CeliLac',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const SplashPage(),
      ),
    );
  }
}
