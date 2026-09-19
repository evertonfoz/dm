class SpecieEntity {
  final String specieId;
  final String name;

  const SpecieEntity({required this.specieId, required this.name});

  Map<String, dynamic> toMap() {
    return {'specieId': specieId, 'name': name};
  }

  factory SpecieEntity.fromMap(Map<String, dynamic> map) {
    return SpecieEntity(specieId: map['specieId'], name: map['name']);
  }
}
