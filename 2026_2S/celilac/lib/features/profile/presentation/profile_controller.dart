import 'package:flutter/foundation.dart';

import '../domain/entities/dietary_profile.dart';
import '../domain/repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this._repository);

  final ProfileRepository _repository;

  DietaryProfile _profile = DietaryProfile.empty;
  bool _isLoaded = false;
  Future<void>? _loading;

  DietaryProfile get profile => _profile;
  bool get isLoaded => _isLoaded;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      _profile = await _repository.load();
    } catch (error) {
      // O perfil melhora o app, mas não pode impedir que ele abra.
      debugPrint('Não foi possível carregar o perfil: $error');
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> save(DietaryProfile profile) async {
    await _repository.save(profile);
    _profile = profile;
    _isLoaded = true;
    notifyListeners();
  }
}
