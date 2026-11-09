import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../features/favorites/data/sqlite_favorites_repository.dart';
import '../features/favorites/domain/repositories/favorites_repository.dart';
import '../features/favorites/presentation/favorites_controller.dart';
import '../features/profile/data/local_profile_repository.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/profile/presentation/profile_controller.dart';
import '../features/startup/presentation/splash_page.dart';
import 'theme/app_theme.dart';

class CeliLacApp extends StatelessWidget {
  const CeliLacApp({
    super.key,
    this.profileRepository,
    this.favoritesRepository,
  });

  final ProfileRepository? profileRepository;
  final FavoritesRepository? favoritesRepository;

  @override
  Widget build(BuildContext context) {
    // Acima do MaterialApp: as rotas empilhadas também enxergam os
    // controladores, e o ChangeNotifierProvider cuida de criar e descartar.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileController>(
          create: (_) => ProfileController(
            profileRepository ?? LocalProfileRepository(),
          ),
        ),
        ChangeNotifierProvider<FavoritesController>(
          create: (_) => FavoritesController(
            favoritesRepository ?? SqliteFavoritesRepository(),
          ),
        ),
      ],
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
