import '../domain/entities/dietary_option.dart';
import '../domain/entities/establishment.dart';
import '../domain/entities/establishment_category.dart';
import '../domain/entities/establishment_details.dart';
import '../domain/entities/establishment_photo.dart';
import '../domain/entities/opening_hours.dart';
import '../domain/entities/safety_practice.dart';
import '../domain/repositories/establishment_repository.dart';

class FakeEstablishmentRepository implements EstablishmentRepository {
  const FakeEstablishmentRepository({
    this.delay = const Duration(milliseconds: 800),
  });

  final Duration delay;

  static const String _images = 'assets/images/establishments';

  static const List<Establishment> _establishments = [
    Establishment(
      id: '1',
      name: 'Café Aconchego',
      category: EstablishmentCategory.cafe,
      neighborhood: 'Centro',
      distanceInKm: 0.35,
      rating: 4.8,
      dietaryOptions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
      logoSource: '$_images/cafe_aconchego/logo.png',
    ),
    Establishment(
      id: '2',
      name: 'Padaria Leve Grão',
      category: EstablishmentCategory.bakery,
      neighborhood: 'Jardim das Flores',
      distanceInKm: 1.2,
      rating: 4.6,
      dietaryOptions: {DietaryOption.glutenFree},
      logoSource: '$_images/padaria_leve_grao/logo.png',
    ),
    Establishment(
      id: '3',
      name: 'Bistrô Bem-Estar',
      category: EstablishmentCategory.restaurant,
      neighborhood: 'Bela Vista',
      distanceInKm: 2.4,
      rating: 4.7,
      dietaryOptions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
      logoSource: '$_images/bistro_bem_estar/logo.png',
    ),
    Establishment(
      id: '4',
      name: 'Empório Natural',
      category: EstablishmentCategory.market,
      neighborhood: 'Vila Nova',
      distanceInKm: 3.1,
      rating: 4.5,
      dietaryOptions: {DietaryOption.lactoseFree},
    ),
  ];

  static final Map<String, EstablishmentDetails> _details = {
    '1': EstablishmentDetails(
      establishmentId: '1',
      description:
          'Café de bairro com cardápio próprio sem glúten e sem lactose: '
          'pães de fermentação natural, bolos caseiros e bebidas vegetais.',
      address: 'Rua das Palmeiras, 120 - Centro',
      phone: '(44) 0000-0101',
      openingHours: [
        ..._hoursFor(
          [1, 2, 3, 4, 5, 6],
          opensAt: const Duration(hours: 7),
          closesAt: const Duration(hours: 19),
        ),
        ..._hoursFor(
          [7],
          opensAt: const Duration(hours: 8),
          closesAt: const Duration(hours: 12),
        ),
      ],
      safetyPractices: SafetyPractice.values.toSet(),
      photos: [
        EstablishmentPhoto(
          source: '$_images/cafe_aconchego/photo_1.jpg',
          description: 'Salão do café com mesas de madeira e luz natural',
        ),
        EstablishmentPhoto(
          source: '$_images/cafe_aconchego/photo_2.jpg',
          description:
              'Vitrine com pães de fermentação natural e bolos caseiros',
        ),
        EstablishmentPhoto(
          source: '$_images/cafe_aconchego/photo_3.jpg',
          description: 'Café com bebida vegetal e uma fatia de bolo',
        ),
      ],
    ),
    '2': EstablishmentDetails(
      establishmentId: '2',
      description:
          'Padaria com linha completa sem glúten, produzida em área '
          'separada, com pães, salgados e encomendas de bolos.',
      address: 'Avenida das Hortênsias, 455 - Jardim das Flores',
      phone: '(44) 0000-0202',
      openingHours: _hoursFor(
        [2, 3, 4, 5, 6, 7],
        opensAt: const Duration(hours: 6, minutes: 30),
        closesAt: const Duration(hours: 13),
      ),
      safetyPractices: {
        SafetyPractice.separateKitchen,
        SafetyPractice.exclusiveUtensils,
        SafetyPractice.ingredientList,
      },
      photos: [
        EstablishmentPhoto(
          source: '$_images/padaria_leve_grao/photo_1.jpg',
          description: 'Prateleiras com pães variados',
        ),
        EstablishmentPhoto(
          source: '$_images/padaria_leve_grao/photo_2.jpg',
          description: 'Área de preparo separada com utensílios exclusivos',
        ),
        EstablishmentPhoto(
          source: '$_images/padaria_leve_grao/photo_3.jpg',
          description: 'Bandeja de salgados assados',
        ),
      ],
    ),
    '3': EstablishmentDetails(
      establishmentId: '3',
      description:
          'Restaurante com pratos do dia adaptáveis no almoço e jantar às '
          'sextas e sábados. Avise a equipe sobre a sua restrição ao pedir.',
      address: 'Rua Coronel Silva, 980 - Bela Vista',
      phone: '(44) 0000-0303',
      openingHours: [
        ..._hoursFor(
          [2, 3, 4, 5, 6],
          opensAt: const Duration(hours: 11, minutes: 30),
          closesAt: const Duration(hours: 15),
        ),
        ..._hoursFor(
          [5, 6],
          opensAt: const Duration(hours: 19),
          closesAt: const Duration(hours: 23),
        ),
      ],
      safetyPractices: {
        SafetyPractice.trainedStaff,
        SafetyPractice.ingredientList,
      },
      photos: [
        EstablishmentPhoto(
          source: '$_images/bistro_bem_estar/photo_1.jpg',
          description: 'Salão do bistrô arrumado para o almoço',
        ),
        EstablishmentPhoto(
          source: '$_images/bistro_bem_estar/photo_2.jpg',
          description:
              'Prato do dia com frango grelhado, arroz, feijão e salada',
        ),
        EstablishmentPhoto(
          source: '$_images/bistro_bem_estar/photo_3.jpg',
          description: 'Ambiente do jantar, à meia-luz',
        ),
      ],
    ),
    '4': EstablishmentDetails(
      establishmentId: '4',
      description:
          'Mercado de produtos naturais com um corredor dedicado a itens '
          'sem lactose e bebidas vegetais.',
      address: 'Rua Marechal Deodoro, 31 - Vila Nova',
      openingHours: _hoursFor(
        [1, 2, 3, 4, 5, 6],
        opensAt: const Duration(hours: 9),
        closesAt: const Duration(hours: 20),
      ),
      safetyPractices: {SafetyPractice.ingredientList},
      photos: [
        EstablishmentPhoto(
          source: '$_images/emporio_natural/photo_1.jpg',
          description: 'Corredor de bebidas vegetais',
        ),
        EstablishmentPhoto(
          source: '$_images/emporio_natural/photo_2.jpg',
          description: 'Grãos e castanhas a granel',
        ),
      ],
    ),
  };

  static List<OpeningHours> _hoursFor(
    List<int> weekdays, {
    required Duration opensAt,
    required Duration closesAt,
  }) {
    return [
      for (final weekday in weekdays)
        OpeningHours(weekday: weekday, opensAt: opensAt, closesAt: closesAt),
    ];
  }

  @override
  Future<List<Establishment>> fetchNearby() async {
    await Future<void>.delayed(delay);
    return _establishments;
  }

  @override
  Future<EstablishmentDetails?> fetchDetails(String establishmentId) async {
    await Future<void>.delayed(delay);
    return _details[establishmentId];
  }
}
