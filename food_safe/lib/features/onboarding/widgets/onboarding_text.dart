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
    return SizedBox(
      height: height,
      width: size.width,
      child: const Padding(
        padding: EdgeInsets.only(left: 15, right: 15),
        child: AutoSizeText(
          'Queremos que você\nconsiga oferecer ou encontrar\nopções '
          'deliciosas e seguras\nde produtos, serviços e lugares\n'
          'para alimentação restrita, principalmente,\nde glúten '
          'e lactose.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18, // Ajuste conforme necessário
            fontWeight: FontWeight.w400,
          ),
          maxLines: 6,
        ),
      ),
    );
  }
}
