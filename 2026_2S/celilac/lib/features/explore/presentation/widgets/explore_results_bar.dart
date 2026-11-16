import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/explore_sort.dart';

/// "8 lugares encontrados" + escolha da ordenação.
class ExploreResultsBar extends StatelessWidget {
  const ExploreResultsBar({
    super.key,
    required this.count,
    required this.sort,
    required this.onSortChanged,
  });

  final int count;
  final ExploreSort sort;
  final ValueChanged<ExploreSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final summary = switch (count) {
      0 => 'Nenhum lugar encontrado',
      1 => '1 lugar encontrado',
      _ => '$count lugares encontrados',
    };

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      children: [
        // liveRegion: leitores de tela anunciam a nova contagem sozinhos.
        Semantics(
          liveRegion: true,
          child: Text(
            summary,
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DropdownButton<ExploreSort>(
          value: sort,
          underline: const SizedBox.shrink(),
          onChanged: (value) {
            if (value != null) onSortChanged(value);
          },
          items: [
            for (final option in ExploreSort.values)
              DropdownMenuItem(value: option, child: Text(option.label)),
          ],
        ),
      ],
    );
  }
}
