import 'package:flutter/material.dart';

class OnBoardingBackground extends StatelessWidget {
  final String url;

  const OnBoardingBackground({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Image.asset(
      url,
      fit: BoxFit.cover,
      width: size.width,
      height: size.height,
    );
  }
}
