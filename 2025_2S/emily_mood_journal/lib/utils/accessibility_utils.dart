import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class AccessibilityUtils {
  static void announceToScreenReader(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  static Widget buildSemanticButton({
    required Widget child,
    required VoidCallback onPressed,
    required String label,
    String? hint,
  }) {
    return Semantics(
      button: true,
      label: label,
      hint: hint,
      onTap: onPressed,
      child: child,
    );
  }

  static Widget buildSemanticCard({
    required Widget child,
    required String label,
    String? hint,
  }) {
    return Semantics(
      container: true,
      label: label,
      hint: hint,
      child: child,
    );
  }
}
