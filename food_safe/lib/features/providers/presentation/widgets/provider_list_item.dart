import 'package:flutter/material.dart';

import '../../infrastructure/dtos/provider_dto.dart';

/// Widget para renderizar um item de provider na lista.
/// Recebe callbacks para ações (tap e edit). Não realiza persistência.
class ProviderListItem extends StatelessWidget {
  final ProviderDto provider;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const ProviderListItem({
    Key? key,
    required this.provider,
    this.onTap,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Container(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : Colors.grey[900],
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              if (provider.image_url != null)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: SizedBox(
                    width: 80,
                    height: 90,
                    child: Image.network(
                      provider.image_url!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.store, size: 32),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.store, size: 32),
                        );
                      },
                    ),
                  ),
                )
              else
                SizedBox(
                  width: 80,
                  height: 90,
                  child: Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.store),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nota: ${provider.rating.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (provider.distance_km != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${provider.distance_km!.toStringAsFixed(1)} km',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Editar',
                      onPressed: onEdit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
