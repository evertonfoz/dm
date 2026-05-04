import 'package:flutter/material.dart';
import 'package:pet_care/components/pet_card.dart';
import 'package:pet_care/repositories/pet_mock.dart';

import '../models/pet_entity.dart';
import 'pet_details_page.dart';

class PetReorderPage extends StatefulWidget {
  const PetReorderPage({super.key});

  @override
  State<PetReorderPage> createState() => _PetReorderPageState();
}

class _PetReorderPageState extends State<PetReorderPage> {
  late final List<PetEntity> pets;

  @override
  void initState() {
    super.initState();
    pets = List.from(petMock);
  }

  void _reorderPets(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final pet = pets.removeAt(oldIndex);
      pets.insert(newIndex, pet);
    });
  }

  void _showPetInfoDialog(BuildContext context, PetEntity pet) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Informações de ${pet.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Espécie: ${pet.specie.name}'),
            Text('Idade: ${pet.age} anos'),
            Text('Serviço: ${pet.service}'),
            Text('Prioritário: ${pet.isPriority ? "Sim" : "Não"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reordenar Atendimentos')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ReorderableListView.builder(
          itemCount: pets.length,
          itemBuilder: (context, index) {
            final pet = pets[index];
            return PetCard(
              key: ValueKey(pet.petId),
              pet: pet,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PetDetailsPage(pet: pet),
                  ),
                );
              },
              onInfoTap: () => _showPetInfoDialog(context, pet),
              // trailing: const Icon(Icons.drag_handle),
            );
          },
          onReorder: _reorderPets,
        ),
      ),
    );
  }
}
