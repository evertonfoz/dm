import '../../establishments/domain/entities/dietary_option.dart';

// No perfil, a mesma opção é lida pelo lado de quem evita:
// o estabelecimento oferece "Sem glúten"; a pessoa evita "Glúten".
extension DietaryOptionProfileLabel on DietaryOption {
  String get avoidLabel => switch (this) {
    DietaryOption.glutenFree => 'Glúten',
    DietaryOption.lactoseFree => 'Lactose',
  };
}
