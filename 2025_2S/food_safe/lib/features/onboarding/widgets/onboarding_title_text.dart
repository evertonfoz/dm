import 'package:flutter/material.dart';

class OnBoardingTitleText extends StatelessWidget {
  const OnBoardingTitleText({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height * 0.04,
      width: size.width,
      child: Text(
        'Uhuu! Que bom que você está aqui!',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: size.width * 0.04,
          color: const Color(0xFF424242),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
