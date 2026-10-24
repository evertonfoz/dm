import '../../establishments/domain/entities/establishment.dart';
import 'entities/dietary_profile.dart';

bool meetsProfile(Establishment establishment, DietaryProfile profile) {
  return profile.isComplete &&
      establishment.dietaryOptions.containsAll(profile.restrictions);
}

List<Establishment> sortByProfile(
  List<Establishment> establishments,
  DietaryProfile profile,
) {
  // List.sort não é estável: dois filtros preservam a ordem por distância.
  return [
    ...establishments.where((e) => meetsProfile(e, profile)),
    ...establishments.where((e) => !meetsProfile(e, profile)),
  ];
}
