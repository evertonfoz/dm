import 'package:flutter/material.dart';

import 'widgets/celilac_scaffold.dart';
import 'widgets/profile_select_button.dart';
import '../../theme/color_schemes.dart';
// theme colors accessed via Theme.of(context).colorScheme

class ProfileSelectScreen extends StatelessWidget {
  static const routeName = '/onboarding/profile_select';

  const ProfileSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 700;

    // Using ProfileSelectButton widget for consistent onboarding buttons

    final cs = Theme.of(context).colorScheme;

    return CeliLacScaffold(
      appBar: AppBar(
        title: const Text('Selecionar Perfil'),
        // Keep original dark background as requested
        backgroundColor: darkColorScheme.primary,
        // Use a high-contrast foreground (onSurface) to ensure title and
        // back-arrow are readable against the dark background.
        foregroundColor: darkColorScheme.onSurface,
        iconTheme: IconThemeData(color: darkColorScheme.onSurface),
        elevation: 0,
        centerTitle: true,
      ),
      // Keep the original background color (dark primary)
      backgroundColor: darkColorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              // Centered main block
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 700,
                      // keep the content reasonably sized on taller screens
                      maxHeight: isSmall ? 520 : 620,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        Builder(
                          builder: (ctx) {
                            // Use darkColorScheme.onSurface for guaranteed contrast
                            final textColor = darkColorScheme.onSurface
                                .withOpacity(0.98);
                            return Text(
                              'Como você quer usar o app?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        ProfileSelectButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushNamed('/onboarding/provider_types_select');
                          },
                          text: 'Sou empresa/empreendedor',
                        ),
                        const SizedBox(height: 12),
                        ProfileSelectButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              '/onboarding/consumer_type_sensibilities',
                            );
                          },
                          text: 'Sou consumidor',
                        ),
                        const SizedBox(height: 12),
                        ProfileSelectButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushNamed('/onboarding/login');
                          },
                          text: 'Já tenho conta / Entrar',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Version pinned closer to the bottom with minimal padding
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Builder(
                  builder: (ctx) {
                    final verColor = darkColorScheme.onSurface.withOpacity(
                      0.85,
                    );
                    return Text(
                      'Versão 1.0.0',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        ctx,
                      ).textTheme.bodySmall?.copyWith(color: verColor),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
