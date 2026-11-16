import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/establishments/data/fake_establishment_repository.dart';
import '../features/explore/presentation/explore_controller.dart';
import '../features/favorites/presentation/favorites_controller.dart';
import 'shell/app_shell.dart';

class LabApp extends StatelessWidget {
  const LabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => FavoritesController()),
        ChangeNotifierProvider(
          create: (context) =>
              ExploreController(const FakeEstablishmentRepository()),
        ),
      ],
      child: MaterialApp(
        title: 'Lab Favoritos',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const AppShell(),
      ),
    );
  }
}
