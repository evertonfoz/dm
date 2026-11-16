import 'package:flutter/material.dart';

import '../../domain/enums/explore_sort.dart';

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
    // Plural tratado à mão: "1 lugar" × "N lugares".
    final summary = switch (count) {
      0 => 'Nenhum lugar encontrado',
      1 => '1 lugar encontrado',
      _ => '$count lugares encontrados',
    };

    // Wrap: com fonte grande, a ordenação desce de linha em vez de estourar.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      children: [
        // liveRegion: leitores de tela anunciam a nova contagem sozinhos.
        Semantics(
          liveRegion: true,
          child: Text(
            summary,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
              DropdownMenuItem(value: option, child: Text(option.displayName)),
          ],
        ),
      ],
    );
  }
}
