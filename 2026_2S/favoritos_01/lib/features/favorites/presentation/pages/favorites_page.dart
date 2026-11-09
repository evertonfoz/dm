import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../establishments/domain/entities/establishment.dart';
import '../../../establishments/presentation/pages/establishment_details_page.dart';
import '../../../establishments/presentation/widgets/establishment_card.dart';
import '../favorites_controller.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key, this.onExploreTap});

  final VoidCallback? onExploreTap;

  void _openDetails(BuildContext context, Establishment establishment) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EstablishmentDetailsPage(establishment: establishment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.read<FavoritesController>().favorites;

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: favorites.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_border, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Você ainda não salvou nenhum estabelecimento.\n'
                      'Toque no coração em um lugar para encontrá-lo rápido aqui.',
                      textAlign: TextAlign.center,
                    ),
                    if (onExploreTap != null) ...[
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: onExploreTap,
                        child: const Text('Ver estabelecimentos'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    favorites.length == 1
                        ? '1 lugar salvo'
                        : '${favorites.length} lugares salvos',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                for (final establishment in favorites)
                  EstablishmentCard(
                    establishment: establishment,
                    isFavorite: true,
                    onFavoriteToggle: () {
                      context.read<FavoritesController>().toggle(establishment);
                    },
                    onTap: () => _openDetails(context, establishment),
                  ),
              ],
            ),
    );
  }
}
