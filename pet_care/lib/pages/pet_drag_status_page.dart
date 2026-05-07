import 'package:flutter/material.dart';
import 'package:pet_care/models/entities/pet_entity.dart';
import 'package:pet_care/repositories/pet_mock.dart';

import '../models/entities/pet_attendance_status.dart';
import '../components/pet_drop_area.dart';

class PetDragStatusPage extends StatefulWidget {
  const PetDragStatusPage({super.key});

  @override
  State<PetDragStatusPage> createState() => _PetDragStatusPageState();
}

class _PetDragStatusPageState extends State<PetDragStatusPage> {
  late List<PetEntity> pets;

  @override
  void initState() {
    super.initState();
    pets = List<PetEntity>.from(petMock);
  }

  List<PetEntity> get waitingPets {
    return pets
        .where((pet) => pet.attendanceStatus == PetAttendanceStatus.waiting)
        .toList();
  }

  List<PetEntity> get donePets {
    return pets
        .where((pet) => pet.attendanceStatus == PetAttendanceStatus.done)
        .toList();
  }

  void updatePetStatus(PetEntity selectedPet, PetAttendanceStatus newStatus) {
    setState(() {
      pets = pets.map((pet) {
        if (pet.petId == selectedPet.petId) {
          return pet.copyWith(attendanceStatus: newStatus);
        }
        return pet;
      }).toList();
    });
  }

  void showStatusChangedMessage(PetEntity pet, PetAttendanceStatus status) {
    final message = status == PetAttendanceStatus.done
        ? '${pet.name} foi movido para atendidos.'
        : '${pet.name} voltou para aguardando.';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void handlePetDropped(PetEntity pet, PetAttendanceStatus newStatus) {
    updatePetStatus(pet, newStatus);
    showStatusChangedMessage(pet, newStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mover entre status')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final useVerticalLayout = constraints.maxWidth < 700;

          if (useVerticalLayout) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PetDropArea(
                  title: 'Aguardando atendimento',
                  pets: waitingPets,
                  status: PetAttendanceStatus.waiting,
                  onPetDropped: (pet) {
                    handlePetDropped(pet, PetAttendanceStatus.waiting);
                  },
                ),
                const SizedBox(height: 16),
                PetDropArea(
                  title: 'Atendidos',
                  pets: donePets,
                  status: PetAttendanceStatus.done,
                  onPetDropped: (pet) {
                    handlePetDropped(pet, PetAttendanceStatus.done);
                  },
                ),
              ],
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PetDropArea(
                    title: 'Aguardando atendimento',
                    pets: waitingPets,
                    status: PetAttendanceStatus.waiting,
                    onPetDropped: (pet) {
                      handlePetDropped(pet, PetAttendanceStatus.waiting);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PetDropArea(
                    title: 'Atendidos',
                    pets: donePets,
                    status: PetAttendanceStatus.done,
                    onPetDropped: (pet) {
                      handlePetDropped(pet, PetAttendanceStatus.done);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
