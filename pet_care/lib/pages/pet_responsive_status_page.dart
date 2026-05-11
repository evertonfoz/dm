import 'package:flutter/material.dart';
import 'package:pet_care/models/entities/pet_entity.dart';

import '../components/pet_status_section.dart';
import '../models/enums/pet_attendance_status_enum.dart';
import '../repositories/pet_mock.dart';

class PetResponsiveStatusPage extends StatelessWidget {
  const PetResponsiveStatusPage({super.key});

  List<PetEntity> get waitingPets {
    return petMock
        .where((pet) => pet.attendanceStatus == PetAttendanceStatus.waiting)
        .toList();
  }

  List<PetEntity> get donePets {
    return petMock
        .where((pet) => pet.attendanceStatus == PetAttendanceStatus.done)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PetCare Agenda')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final useVerticalLayout = constraints.maxWidth < 700;
          if (useVerticalLayout) {
            return _buildVerticalLayout();
          }
          return Scaffold(
            appBar: AppBar(title: const Text('PetCare Agenda')),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final useVerticalLayout = constraints.maxWidth < 700;
                if (useVerticalLayout) {
                  return _buildVerticalLayout();
                }
                return _buildHorizontalLayout();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerticalLayout() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PetStatusSection(
          title: 'Aguardando atendimento',
          pets: waitingPets,
          emptyMessage: 'Nenhum pet aguardando.',
        ),

        const SizedBox(height: 16),
        PetStatusSection(
          title: 'Atendidos',
          pets: donePets,
          emptyMessage: 'Nenhum pet atendido.',
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: PetStatusSection(
              title: 'Aguardando atendimento',
              pets: waitingPets,
              emptyMessage: 'Nenhum pet.',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: PetStatusSection(
              title: 'Atendidos',
              pets: donePets,
              emptyMessage: 'Nenhum pet.',
            ),
          ),
        ],
      ),
    );
  }
}
