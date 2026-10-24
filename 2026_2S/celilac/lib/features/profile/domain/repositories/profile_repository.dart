import '../entities/dietary_profile.dart';

abstract interface class ProfileRepository {
  Future<DietaryProfile> load();

  Future<void> save(DietaryProfile profile);
}
