import 'package:flutter/material.dart';

class HowItWorksOBPage extends StatelessWidget {
  const HowItWorksOBPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/images/onboarding/02.png'),
          ),
          const SizedBox(height: 24),
          Text(
            'Como Funciona o FoodSafe',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Aprenda a usar o aplicativo para garantir a segurança alimentar',
              style: Theme.of(context).textTheme.bodyMedium,
              softWrap: true,
              textAlign: TextAlign.center,
              // overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
