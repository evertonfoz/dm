import '../domain/entities/establishment.dart';
import '../domain/enums/dietary_option.dart';
import '../domain/enums/establishment_category.dart';
import '../domain/repositories/establishment_repository.dart';

class FakeEstablishmentRepository implements EstablishmentRepository {
  const FakeEstablishmentRepository({
    this.delay = const Duration(milliseconds: 800),
  });

  final Duration delay;

  static const _establishments = [
    Establishment(
      establishmentId: '1',
      name: 'Café Aconchego',
      category: EstablishmentCategory.cafe,
      neighborhood: 'Centro',
      rating: 4.8,
      dietaryOptions: {DietaryOption.glutenFree},
      distanceInKm: 1.2,
    ),
    Establishment(
      establishmentId: '2',
      name: 'Padaria Trigo Zero',
      category: EstablishmentCategory.bakery,
      neighborhood: 'Jardim América',
      rating: 4.9,
      dietaryOptions: {DietaryOption.lactoseFree},
      distanceInKm: 2.5,
    ),
    Establishment(
      establishmentId: '3',
      name: 'Bistrô Sem Traço',
      category: EstablishmentCategory.restaurant,
      neighborhood: 'Bela Vista',
      rating: 4.7,
      dietaryOptions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
      distanceInKm: 3.1,
    ),
  ];
  @override
  Future<List<Establishment>> fetchNearby() async {
    await Future.delayed(delay);
    return _establishments;
  }
}
