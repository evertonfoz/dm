import 'package:pet_care/models/entities/pet_attendance_status.dart';

import '../specie_entity.dart';

class PetEntity {
  final int petId;
  final String name;
  final SpecieEntity specie;
  final int age;
  final String tutorName;
  final String service;
  final bool isPriority;
  final PetAttendanceStatus attendanceStatus;

  const PetEntity({
    required this.petId,
    required this.name,
    required this.specie,
    required this.age,
    required this.tutorName,
    required this.service,
    required this.isPriority,
    required this.attendanceStatus,
  });
}
