import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../establishments/domain/entities/establishment.dart';
import 'favorites_controller.dart';

/// Alterna o favorito e, se a gravação falhar, avisa com um SnackBar.
/// Fica fora das páginas para Home, Explorar e Favoritos agirem igual.
Future<void> toggleFavoriteWithFeedback(
  BuildContext context,
  Establishment establishment,
) async {
  try {
    await context.read<FavoritesController>().toggle(establishment);
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Não foi possível atualizar os favoritos.'),
        ),
      );
  }
}
