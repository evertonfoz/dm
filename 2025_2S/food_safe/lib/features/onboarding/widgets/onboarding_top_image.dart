import 'package:flutter/material.dart';

class OnBoardingTopImage extends StatelessWidget {
  final String url;

  const OnBoardingTopImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height * 0.45,
      width: size.width,
      child: Image.asset(url, fit: BoxFit.contain),
    );
  }
}
