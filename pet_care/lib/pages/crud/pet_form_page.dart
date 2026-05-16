import 'package:flutter/material.dart';

class PetFormPage extends StatefulWidget {
  const PetFormPage({super.key});

  @override
  State<PetFormPage> createState() => _PetFormPageState();
}

class _PetFormPageState extends State<PetFormPage> {
  final nameController = TextEditingController();
  final tutorController = TextEditingController();

  void showPetName() {
    final petName = nameController.text;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nome informado'),
          content: Text('O nome digitado foi: $petName'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Pet')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do pet',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tutorController,
              decoration: const InputDecoration(
                labelText: 'Nome do tutor',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: showPetName,
                  child: const Text('Exibir nome digitado'),
                ),
                ElevatedButton(
                  onPressed: () {
                    nameController.clear();
                    tutorController.clear();
                  },
                  child: const Text('Limpar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
