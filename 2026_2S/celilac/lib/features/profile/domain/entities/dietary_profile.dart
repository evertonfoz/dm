import '../../../establishments/domain/entities/dietary_option.dart';

class DietaryProfile {
  const DietaryProfile({
    this.name,
    this.restrictions = const {},
    this.needsCrossContactCare = false,
  });

  static const DietaryProfile empty = DietaryProfile();

  final String? name;
  final Set<DietaryOption> restrictions;
  final bool needsCrossContactCare;

  bool get isComplete => restrictions.isNotEmpty;

  DietaryProfile copyWith({
    String? name,
    bool clearName = false,
    Set<DietaryOption>? restrictions,
    bool? needsCrossContactCare,
  }) {
    return DietaryProfile(
      name: clearName ? null : (name ?? this.name),
      restrictions: restrictions ?? this.restrictions,
      needsCrossContactCare:
          needsCrossContactCare ?? this.needsCrossContactCare,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DietaryProfile &&
        other.name == name &&
        other.restrictions.length == restrictions.length &&
        other.restrictions.containsAll(restrictions) &&
        other.needsCrossContactCare == needsCrossContactCare;
  }

  @override
  int get hashCode => Object.hash(
    name,
    Object.hashAllUnordered(restrictions),
    needsCrossContactCare,
  );
}
