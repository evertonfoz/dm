import 'package:flutter/material.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.establishmentName,
    required this.isFavorite,
    required this.onPressed,
  });

  final String establishmentName;
  final bool isFavorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Rótulo contextualizado: essencial para leitores de tela (TalkBack/VoiceOver),
    // anunciando claramente qual estabelecimento será salvo ou removido.
    final label = isFavorite
        ? 'Remover $establishmentName dos favoritos'
        : 'Salvar $establishmentName nos favoritos';

    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      color: isFavorite ? Colors.red.shade700 : null,
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
    );
  }
}
