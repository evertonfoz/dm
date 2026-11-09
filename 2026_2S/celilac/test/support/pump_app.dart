import 'package:celilac/app/theme/app_theme.dart';
import 'package:celilac/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:celilac/features/favorites/presentation/favorites_controller.dart';
import 'package:celilac/features/profile/domain/repositories/profile_repository.dart';
import 'package:celilac/features/profile/presentation/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'memory_favorites_repository.dart';
import 'memory_profile_repository.dart';

/// Monta [home] como o app monta: tema, português, perfil e favoritos já carregados.
Future<ProfileController> pumpWithProfile(
  WidgetTester tester,
  Widget home, {
  ProfileRepository? repository,
  FavoritesRepository? favoritesRepository,
  Size size = const Size(360, 800),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final controller = ProfileController(repository ?? MemoryProfileRepository());
  final favoritesController = FavoritesController(
    favoritesRepository ?? MemoryFavoritesRepository(),
  );
  addTearDown(controller.dispose);
  addTearDown(favoritesController.dispose);
  await (controller.load(), favoritesController.load()).wait;

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileController>.value(value: controller),
        ChangeNotifierProvider<FavoritesController>.value(
          value: favoritesController,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  return controller;
}

/// Uma tela mínima com um botão que empilha [page], para testar o voltar.
class PushButtonHost extends StatelessWidget {
  const PushButtonHost({super.key, required this.page});

  final Widget page;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () =>
              Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => page)),
          child: const Text('Abrir'),
        ),
      ),
    );
  }
}
