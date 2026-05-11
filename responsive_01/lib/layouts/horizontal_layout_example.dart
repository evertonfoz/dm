import 'package:flutter/material.dart';
import '../widgets/info_panel.dart';

class HorizontalLayoutExample extends StatelessWidget {
  const HorizontalLayoutExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InfoPanel(title: 'Painel A', description: 'À esquerda.'),
          ),
          SizedBox(width: 16),
          Expanded(
            child: InfoPanel(title: 'Painel B', description: 'À direita.'),
          ),
        ],
      ),
    );
  }
}
