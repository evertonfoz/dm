import 'dart:math' as math;

import 'app_spacing.dart';

abstract final class AppLayout {
  static const double maxContentWidth = 600;

  static double horizontalPadding(double screenWidth) {
    return math.max(AppSpacing.lg, (screenWidth - maxContentWidth) / 2);
  }
}
