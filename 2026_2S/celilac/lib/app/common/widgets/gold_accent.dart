import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class GoldAccent extends StatelessWidget {
  final double width;

  const GoldAccent({super.key, this.width = 40.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 3.0,
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(2.0),
      ),
    );
  }
}
