import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/profile/data/local_profile_repository.dart';
import 'package:celilac/features/profile/domain/entities/dietary_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _ana = DietaryProfile(
  name: 'Ana',
  restrictions: {DietaryOption.lactoseFree},
);

void main() {
  setUp(() {
    // Troca o armazenamento do aparelho por um mapa em memória.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('sem nada gravado devolve o perfil vazio', () async {
    expect(await LocalProfileRepository().load(), DietaryProfile.empty);
  });

  test('o que foi salvo é lido de volta', () async {
    await LocalProfileRepository().save(_ana);

    // Um repositório novo, como depois de fechar e abrir o app.
    expect(await LocalProfileRepository().load(), _ana);
  });

  test('salvar de novo substitui o perfil anterior', () async {
    final repository = LocalProfileRepository();
    await repository.save(_ana);
    await repository.save(_ana.copyWith(clearName: true));

    expect((await repository.load()).name, isNull);
  });

  test('grava a versão do formato junto com o perfil', () async {
    await LocalProfileRepository().save(_ana);

    final stored = await SharedPreferencesAsync().getString('dietary_profile');
    expect(stored, contains('"schema_version":1'));
  });

  test('texto corrompido devolve o perfil vazio, sem apagar', () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString('dietary_profile', '{isto não é json');

    expect(await LocalProfileRepository().load(), DietaryProfile.empty);
    expect(await preferences.getString('dietary_profile'), '{isto não é json');
  });

  test('JSON que não é um objeto devolve o perfil vazio', () async {
    await SharedPreferencesAsync().setString('dietary_profile', '[1, 2]');

    expect(await LocalProfileRepository().load(), DietaryProfile.empty);
  });
}
