import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class OnBoardingText extends StatelessWidget {
  const OnBoardingText({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double height;
    if (size.height < 700) {
      height = size.height * 0.19;
    } else if (size.height > 1000) {
      height = size.height * 0.26;
    } else {
      height = size.height * 0.16;
    }
    final textStyleBase =
        Theme.of(context).textTheme.bodyMedium ??
        const TextStyle(fontSize: 18, fontWeight: FontWeight.w400);

    // Use dark text color for the light background image
    // This ensures readability regardless of system theme
    const Color textColor = Color(0xFF424242);

    return SizedBox(
      height: height,
      width: size.width,
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 15),
        child: AutoSizeText(
          'Queremos que você\nconsiga oferecer ou encontrar\nopções '
          'deliciosas e seguras\nde produtos, serviços e lugares\n'
          'para alimentação restrita, principalmente,\nde glúten '
          'e lactose.',
          textAlign: TextAlign.center,
          style: textStyleBase.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: textColor,
          ),
          maxLines: 6,
        ),
      ),
    );
  }
}
