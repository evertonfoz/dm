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
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(40)),
            ),
            // backgroundColor: Theme.of(context).colorScheme.primary, // Ajuste conforme necessário
            // foregroundColor: Theme.of(context).colorScheme.onPrimary, // Ajuste conforme necessário
          ),
          child: Text(
            'Eu também!',
            style: TextStyle(
              fontSize: size.width * 0.04,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
