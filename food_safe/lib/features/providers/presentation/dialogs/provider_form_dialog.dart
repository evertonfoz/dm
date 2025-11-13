import 'package:flutter/material.dart';

import '../../infrastructure/dtos/provider_dto.dart';

/// Exibe o diálogo de formulário para criar/editar um ProviderDto.
/// Retorna o [ProviderDto] criado/alterado ou `null` se cancelado.
Future<ProviderDto?> showProviderFormDialog(
  BuildContext context, {
  ProviderDto? provider,
}) {
  return showDialog<ProviderDto>(
    context: context,
    builder: (context) {
      final nameController = TextEditingController(text: provider?.name ?? '');
      final ratingController = TextEditingController(
        text: provider?.rating.toString() ?? '5.0',
      );
      final distanceController = TextEditingController(
        text: provider?.distance_km?.toString() ?? '',
      );
      final imageUrlController = TextEditingController(
        text: provider?.image_url ?? '',
      );

      final labelStyle = TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
      );
      final hintStyle = TextStyle(
        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
      );
      final inputTextStyle = TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
      );

      return AlertDialog(
        title: Text(provider == null ? 'Novo Fornecedor' : 'Editar Fornecedor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  labelStyle: labelStyle,
                  hintStyle: hintStyle,
                ),
                autofocus: true,
                // ensure caret and typed text are visible against dialog background
                cursorColor: Theme.of(context).colorScheme.onSurface,
                style: inputTextStyle,
              ),
              TextField(
                controller: ratingController,
                decoration: InputDecoration(
                  labelText: 'Nota (0-5)',
                  labelStyle: labelStyle,
                  hintStyle: hintStyle,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                cursorColor: Theme.of(context).colorScheme.onSurface,
                style: inputTextStyle,
              ),
              TextField(
                controller: distanceController,
                decoration: InputDecoration(
                  labelText: 'Distância (km)',
                  labelStyle: labelStyle,
                  hintStyle: hintStyle,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                cursorColor: Theme.of(context).colorScheme.onSurface,
                style: inputTextStyle,
              ),
              TextField(
                controller: imageUrlController,
                decoration: InputDecoration(
                  labelText: 'URL da Imagem (opcional)',
                  labelStyle: labelStyle,
                  hintStyle: hintStyle,
                ),
                cursorColor: Theme.of(context).colorScheme.onSurface,
                style: inputTextStyle,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final rating = double.tryParse(ratingController.text) ?? 5.0;
              final distance = double.tryParse(distanceController.text);
              final imageUrl = imageUrlController.text.trim().isEmpty
                  ? null
                  : imageUrlController.text.trim();
              if (name.isEmpty) return;
              final now = DateTime.now().toIso8601String();
              final dto = ProviderDto(
                id: provider?.id ?? DateTime.now().millisecondsSinceEpoch,
                name: name,
                image_url: imageUrl,
                brand_color_hex: null,
                rating: rating,
                distance_km: distance,
                metadata: null,
                updated_at: now,
              );
              Navigator.of(context).pop(dto);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 4,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              provider == null ? 'Adicionar' : 'Salvar',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    },
  );
}
