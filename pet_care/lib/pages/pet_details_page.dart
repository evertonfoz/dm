import 'package:flutter/material.dart';

import '../models/entities/pet_entity.dart';

class PetDetailsPage extends StatelessWidget {
  final PetEntity pet;

  const PetDetailsPage({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pet.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nome: ${pet.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Espécie: ${pet.specie.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Idade: ${pet.age} anos',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Serviço: ${pet.service}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.priority_high,
                  color: pet.isPriority ? Colors.red : Colors.green,
                ),
                SizedBox(width: 8),
                Text(
                  pet.isPriority
                      ? 'Atendimento Prioritário'
                      : 'Atendimento Normal',
                  style: TextStyle(
                    color: pet.isPriority ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
