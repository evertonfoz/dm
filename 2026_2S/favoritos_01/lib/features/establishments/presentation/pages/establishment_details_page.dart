import 'package:favoritos_01/features/establishments/presentation/widgets/favorite_button.dart';
import 'package:favoritos_01/features/favorites/presentation/favorites_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/establishment.dart';

/// PROBLEMA DIDÁTICO AQUI TAMBÉM: a tela de detalhes tem outro `_isFavorite`!
class EstablishmentDetailsPage extends StatelessWidget {
  const EstablishmentDetailsPage({super.key, required this.establishment});

  final Establishment establishment;

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.watch<FavoritesController>().isFavorite(
      establishment.establishmentId,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(establishment.name),
        actions: [
          FavoriteButton(
            establishmentName: establishment.name,
            isFavorite: isFavorite,
            onPressed: () =>
                context.read<FavoritesController>().toggle(establishment),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                establishment.name,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('${establishment.category} · ${establishment.neighborhood}'),
              const SizedBox(height: 4),
              Text('Nota: ★ ${establishment.rating}'),
            ],
          ),
        ),
      ),
    );
  }
}
