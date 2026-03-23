/// Domain entity representing a Provider (business/establishment).
///
/// Placed under `features/providers` rather than `home` because it is
/// a domain model for provider-related features (listing, details,
/// filters) and may be used across screens (home, search, profile).
class Provider {
  final int id;
  final String name;
  final Uri? imageUri; // mais seguro que String solta
  final String? brandColorHex; // pode virar Color depois
  final double rating; // garantimos 0..5
  final double? distanceKm;
  final Set<String> tags; // vindo de metadata, mas aqui já limpo
  final bool featured; // idem
  final DateTime updatedAt;

  Provider({
    required this.id,
    required this.name,
    this.imageUri,
    this.brandColorHex,
    required double rating,
    this.distanceKm,
    Set<String>? tags,
    this.featured = false,
    required this.updatedAt,
  }) : rating = rating.clamp(0.0, 5.0),
       tags = {...?tags};

  /// Conveniência para a UI (texto pronto)
  String get subtitle =>
      '${rating.toStringAsFixed(1)} ★ · ${distanceKm?.toStringAsFixed(1) ?? '-'} km';

  /// Serialization helper from a Map (e.g., DB row or JSON).
  factory Provider.fromMap(Map<String, dynamic> map) {
    return Provider(
      id: map['id'] as int,
      name: map['name'] as String,
      imageUri: map['image_uri'] != null
          ? Uri.tryParse(map['image_uri'] as String)
          : null,
      brandColorHex: map['brand_color_hex'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toSet(),
      featured: (map['featured'] as bool?) ?? false,
      updatedAt: map['updated_at'] is DateTime
          ? map['updated_at'] as DateTime
          : DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert to a Map suitable for DB insertion or JSON encoding.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image_uri': imageUri?.toString(),
      'brand_color_hex': brandColorHex,
      'rating': rating,
      'distance_km': distanceKm,
      'tags': tags.toList(),
      'featured': featured,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
