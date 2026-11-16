import '../enums/dietary_option.dart';
import '../enums/establishment_category.dart';

class Establishment {
  const Establishment({
    required this.establishmentId,
    required this.name,
    required this.category,
    required this.neighborhood,
    required this.rating,
    required this.dietaryOptions,
    required this.distanceInKm,
  });

  final String establishmentId;
  final String name;
  final EstablishmentCategory category;
  final String neighborhood;
  final double rating;
  final Set<DietaryOption> dietaryOptions;
  final double distanceInKm;
}
