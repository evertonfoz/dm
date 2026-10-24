import 'package:celilac/app/celilac_app.dart';
import 'package:celilac/app/shell/app_shell.dart';
import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/onboarding/presentation/onboarding_page.dart';
import 'package:celilac/features/profile/domain/entities/dietary_profile.dart';
import 'package:celilac/features/profile/presentation/profile_scope.dart';
import 'package:celilac/features/startup/presentation/splash_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/memory_profile_repository.dart';

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
  testWidgets('carrega o perfil durante a Splash e abre o app', (tester) async {
    _onboarding(completed: true);
    final repository = MemoryProfileRepository(stored: _ana);

    await tester.pumpWidget(CeliLacApp(profileRepository: repository));
    expect(find.byType(SplashPage), findsOne);
    expect(repository.loadCalls, 1);

    // Animação de entrada + barra de progresso + dados falsos da Home.
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.byType(AppShell), findsOne);
    final context = tester.element(find.byType(AppShell));
    expect(ProfileScope.read(context).profile, _ana);
    expect(repository.loadCalls, 1);

    // Deixa terminar o atraso simulado do FakeEstablishmentRepository.
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('falha ao ler o perfil não impede o app de abrir', (
    tester,
  ) async {
    _onboarding(completed: false);
    final repository = MemoryProfileRepository(failOnLoad: true);

    await tester.pumpWidget(CeliLacApp(profileRepository: repository));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.byType(OnboardingPage), findsOne);
    final context = tester.element(find.byType(OnboardingPage));
    expect(ProfileScope.read(context).profile, DietaryProfile.empty);
  });
}
