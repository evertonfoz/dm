import '../domain/entities/dietary_option.dart';
import '../domain/entities/establishment.dart';
import '../domain/entities/establishment_category.dart';
import '../domain/entities/establishment_details.dart';
import '../domain/entities/establishment_photo.dart';
import '../domain/entities/opening_hours.dart';
import '../domain/entities/safety_practice.dart';

/// Transforma um caminho do Storage (`cafe_aconchego/logo.png`) na URL
/// pública do arquivo. Quem sabe montar a URL é o client do Supabase.
typedef PublicUrlBuilder = String Function(String storagePath);

/// Uma linha de `establishments`, como a API REST devolve.
Establishment establishmentFromJson(
  Map<String, dynamic> json, {
  required PublicUrlBuilder publicUrl,
}) {
  return Establishment(
    id: json['id'] as String,
    name: json['name'] as String,
    // byName: o banco só aceita os nomes dos enums (check), então um valor
    // desconhecido é erro de versão, não algo a esconder.
    category: EstablishmentCategory.values.byName(json['category'] as String),
    neighborhood: json['neighborhood'] as String,
    // numeric chega como número no JSON, mas 5.0 pode chegar como 5 (int).
    distanceInKm: (json['distance_in_km'] as num).toDouble(),
    rating: (json['rating'] as num).toDouble(),
    dietaryOptions: {
      for (final name in json['dietary_options'] as List<dynamic>)
        DietaryOption.values.byName(name as String),
    },
    logoSource: _publicUrlOrNull(json['logo_path'], publicUrl),
  );
}

/// Uma linha de `establishments` com as tabelas filhas embutidas:
/// `establishment_details` (objeto, 1:1), `opening_hours` e
/// `establishment_photos` (listas, 1:N).
///
/// Devolve `null` quando o lugar existe mas não tem detalhes cadastrados.
EstablishmentDetails? establishmentDetailsFromJson(
  Map<String, dynamic> json, {
  required PublicUrlBuilder publicUrl,
}) {
  final details = json['establishment_details'] as Map<String, dynamic>?;
  if (details == null) {
    return null;
  }

  final hours = [
    for (final row in json['opening_hours'] as List<dynamic>)
      _openingHoursFromJson(row as Map<String, dynamic>),
  ];
  // A API não garante a ordem das linhas embutidas: ordenamos aqui.
  hours.sort((a, b) {
    final byDay = a.weekday.compareTo(b.weekday);
    return byDay != 0 ? byDay : a.opensAt.compareTo(b.opensAt);
  });

  final photoRows = [
    for (final row in json['establishment_photos'] as List<dynamic>)
      row as Map<String, dynamic>,
  ]..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

  return EstablishmentDetails(
    establishmentId: json['id'] as String,
    description: details['description'] as String,
    address: details['address'] as String,
    phone: details['phone'] as String?,
    openingHours: hours,
    safetyPractices: {
      for (final name in details['safety_practices'] as List<dynamic>)
        SafetyPractice.values.byName(name as String),
    },
    photos: [
      for (final row in photoRows)
        EstablishmentPhoto(
          source: publicUrl(row['path'] as String),
          description: row['description'] as String,
        ),
    ],
  );
}

/// Converte um `time` do Postgres (`"07:00:00"`, `"06:30"`, `"24:00:00"`)
/// para o tempo desde a meia-noite.
Duration durationFromPostgresTime(String value) {
  final match = _timePattern.firstMatch(value);
  if (match == null) {
    throw FormatException('Horário inválido', value);
  }
  return Duration(
    hours: int.parse(match.group(1)!),
    minutes: int.parse(match.group(2)!),
    seconds: int.parse(match.group(3) ?? '0'),
  );
}

// HH:MM, com segundos e frações de segundo opcionais (as frações são ignoradas).
final RegExp _timePattern = RegExp(r'^(\d{2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?$');

OpeningHours _openingHoursFromJson(Map<String, dynamic> json) {
  return OpeningHours(
    weekday: json['weekday'] as int,
    opensAt: durationFromPostgresTime(json['opens_at'] as String),
    closesAt: durationFromPostgresTime(json['closes_at'] as String),
  );
}

String? _publicUrlOrNull(Object? path, PublicUrlBuilder publicUrl) {
  return switch (path) {
    final String value when value.trim().isNotEmpty => publicUrl(value),
    _ => null,
  };
}
