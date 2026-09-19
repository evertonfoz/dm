import 'package:pet_care/models/entities/pet_attendance_status.dart';

import '../specie_entity.dart';

class PetEntity {
  int? petId;
  final String name;
  SpecieEntity? specie;
  int? age;
  final String tutorName;
  String? service;
  bool? isPriority;
  PetAttendanceStatus? attendanceStatus;

  PetEntity({
    this.petId,
    required this.name,
    this.specie,
    this.age,
    required this.tutorName,
    this.service,
    this.isPriority,
    this.attendanceStatus,
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

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'name': name,
      'specie': specie?.toMap(),
      'age': age,
      'tutorName': tutorName,
      'service': service,
      'isPriority': isPriority,
      'attendanceStatus': attendanceStatus?.toMap(),
    };
  }

  factory PetEntity.fromMap(Map<String, dynamic> map) {
    return PetEntity(
      petId: map['petId'],
      name: map['name'],
      // specie: SpecieEntity.fromMap(map['specie']),
      age: map['age'],
      tutorName: map['tutorName'],
      service: map['service'],
      isPriority: map['isPriority'],
      attendanceStatus: PetAttendanceStatus.done,
      // attendanceStatus: PetAttendanceStatus.fromMap(map['attendanceStatus']),
    );
  }
}
