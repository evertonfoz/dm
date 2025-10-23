import 'package:flutter/material.dart';

class ProfileSelectScreen extends StatelessWidget {
  static const routeName = '/onboarding/profile_select';

  const ProfileSelectScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 700;

    Widget bigButton(String label, Color color, VoidCallback onTap) {
      return SizedBox(
        width: double.infinity,
        height: isSmall ? 56 : 72,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            elevation: 0,
          ),
          child: Text(label, style: const TextStyle(fontSize: 18)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar Perfil')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: isSmall ? 8 : 24),
              SizedBox(
                height: isSmall ? 80 : 120,
                child: Center(
                  child: Image.asset(
                    'assets/images/onboarding/image_splashscreen.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Como você quer usar o app?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              bigButton(
                'Sou um fornecedor',
                Theme.of(context).colorScheme.primary,
                () {
                  Navigator.of(
                    context,
                  ).pushNamed('/onboarding/provider_types_select');
                },
              ),
              const SizedBox(height: 12),
              bigButton(
                'Sou consumidor',
                Theme.of(context).colorScheme.secondary,
                () {
                  Navigator.of(
                    context,
                  ).pushNamed('/onboarding/consumer_type_sensibilities');
                },
              ),
              const SizedBox(height: 12),
              bigButton(
                'Já tenho conta / Entrar',
                Theme.of(context).colorScheme.surfaceVariant,
                () {
                  Navigator.of(context).pushNamed('/onboarding/login');
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Versão 1.0.0',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
