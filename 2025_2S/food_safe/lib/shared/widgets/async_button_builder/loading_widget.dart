import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';

import '../../../theme/color_schemes.dart';

class LoadingWidgetToAsyncButtonBuilder extends StatelessWidget {
  final AnimatedTextKit animatedTexts;
  final double fontSize;

  const LoadingWidgetToAsyncButtonBuilder({
    super.key,
    required this.animatedTexts,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              lightColorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        DefaultTextStyle(
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: lightColorScheme.primary,
          ),
          child: animatedTexts,
        ),
      ],
    );
  }
}
