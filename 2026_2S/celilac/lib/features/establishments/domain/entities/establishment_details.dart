import 'establishment_photo.dart';
import 'opening_hours.dart';
import 'safety_practice.dart';

class EstablishmentDetails {
  const EstablishmentDetails({
    required this.establishmentId,
    required this.description,
    required this.address,
    this.phone,
    required this.openingHours,
    required this.safetyPractices,
    this.photos = const [],
  });

  final String establishmentId;
  final String description;
  final String address;
  final String? phone;
  final List<OpeningHours> openingHours;
  final Set<SafetyPractice> safetyPractices;
  final List<EstablishmentPhoto> photos;

  OpeningHours? openPeriodAt(DateTime moment) {
    for (final hours in openingHours) {
      if (hours.contains(moment)) {
        return hours;
      }
    }
    return null;
  }

  List<OpeningHours> hoursOn(int weekday) {
    return [
      for (final hours in openingHours)
        if (hours.weekday == weekday) hours,
    ];
  }
}
