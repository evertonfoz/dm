import '../../establishments/domain/entities/dietary_option.dart';
import '../domain/entities/dietary_profile.dart';

// Chaves em snake_case: os mesmos nomes servirão de colunas no banco.
extension DietaryProfileJson on DietaryProfile {
  Map<String, Object?> toJson() => {
    'name': name,
    'restrictions': [for (final option in restrictions) option.name],
    'needs_cross_contact_care': needsCrossContactCare,
  };
}

DietaryProfile dietaryProfileFromJson(Map<String, Object?> json) {
  final options = DietaryOption.values.asNameMap();

  return DietaryProfile(
    name: switch (json['name']) {
      final String name when name.trim().isNotEmpty => name,
      _ => null,
    },
    restrictions: {
      if (json['restrictions'] case final List<Object?> values)
        for (final value in values) ?options[value],
    },
    needsCrossContactCare: json['needs_cross_contact_care'] == true,
  );
}
