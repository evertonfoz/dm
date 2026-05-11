import 'package:pet_care/models/enums/pet_attendance_status_enum.dart';

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

  PetEntity copyWith({
    int? petId,
    String? name,
    SpecieEntity? specie,
    int? age,
    String? tutorName,
    String? service,
    bool? isPriority,
    PetAttendanceStatus? attendanceStatus,
  }) {
    return PetEntity(
      petId: petId ?? this.petId,
      name: name ?? this.name,
      specie: specie ?? this.specie,
      age: age ?? this.age,
      tutorName: tutorName ?? this.tutorName,
      service: service ?? this.service,
      isPriority: isPriority ?? this.isPriority,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
    );
  }
}
