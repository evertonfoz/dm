import 'package:flutter/material.dart';

import '../domain/entities/safety_practice.dart';

extension SafetyPracticeIcon on SafetyPractice {
  IconData get icon => switch (this) {
    SafetyPractice.separateKitchen => Icons.kitchen_outlined,
    SafetyPractice.exclusiveUtensils => Icons.flatware_outlined,
    SafetyPractice.trainedStaff => Icons.school_outlined,
    SafetyPractice.ingredientList => Icons.list_alt_outlined,
  };
}
