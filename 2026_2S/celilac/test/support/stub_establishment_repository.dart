import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/establishments/domain/entities/establishment.dart';
import 'package:celilac/features/establishments/domain/entities/establishment_category.dart';
import 'package:celilac/features/establishments/domain/entities/establishment_details.dart';
import 'package:celilac/features/establishments/domain/entities/establishment_photo.dart';
import 'package:celilac/features/establishments/domain/entities/opening_hours.dart';
import 'package:celilac/features/establishments/domain/entities/safety_practice.dart';
import 'package:celilac/features/establishments/domain/repositories/establishment_repository.dart';

class StubEstablishmentRepository implements EstablishmentRepository {
  StubEstablishmentRepository({
    this.nearbyResults = const [],
    this.detailsResults = const [],
  });

  final List<Future<List<Establishment>> Function()> nearbyResults;
  final List<Future<EstablishmentDetails?> Function()> detailsResults;
  int nearbyCalls = 0;
  int detailsCalls = 0;

  @override
  Future<List<Establishment>> fetchNearby() => nearbyResults[nearbyCalls++]();

  @override
  Future<EstablishmentDetails?> fetchDetails(String establishmentId) =>
      detailsResults[detailsCalls++]();
}

const testCafe = Establishment(
  id: '1',
  name: 'Café Teste',
  category: EstablishmentCategory.cafe,
  neighborhood: 'Centro',
  distanceInKm: 0.35,
  rating: 4.8,
  dietaryOptions: {DietaryOption.glutenFree},
);

final testCafeDetails = EstablishmentDetails(
  establishmentId: '1',
  description: 'Um café de teste.',
  address: 'Rua dos Testes, 10 - Centro',
  phone: '(44) 0000-0000',
  openingHours: [
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
      OpeningHours(
        weekday: weekday,
        opensAt: Duration.zero,
        closesAt: const Duration(hours: 24),
      ),
  ],
  safetyPractices: const {SafetyPractice.exclusiveUtensils},
  photos: const [
    EstablishmentPhoto(
      source: 'assets/images/establishments/cafe_aconchego/photo_1.jpg',
      description: 'Salão de teste',
    ),
    EstablishmentPhoto(
      source: 'assets/images/establishments/cafe_aconchego/photo_2.jpg',
      description: 'Vitrine de teste',
    ),
  ],
);
