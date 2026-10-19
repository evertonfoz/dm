import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/establishments/domain/entities/establishment.dart';
import 'package:celilac/features/establishments/domain/entities/establishment_category.dart';
import 'package:celilac/features/establishments/presentation/widgets/category_icon_tile.dart';
import 'package:celilac/features/establishments/presentation/widgets/establishment_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Establishment _cafeWithLogo(String? logoSource) => Establishment(
  id: '1',
  name: 'Café Teste',
  category: EstablishmentCategory.cafe,
  neighborhood: 'Centro',
  distanceInKm: 0.35,
  rating: 4.8,
  dietaryOptions: const {DietaryOption.glutenFree},
  logoSource: logoSource,
);

Future<void> _pumpLogo(WidgetTester tester, Establishment establishment) {
  return tester.pumpWidget(
    MaterialApp(
      home: Center(child: EstablishmentLogo(establishment: establishment)),
    ),
  );
}

void main() {
  testWidgets('usa o ícone da categoria quando não há logo', (tester) async {
    await _pumpLogo(tester, _cafeWithLogo(null));

    expect(find.byType(CategoryIconTile), findsOne);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('mostra a imagem quando há logo', (tester) async {
    await _pumpLogo(
      tester,
      _cafeWithLogo('assets/images/establishments/cafe_aconchego/logo.png'),
    );

    expect(find.byType(Image), findsOne);
    expect(find.byType(CategoryIconTile), findsNothing);
  });

  testWidgets('mostra o ícone da categoria quando a logo não carrega', (
    tester,
  ) async {
    await _pumpLogo(tester, _cafeWithLogo('assets/nao_existe.png'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.byIcon(Icons.local_cafe_outlined), findsOne);
  });
}
