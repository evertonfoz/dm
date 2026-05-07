import 'package:flutter/material.dart';

import 'pet_drag_status_page.dart';
import 'pet_reorder_page.dart';

class PetHomePage extends StatelessWidget {
  const PetHomePage({super.key});

  void openPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PetCare Agenda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.reorder),
              title: const Text('Reorganizar fila'),
              subtitle: const Text('Arraste os cards para alterar a ordem.'),
              onTap: () => openPage(context, const PetReorderPage()),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Mover entre status'),
              subtitle: const Text(
                'Arraste pets entre aguardando e atendidos.',
              ),
              onTap: () => openPage(context, const PetDragStatusPage()),
            ),
          ),
        ],
      ),
    );
  }
}
