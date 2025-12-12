import 'package:flutter/material.dart';
import '../constants.dart';

class LoginImage extends StatelessWidget {
  const LoginImage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.only(
        top: 100,
        left: 20,
        right: 20,
      ),
      child: Image.asset(
        kLoginPageLogo,
        width: size.width,
        height: size.height * 0.4,
        fit: BoxFit.contain,
      ),
    );
  }
}
