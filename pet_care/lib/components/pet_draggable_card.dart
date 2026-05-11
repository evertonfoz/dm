import 'package:flutter/material.dart';
import 'package:pet_care/models/entities/pet_entity.dart';

import 'pet_card.dart';

class PetDraggableCard extends StatelessWidget {
  final PetEntity pet;

  const PetDraggableCard({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return LongPressDraggable<PetEntity>(
          data: pet,
          feedback: Material(
            color: Colors.amber,
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: width,
              child: PetCard(pet: pet, trailing: const Icon(Icons.open_with)),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: PetCard(pet: pet, trailing: const Icon(Icons.open_with)),
          ),
          child: PetCard(pet: pet, trailing: const Icon(Icons.open_with)),
        );
      },
    );
  }
}
