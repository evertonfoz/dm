import '../../domain/entities/provider.dart';
import '../dtos/provider_dto.dart';

class ProviderMapper {
  static Provider toEntity(ProviderDto d) {
    final md = d.metadata ?? const {};
    final tags =
        (md['tags'] as List?)?.whereType<String>().toSet() ?? <String>{};
    final featured = md['featured'] == true;

    return Provider(
      id: d.id,
      name: d.name,
      imageUri: d.image_url != null ? Uri.tryParse(d.image_url!) : null,
      brandColorHex: d.brand_color_hex,
      rating: d.rating,
      distanceKm: d.distance_km,
      tags: tags,
      featured: featured,
      updatedAt: DateTime.parse(d.updated_at),
    );
  }

  static ProviderDto toDto(Provider e) => ProviderDto(
    id: e.id,
    name: e.name,
    image_url: e.imageUri?.toString(),
    brand_color_hex: e.brandColorHex,
    rating: e.rating,
    distance_km: e.distanceKm,
    metadata: {'tags': e.tags.toList(), 'featured': e.featured},
    updated_at: e.updatedAt.toIso8601String(),
  );
}
