import '../../establishments/domain/entities/dietary_option.dart';
import '../../establishments/domain/entities/establishment.dart';
import '../../establishments/domain/entities/establishment_category.dart';

extension FavoriteEstablishmentRow on Establishment {
  Map<String, Object?> toRow({required DateTime savedAt}) => {
    'id': id,
    'name': name,
    'category': category.name,
    'neighborhood': neighborhood,
    'distance_in_km': distanceInKm,
    'rating': rating,
    'dietary_options': [
      for (final option in dietaryOptions) option.name,
    ].join(','),
    'logo_source': logoSource,
    'saved_at': savedAt.millisecondsSinceEpoch,
  };
}

Establishment establishmentFromRow(Map<String, Object?> row) {
  final categories = EstablishmentCategory.values.asNameMap();
  final options = DietaryOption.values.asNameMap();

  return Establishment(
    id: row['id'] as String,
    name: row['name'] as String,
    category: categories[row['category']] ?? EstablishmentCategory.restaurant,
    neighborhood: row['neighborhood'] as String,
    // No SQLite, um REAL sem casas decimais (ex.: 4.0) pode voltar como int.
    distanceInKm: (row['distance_in_km'] as num).toDouble(),
    rating: (row['rating'] as num).toDouble(),
    dietaryOptions: {
      if (row['dietary_options'] case final String raw when raw.isNotEmpty)
        for (final name in raw.split(',')) ?options[name],
    },
    logoSource: switch (row['logo_source']) {
      final String source when source.trim().isNotEmpty => source,
      _ => null,
    },
  );
}

