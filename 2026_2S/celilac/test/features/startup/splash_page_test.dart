import 'package:celilac/app/celilac_app.dart';
import 'package:celilac/app/shell/app_shell.dart';
import 'package:celilac/features/establishments/data/fake_establishment_repository.dart';
import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/favorites/presentation/favorites_controller.dart';
import 'package:celilac/features/onboarding/presentation/onboarding_page.dart';
import 'package:celilac/features/profile/domain/entities/dietary_profile.dart';
import 'package:celilac/features/profile/presentation/profile_controller.dart';
import 'package:celilac/features/startup/presentation/splash_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/memory_favorites_repository.dart';
import '../../support/memory_profile_repository.dart';
import '../../support/stub_establishment_repository.dart';

const _ana = DietaryProfile(
  name: 'Ana',
  restrictions: {DietaryOption.glutenFree},
);

void _onboarding({required bool completed}) {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData({
        if (completed) 'onboarding_completed': true,
      });
}

void main() {
  testWidgets('carrega o perfil e os favoritos durante a Splash e abre o app', (
    tester,
  ) async {
    _onboarding(completed: true);
    final profileRepo = MemoryProfileRepository(stored: _ana);
    final favoritesRepo = MemoryFavoritesRepository(stored: [testCafe]);

    await tester.pumpWidget(
      CeliLacApp(
        profileRepository: profileRepo,
        favoritesRepository: favoritesRepo,
        establishmentRepository: const FakeEstablishmentRepository(),
      ),
    );
    expect(find.byType(SplashPage), findsOne);
    expect(profileRepo.loadCalls, 1);
    expect(favoritesRepo.loadCalls, 1);

    // Animação de entrada + barra de progresso + dados falsos da Home.
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.byType(AppShell), findsOne);
    final context = tester.element(find.byType(AppShell));
    expect(context.read<ProfileController>().profile, _ana);
    expect(context.read<FavoritesController>().favorites, [testCafe]);
    expect(profileRepo.loadCalls, 1);
    expect(favoritesRepo.loadCalls, 1);

    // Deixa terminar o atraso simulado do FakeEstablishmentRepository.
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('falha ao ler o perfil ou os favoritos não impede o app de abrir', (
    tester,
  ) async {
    _onboarding(completed: false);
    final profileRepo = MemoryProfileRepository(failOnLoad: true);
    final favoritesRepo = MemoryFavoritesRepository(failOnLoad: true);

    await tester.pumpWidget(
      CeliLacApp(
        profileRepository: profileRepo,
        favoritesRepository: favoritesRepo,
        establishmentRepository: const FakeEstablishmentRepository(),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.byType(OnboardingPage), findsOne);
    final context = tester.element(find.byType(OnboardingPage));
    expect(context.read<ProfileController>().profile, DietaryProfile.empty);
    expect(context.read<FavoritesController>().favorites, isEmpty);
  });
}
