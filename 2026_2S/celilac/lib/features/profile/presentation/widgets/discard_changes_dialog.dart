import 'package:flutter/material.dart';

/// Devolve `true` quando a pessoa escolhe descartar as alterações.
Future<bool> confirmDiscardChanges(BuildContext context) async {
  final discard = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Descartar alterações?'),
      content: const Text('As mudanças no seu perfil ainda não foram salvas.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Continuar editando'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Descartar'),
        ),
      ],
    ),
  );
  // Tocar fora do diálogo devolve null: na dúvida, não se perde nada.
  return discard ?? false;
}
