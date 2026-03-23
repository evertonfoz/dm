import 'package:flutter/material.dart';
import '../core/theme.dart';

class CustomFilledButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool enabled;

  const CustomFilledButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: enabled ? purple : slate,
        foregroundColor: Colors.white,
        minimumSize: const Size(180, 48),
      ),
    );
  }
}