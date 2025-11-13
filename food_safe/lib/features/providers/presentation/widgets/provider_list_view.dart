import 'package:flutter/material.dart';

import '../../infrastructure/dtos/provider_dto.dart';
import 'provider_list_item.dart';

/// Widget que monta a ListView de providers. Recebe callbacks para ações
/// (onTap, onEdit, onRemove) e não realiza nenhuma persistência por si só.
class ProviderListView extends StatelessWidget {
  final List<ProviderDto> providers;
  final void Function(ProviderDto provider, int index)? onTap;
  final void Function(ProviderDto provider, int index)? onEdit;
  final Future<void> Function(int index)?
  onRemove; // chamador realiza persistência

  const ProviderListView({
    Key? key,
    required this.providers,
    this.onTap,
    this.onEdit,
    this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
      itemCount: providers.length,
      itemBuilder: (context, idx) {
        final p = providers[idx];
        final isEven = idx % 2 == 0;
        final backgroundColor = isEven ? Colors.blue[50] : Colors.grey[100];

        return Dismissible(
          key: Key(p.id.toString()),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white, size: 28),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: const Text('Remover fornecedor?'),
                    content: Text(
                      'Tem certeza que deseja remover "${p.name}"?',
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
                ) ??
                false;
          },
          onDismissed: (direction) async {
            if (onRemove != null) {
              await onRemove!(idx);
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Container(
              color: backgroundColor,
              child: ProviderListItem(
                provider: p,
                onTap: () => onTap?.call(p, idx),
                onEdit: () => onEdit?.call(p, idx),
              ),
            ),
          ),
        );
      },
    );
  }
}
