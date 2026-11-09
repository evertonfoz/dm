import 'package:favoritos_01/features/favorites/presentation/favorites_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../establishments/data/sample_establishments.dart';
import '../../../establishments/domain/entities/establishment.dart';
import '../../../establishments/presentation/pages/establishment_details_page.dart';
import '../../../establishments/presentation/widgets/establishment_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openDetails(BuildContext context, Establishment estalishment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EstablishmentDetailsPage(establishment: estalishment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Estabelecimentos')),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sampleEstablishments.length,
        itemBuilder: (context, index) {
          final establishment = sampleEstablishments[index];

          return EstablishmentCard(
            establishment: establishment,
            isFavorite: favorites.isFavorite(establishment.establishmentId),
            onFavoriteToggle: () {
              context.read<FavoritesController>().toggle(establishment);
            },
            onTap: () => _openDetails(context, establishment),
          );
        },
      ),
    );
  }
}
