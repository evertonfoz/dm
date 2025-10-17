import 'package:flutter/material.dart';

class WellcomeOBPage extends StatelessWidget {
  const WellcomeOBPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipOval(child: Image.asset('assets/images/onboarding/01.png')),
          // ClipRRect(
          //   borderRadius: BorderRadius.circular(16),
          //   child: Image.asset('assets/images/onboarding/01.png'),
          // ),
          // Container(
          //   decoration: BoxDecoration(
          //     borderRadius: BorderRadius.circular(16),
          //     border: Border.all(color: Colors.black, width: 2),
          //     // boxShadow: [
          //     //   BoxShadow(
          //     //     color: Colors.black.withOpacity(0.1),
          //     //     blurRadius: 8,
          //     //     offset: const Offset(0, 4),
          //     //   ),
          //     // ],
          //   ),
          //   clipBehavior: Clip.antiAlias,
          //   child: Image.asset(
          //     'assets/images/onboarding/01.png',
          //     width: 200,
          //     height: 200,
          //     fit: BoxFit.cover,
          //   ),
          // ),
          const SizedBox(height: 24),
          Text(
            'Bem-vindo(a) ao FoodSafe',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Seu guia para segurança alimentar',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
