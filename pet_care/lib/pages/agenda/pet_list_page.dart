import 'package:flutter/material.dart';
import 'package:pet_care/models/entities/pet_entity.dart';

import '../../components/pet_card.dart';
import '../../components/section_title.dart';
import '../../repositories/pet_mock.dart';
import 'pet_details_page.dart';

class PetListPage extends StatelessWidget {
  const PetListPage({super.key});

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
      appBar: AppBar(title: const Text('PetCare Agenda')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'Atendimentos do dia'),
            ListView.builder(
              itemCount: petMock.length,
              itemBuilder: (context, index) {
                final pet = petMock[index];
                return PetCard(
                  pet: pet,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PetDetailsPage(pet: pet),
                      ),
                    );
                  },
                  onInfoTap: () {
                    _showPetInfoDialog(context, pet);
                  },
                );
              },
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            ),
          ],
        ),
      ),
    );
  }
}
