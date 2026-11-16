import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../establishments/domain/entities/establishment.dart';
import '../favorites_controller.dart';

/// Alterna o favorito e avisa a pessoa com um SnackBar.
/// `read`: é uma ação disparada por toque, não uma leitura que redesenha.
void toggleFavoriteWithFeedback(
  BuildContext context,
  Establishment establishment,
) {
  final added = context.read<FavoritesController>().toggle(establishment);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          added
              ? '${establishment.name} salvo nos favoritos.'
              : '${establishment.name} removido dos favoritos.',
        ),
      ),
    );
}
