import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';

class ContactActions extends StatelessWidget {
  const ContactActions({super.key, required this.onDirections, this.onCall});

  final VoidCallback onDirections;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final call = onCall;

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onDirections,
            icon: const Icon(Icons.directions_outlined),
            label: const Text('Como chegar'),
          ),
        ),
        if (call != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: call,
              icon: const Icon(Icons.call_outlined),
              label: const Text('Ligar'),
            ),
          ),
        ],
      ],
    );
  }
}
