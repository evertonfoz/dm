import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

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
    final label = isFavorite
        ? 'Remover $establishmentName dos favoritos'
        : 'Salvar $establishmentName nos favoritos';

    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      color: AppColors.navy,
      style: IconButton.styleFrom(
        backgroundColor: isFavorite
            ? AppColors.gold.withValues(alpha: 0.22)
            : null,
      ),
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
    );
  }
}

