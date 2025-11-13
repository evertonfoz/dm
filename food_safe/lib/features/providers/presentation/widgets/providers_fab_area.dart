import 'package:flutter/material.dart';

/// Widget que compõe a área do FAB e o botão opt-out (não exibir dica).
/// Recebe a [fabScale] (animação) criada no State e callbacks para ações.
class ProvidersFabArea extends StatelessWidget {
  final Animation<double>? fabScale;
  final bool dontShowTipAgain;
  final double bottomSafe;
  final VoidCallback onDontShowTipAgain;
  final VoidCallback onPressed;
  final String tooltip;

  const ProvidersFabArea({
    Key? key,
    required this.fabScale,
    required this.dontShowTipAgain,
    required this.bottomSafe,
    required this.onDontShowTipAgain,
    required this.onPressed,
    this.tooltip = 'Adicionar fornecedor',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 16.0, bottom: 8.0 + bottomSafe),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!dontShowTipAgain)
            TextButton(
              onPressed: onDontShowTipAgain,
              child: const Text('Não exibir dica novamente'),
            ),
          const SizedBox(width: 12),
          ScaleTransition(
            scale: fabScale ?? kAlwaysCompleteAnimation,
            child: Tooltip(
              message: tooltip,
              preferBelow: false,
              child: FloatingActionButton(
                onPressed: onPressed,
                tooltip: tooltip,
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
