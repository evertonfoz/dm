enum PetAttendanceStatus { waiting, done }

extension PetAttendanceStatusExtension on PetAttendanceStatus {
  String get name {
    switch (this) {
      case PetAttendanceStatus.waiting:
        return 'Aguardando';
      case PetAttendanceStatus.done:
        return 'Atendido';
    }
  }

  Map<String, dynamic> toMap() {
    return {'name': name};
  }

  PetAttendanceStatus fromMap(Map<String, dynamic> map) {
    final name = map['name'];
    if (name == 'Aguardando') {
      return PetAttendanceStatus.waiting;
    } else if (name == 'Atendido') {
      return PetAttendanceStatus.done;
    } else {
      throw Exception('Invalid attendance status name: $name');
    }
  }
}
