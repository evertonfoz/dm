import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/establishments/domain/entities/establishment.dart';
import 'package:celilac/features/establishments/domain/entities/establishment_category.dart';

const both = {DietaryOption.glutenFree, DietaryOption.lactoseFree};

const cafeAconchego = Establishment(
  id: '1',
  name: 'Café Aconchego',
  category: EstablishmentCategory.cafe,
  neighborhood: 'Centro',
  distanceInKm: 0.35,
  rating: 4.8,
  dietaryOptions: both,
);

const padariaLeve = Establishment(
  id: '2',
  name: 'Padaria Leve Grão',
  category: EstablishmentCategory.bakery,
  neighborhood: 'Jardim das Flores',
  distanceInKm: 1.2,
  rating: 4.6,
  dietaryOptions: {DietaryOption.glutenFree},
);

const bistro = Establishment(
  id: '3',
  name: 'Bistrô Bem-Estar',
  category: EstablishmentCategory.restaurant,
  neighborhood: 'Bela Vista',
  distanceInKm: 2.4,
  rating: 4.7,
  dietaryOptions: both,
);

const emporio = Establishment(
  id: '4',
  name: 'Empório Natural',
  category: EstablishmentCategory.market,
  neighborhood: 'Vila Nova',
  distanceInKm: 3.1,
  rating: 4.5,
  dietaryOptions: {DietaryOption.lactoseFree},
);

const catalog = [emporio, bistro, cafeAconchego, padariaLeve];
