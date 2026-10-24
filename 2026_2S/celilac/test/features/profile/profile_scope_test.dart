import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/profile/domain/entities/dietary_profile.dart';
import 'package:celilac/features/profile/presentation/profile_controller.dart';
import 'package:celilac/features/profile/presentation/profile_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_profile_repository.dart';

class _NameLabel extends StatelessWidget {
  const _NameLabel({required this.listen, required this.onBuild});

  final bool listen;
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    final controller = listen
        ? ProfileScope.of(context)
        : ProfileScope.read(context);
    return Text(controller.profile.name ?? 'sem nome');
  }
}

Future<int Function()> _pumpLabel(
  WidgetTester tester,
  ProfileController controller, {
  required bool listen,
}) async {
  var builds = 0;
  await tester.pumpWidget(
    ProfileScope(
      controller: controller,
      child: MaterialApp(
        home: _NameLabel(listen: listen, onBuild: () => builds++),
      ),
    ),
  );
  return () => builds;
}

const _ana = DietaryProfile(
  name: 'Ana',
  restrictions: {DietaryOption.glutenFree},
);

void main() {
  testWidgets('of: reconstrói quando o perfil muda', (tester) async {
    final controller = ProfileController(MemoryProfileRepository());
    addTearDown(controller.dispose);
    final builds = await _pumpLabel(tester, controller, listen: true);
    expect(find.text('sem nome'), findsOne);

    await tester.runAsync(() => controller.save(_ana));
    await tester.pump();

    expect(find.text('Ana'), findsOne);
    expect(builds(), 2);
  });

  testWidgets('read: não reconstrói quando o perfil muda', (tester) async {
    final controller = ProfileController(MemoryProfileRepository());
    addTearDown(controller.dispose);
    final builds = await _pumpLabel(tester, controller, listen: false);

    await tester.runAsync(() => controller.save(_ana));
    await tester.pump();

    expect(find.text('sem nome'), findsOne);
    expect(builds(), 1);
  });
}
