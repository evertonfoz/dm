import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../features/establishments/data/fake_establishment_repository.dart';
import '../features/establishments/domain/repositories/establishment_repository.dart';
import '../features/explore/presentation/explore_controller.dart';
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
    this.establishmentRepository,
  });

  final ProfileRepository? profileRepository;
  final FavoritesRepository? favoritesRepository;
  final EstablishmentRepository? establishmentRepository;

  @override
  Widget build(BuildContext context) {
    // Acima do MaterialApp: as rotas empilhadas também enxergam os
    // controladores, e o ChangeNotifierProvider cuida de criar e descartar.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileController>(
          create: (_) =>
              ProfileController(profileRepository ?? LocalProfileRepository()),
        ),
        ChangeNotifierProvider<FavoritesController>(
          create: (_) => FavoritesController(
            favoritesRepository ?? SqliteFavoritesRepository(),
          ),
        ),
        ChangeNotifierProvider<ExploreController>(
          create: (_) => ExploreController(
            establishmentRepository ?? const FakeEstablishmentRepository(),
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
