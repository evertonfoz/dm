import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/celilac_app.dart';
import 'app/config/supabase_config.dart';
import 'features/establishments/data/supabase_establishment_repository.dart';

Future<void> main() async {
  // Necessário antes de qualquer plugin (o Supabase guarda a sessão no aparelho).
  WidgetsFlutterBinding.ensureInitialized();

  final config = SupabaseConfig.fromEnvironment();
  final problems = config.problems;
  if (problems.isNotEmpty) {
    throw StateError(
      'Configuração do Supabase incompleta:\n'
      '- ${problems.join('\n- ')}\n'
      'Rode com: flutter run --dart-define-from-file=supabase.json '
      '(modelo em supabase.example.json).',
    );
  }

  await Supabase.initialize(
    url: config.normalizedUrl,
    publishableKey: config.publishableKey,
  );

  runApp(
    CeliLacApp(
      // A troca do fake pelo Supabase acontece só nesta linha.
      establishmentRepository: SupabaseEstablishmentRepository(
        Supabase.instance.client,
      ),
    ),
  );
}
