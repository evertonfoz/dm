import 'package:flutter/material.dart';
import 'package:pet_care/models/entities/pet_entity.dart';

import 'pet_card.dart';

class PetStatusSection extends StatelessWidget {
  final String title;
  final List<PetEntity> pets;
  final String emptyMessage;

  const PetStatusSection({
    super.key,
    required this.title,
    required this.pets,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title (${pets.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (pets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text(emptyMessage)),
            )
          else
            ...pets.map((pet) => PetCard(key: ValueKey(pet.petId), pet: pet)),
        ],
      ),
    );
  }
}
