import '../entities/establishment.dart';
import '../entities/establishment_details.dart';

abstract interface class EstablishmentRepository {
  Future<List<Establishment>> fetchNearby();

  Future<EstablishmentDetails?> fetchDetails(String establishmentId);
}
