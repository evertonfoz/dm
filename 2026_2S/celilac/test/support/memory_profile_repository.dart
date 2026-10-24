import 'package:celilac/features/profile/domain/entities/dietary_profile.dart';
import 'package:celilac/features/profile/domain/repositories/profile_repository.dart';

class MemoryProfileRepository implements ProfileRepository {
  MemoryProfileRepository({
    this.stored = DietaryProfile.empty,
    this.failOnLoad = false,
    this.failOnSave = false,
  });

  DietaryProfile stored;
  bool failOnLoad;
  bool failOnSave;
  int loadCalls = 0;
  int saveCalls = 0;

  @override
  Future<DietaryProfile> load() async {
    loadCalls++;
    if (failOnLoad) {
      throw Exception('falha ao ler');
    }
    return stored;
  }

  @override
  Future<void> save(DietaryProfile profile) async {
    saveCalls++;
    if (failOnSave) {
      throw Exception('falha ao gravar');
    }
    stored = profile;
  }
}
