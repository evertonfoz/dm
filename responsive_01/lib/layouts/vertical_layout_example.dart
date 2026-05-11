import 'package:flutter/material.dart';
import '../widgets/info_panel.dart';

class VerticalLayoutExample extends StatelessWidget {
  const VerticalLayoutExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      // scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      children: const [
        InfoPanel(title: 'Painel A', description: 'Aparece primeiro.'),
        SizedBox(height: 16),
        InfoPanel(title: 'Painel B', description: 'Aparece abaixo.'),
      ],
    );
  }
}
