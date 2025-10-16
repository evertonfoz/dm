import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/event.dart';

class EventListTile extends StatelessWidget {
  final Event event;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EventListTile({
    super.key,
    required this.event,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white10,
      child: ListTile(
        title: Text(
          event.nome,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Início: ${event.horarioInicio}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Fim: ${event.horarioFim}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Duração: ${event.duracao.inMinutes} min',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Pessoas: ${event.quantidadePessoas}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Checklist: ${event.checklist.join(", ")}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: Icon(Icons.edit, color: cyan),
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}