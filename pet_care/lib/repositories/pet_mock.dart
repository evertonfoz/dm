import '../models/pet_entity.dart';
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
  ),
  PetEntity(
    petId: 2,
    name: 'Mia',
    specie: SpecieEntity(specieId: '2', name: 'Gato'),
    age: 3,
    service: 'Vacinação',
    isPriority: false,
    tutorName: 'Maria',
  ),
  PetEntity(
    petId: 3,
    name: 'Pipoca',
    specie: SpecieEntity(specieId: '3', name: 'Pássaro'),
    age: 2,
    service: 'Consulta Veterinária',
    isPriority: false,
    tutorName: 'Carlos',
  ),
];
