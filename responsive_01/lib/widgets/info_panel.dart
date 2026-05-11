import 'package:flutter/material.dart';

class InfoPanel extends StatelessWidget {
  final String title;
  final String description;

  const InfoPanel({super.key, required this.title, required this.description});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description),
          ],
        ),
      ),
    );
  }
}
