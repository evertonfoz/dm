import 'package:flutter/material.dart';

import '../../domain/entities/establishment.dart';
import '../pages/establishment_details_page.dart';
import 'favorite_button.dart';

/// PROBLEMA DIDÁTICO AQUI: cada cartão guarda seu próprio `_isFavorite` local!
class EstablishmentCard extends StatelessWidget {
  const EstablishmentCard({
    super.key,
    required this.establishment,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final Establishment establishment;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final item = establishment;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${item.category} · ${item.neighborhood} · ★ ${item.rating}',
        ),
        trailing: onFavoriteToggle != null
            ? FavoriteButton(
                establishmentName: establishment.name,
                isFavorite: isFavorite,
                onPressed: onFavoriteToggle!,
              )
            : null,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EstablishmentDetailsPage(establishment: item),
            ),
          );
        },
      ),
    );
  }
}
