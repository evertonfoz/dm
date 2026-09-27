import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class IllustrationCard extends StatelessWidget {
  const IllustrationCard({
    super.key,
    required this.imagePath,
    required this.boxShaddowAlpha,
    this.width,
    this.height,
    this.padding,
  });

  final String imagePath;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double boxShaddowAlpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: boxShaddowAlpha),
            blurRadius: 32.0,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Image.asset(imagePath),
    );
  }
}
