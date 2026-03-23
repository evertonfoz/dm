import 'package:flutter/material.dart';

class OnBoardingBottomButton extends StatelessWidget {
  const OnBoardingBottomButton({super.key});

  double getButtonHeight({required BuildContext buildContext}) {
    final height = MediaQuery.of(buildContext).size.height;
    if (height < 700) {
      return height * 0.07;
    } else if (height > 1000) {
      return height * 0.09;
    } else {
      return height * 0.08;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cs = Theme.of(context).colorScheme;
    // Defensive selection: prefer primaryContainer/onPrimaryContainer for good contrast
    Color buttonBg = cs.primaryContainer;
    Color buttonFg = cs.onPrimaryContainer;
    // If selected bg is essentially very light (close to white), fallback to primary
    try {
      if (buttonBg.computeLuminance() > 0.95) {
        buttonBg = cs.primary;
        buttonFg = cs.onPrimary;
      }
    } catch (_) {}
    // Ensure readable foreground: fall back to black/white if contrast looks poor
    try {
      final lumBg = buttonBg.computeLuminance();
      // choose white on dark bg, black on light bg
      final highContrastFg = lumBg > 0.5 ? Colors.black : Colors.white;
      // If the theme-provided foreground is too close to bg luminance, override
      if ((buttonFg.computeLuminance() - lumBg).abs() < 0.25) {
        buttonFg = highContrastFg;
      }
    } catch (_) {}
    return SizedBox(
      height: getButtonHeight(buildContext: context),
      width: size.width * 0.6,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 32),
        child: ElevatedButton(
          onPressed: () {
            // Corrigido: usar rota nomeada absoluta do projeto
            Navigator.of(
              context,
            ).pushNamed('/onboarding/privacy_and_use_terms');
          },
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(40)),
            ),
            backgroundColor: buttonBg,
            foregroundColor: buttonFg,
            side: BorderSide(
              color: cs.onSurface.withAlpha((0.08 * 255).round()),
            ),
            shadowColor: cs.onSurface.withAlpha((0.06 * 255).round()),
          ),
          child: Text(
            'Eu também!',
            style: TextStyle(
              fontSize: size.width * 0.04,
              fontWeight: FontWeight.bold,
              color: buttonFg,
            ),
          ),
        ),
      ),
    );
  }
}
