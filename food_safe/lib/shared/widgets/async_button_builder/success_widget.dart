import 'package:flutter/material.dart';

import '../../../theme/color_schemes.dart';

class SuccessWidgetToAsyncButtonBuilder extends StatelessWidget {
  const SuccessWidgetToAsyncButtonBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check,
            color: darkColorScheme.primary,
            size: 40,
          ),
          const SizedBox(width: 8),
          Text(
            'Pronto!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: darkColorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
