import '../models/enums/pet_attendance_status_enum.dart';
import '../models/entities/pet_entity.dart';
import '../models/specie_entity.dart';

const List<PetEntity> petMock = [
  PetEntity(
    petId: 1,
    name: 'Rex',
    specie: SpecieEntity(specieId: '1', name: 'Cachorro'),
    age: 5,
    service: 'Banho e Tosa',
    isPriority: true,
    tutorName: 'João',
    attendanceStatus: PetAttendanceStatus.waiting,
  ),
  PetEntity(
    petId: 2,
    name: 'Mia',
    specie: SpecieEntity(specieId: '2', name: 'Gato'),
    age: 3,
    service: 'Vacinação',
    isPriority: false,
    tutorName: 'Maria',
    attendanceStatus: PetAttendanceStatus.waiting,
  ),
  PetEntity(
    petId: 3,
    name: 'Pipoca',
    specie: SpecieEntity(specieId: '3', name: 'Pássaro'),
    age: 2,
    service: 'Consulta Veterinária',
    isPriority: false,
    tutorName: 'Carlos',
    attendanceStatus: PetAttendanceStatus.done,
  ),
  PetEntity(
    petId: 4,
    name: 'Bolt',
    specie: SpecieEntity(specieId: '1', name: 'Cachorro'),
    age: 4,
    service: 'Banho e Tosa',
    isPriority: true,
    tutorName: 'Ana',
    attendanceStatus: PetAttendanceStatus.done,
  ),
];
