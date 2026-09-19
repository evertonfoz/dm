import 'package:flutter/material.dart';

import '../features/startup/presentation/splash_page.dart';

class CeliLacApp extends StatelessWidget {
  const CeliLacApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CeliLac',
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
    );
  }
}
