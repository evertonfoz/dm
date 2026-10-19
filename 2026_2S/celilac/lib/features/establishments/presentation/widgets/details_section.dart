import 'package:flutter/material.dart';

import '../../../../app/common/widgets/section_header.dart';
import '../../../../app/theme/app_spacing.dart';

class DetailsSection extends StatelessWidget {
  const DetailsSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ],
    );
  }
}
