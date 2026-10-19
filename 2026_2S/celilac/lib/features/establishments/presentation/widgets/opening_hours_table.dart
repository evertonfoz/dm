import 'package:flutter/material.dart';

import '../../../../app/common/formatters.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/establishment_details.dart';

class OpeningHoursTable extends StatelessWidget {
  const OpeningHoursTable({
    super.key,
    required this.details,
    required this.today,
  });

  final EstablishmentDetails details;
  final int today;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (
          var weekday = DateTime.monday;
          weekday <= DateTime.sunday;
          weekday++
        )
          _buildRow(context, weekday),
      ],
    );
  }

  Widget _buildRow(BuildContext context, int weekday) {
    final periods = details.hoursOn(weekday);
    final hoursText = periods.isEmpty
        ? 'Fechado'
        : periods
              .map(
                (p) => '${formatHour(p.opensAt)} às ${formatHour(p.closesAt)}',
              )
              .join('\n');
    final isToday = weekday == today;
    final dayText = isToday
        ? '${formatWeekday(weekday)} (hoje)'
        : formatWeekday(weekday);
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.navy,
      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
    );

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(dayText, style: style)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(hoursText, style: style, textAlign: TextAlign.end),
            ),
          ],
        ),
      ),
    );
  }
}
