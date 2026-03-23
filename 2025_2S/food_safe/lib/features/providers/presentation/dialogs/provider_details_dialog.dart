import 'package:flutter/material.dart';

import '../../domain/entities/provider.dart';

/// Exibe diálogo de detalhes do fornecedor e delega ações para callbacks.
Future<void> showProviderDetailsDialog(
  BuildContext context,
  Provider provider, {
  required VoidCallback onEdit,
  required Future<void> Function() onRemove,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(provider.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.imageUri != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    provider.imageUri!.toString(),
                    height: 120,
                    width: 280,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        width: 280,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 48),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 120,
                        width: 280,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
              ),
            Text('Nota: ${provider.rating.toStringAsFixed(1)}'),
            if (provider.distanceKm != null)
              Text('Distância: ${provider.distanceKm!.toStringAsFixed(1)} km'),
            Text('Atualizado em: ${provider.updatedAt.toIso8601String()}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          child: const Text('Fechar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onEdit();
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          child: const Text('Editar'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            final confirm = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Remover fornecedor?'),
                content: Text(
                  'Tem certeza que deseja remover o fornecedor "${provider.name}"?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Remover'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await onRemove();
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Remover'),
        ),
      ],
    ),
  );
}
