// Allow snake_case field names that mirror the database columns.
// ignore_for_file: non_constant_identifier_names

import '../../domain/entities/provider.dart';

class ProviderDto {
  final int id;
  final String name;
  final String? image_url; // nomes iguais aos do banco
  final String? brand_color_hex;
  final double rating;
  final double? distance_km;
  final Map<String, dynamic>? metadata;
  final String updated_at; // ISO8601 no fio

  ProviderDto({
    required this.id,
    required this.name,
    this.image_url,
    this.brand_color_hex,
    required this.rating,
    this.distance_km,
    this.metadata,
    required this.updated_at,
  });

  factory ProviderDto.fromMap(Map<String, dynamic> m) => ProviderDto(
    id: m['id'] as int,
    name: m['name'] as String,
    image_url: m['image_url'] as String?,
    brand_color_hex: m['brand_color_hex'] as String?,
    rating: (m['rating'] as num).toDouble(),
    distance_km: (m['distance_km'] as num?)?.toDouble(),
    metadata: m['metadata'] as Map<String, dynamic>?,
    updated_at: m['updated_at'] as String,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'image_url': image_url,
    'brand_color_hex': brand_color_hex,
    'rating': rating,
    'distance_km': distance_km,
    'metadata': metadata,
    'updated_at': updated_at,
  };

  /// Convert DTO to domain entity `Provider`.
  Provider toEntity() {
    return Provider(
      id: id,
      name: name,
      imageUri: image_url != null ? Uri.tryParse(image_url!) : null,
      brandColorHex: brand_color_hex,
      rating: rating,
      distanceKm: distance_km,
      tags: metadata != null && metadata!['tags'] is List
          ? (metadata!['tags'] as List).map((e) => e.toString()).toSet()
          : null,
      featured: metadata != null && (metadata!['featured'] == true),
      updatedAt: DateTime.parse(updated_at),
    );
  }
}
