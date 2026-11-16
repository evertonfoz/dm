import '../entities/establishment.dart';

abstract interface class EstablishmentRepository {
  Future<List<Establishment>> fetchNearby();
}
