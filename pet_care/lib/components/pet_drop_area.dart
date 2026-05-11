import 'package:flutter/material.dart';
import 'package:pet_care/models/entities/pet_entity.dart';

import '../models/enums/pet_attendance_status_enum.dart';
import 'pet_draggable_card.dart';

class PetDropArea extends StatelessWidget {
  final String title;
  final List<PetEntity> pets;
  final PetAttendanceStatus status;
  final ValueChanged<PetEntity> onPetDropped;

  const PetDropArea({
    super.key,
    required this.title,
    required this.pets,
    required this.status,
    required this.onPetDropped,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<PetEntity>(
      onWillAcceptWithDetails: (details) {
        return details.data.attendanceStatus != status;
      },
      onAcceptWithDetails: (details) {
        onPetDropped(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isReceiving = candidateData.isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(width: isReceiving ? 2 : 1),
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Nenhum atendimento nesta lista.')),
                )
              else
                ...pets.map(
                  (pet) => PetDraggableCard(key: ValueKey(pet.petId), pet: pet),
                ),
            ],
          ),
        );
      },
    );
  }
}
