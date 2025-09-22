import 'package:flutter/material.dart';

class DotsIndicator extends StatelessWidget {
  final int totalDots;
  final int currentIndex;

  const DotsIndicator({
    super.key,
    required this.currentIndex,
    required this.totalDots,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDots, (index) {
        final isSelected = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: 12.0,
          height: 12.0,
          decoration: BoxDecoration(
            color: isSelected ? color.primary : color.onSurface,
            shape: BoxShape.circle,
          ),
        );
      }),

      // [
      // Container(
      //   margin: const EdgeInsets.symmetric(horizontal: 4.0),
      //   width: 12.0,
      //   height: 12.0,
      //   decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
      // ),
      // Container(
      //   margin: const EdgeInsets.symmetric(horizontal: 4.0),
      //   width: 12.0,
      //   height: 12.0,
      //   decoration: BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
      // ),
      // Container(
      //   margin: const EdgeInsets.symmetric(horizontal: 4.0),
      //   width: 12.0,
      //   height: 12.0,
      //   decoration: BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
      // ),
      // ],
    );
  }
}
