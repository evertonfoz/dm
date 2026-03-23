// Allow snake_case field names that mirror the database columns.
// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

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

  factory ProviderDto.fromMap(Map<String, dynamic> m) {
    final imageUrl = m['image_url'] as String?;
    if (kDebugMode) {
      debugPrint('[ProviderDto.fromMap] Raw map keys: ${m.keys.toList()}');
      debugPrint('[ProviderDto.fromMap] image_url: $imageUrl');
    }

    return ProviderDto(
      id: _parseId(m['id']),
      name: m['name'] as String,
      image_url: imageUrl,
      brand_color_hex: m['brand_color_hex'] as String?,
      rating: _parseDouble(m['rating']),
      distance_km: _parseNullableDouble(m['distance_km']),
      metadata: _parseMap(m['metadata']),
      updated_at: _parseUpdatedAt(m['updated_at']),
    );
  }

  static int _parseId(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final p = int.tryParse(v);
      if (p != null) return p;
    }
    throw FormatException('Invalid id value: $v');
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) {
      return double.tryParse(v) ?? 0.0;
    }
    return 0.0;
  }

  static double? _parseNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static Map<String, dynamic>? _parseMap(dynamic v) {
    if (v == null) return null;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  static String _parseUpdatedAt(dynamic v) {
    if (v == null) return DateTime.now().toUtc().toIso8601String();
    if (v is String) return v;
    if (v is DateTime) return v.toUtc().toIso8601String();
    return v.toString();
  }

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
