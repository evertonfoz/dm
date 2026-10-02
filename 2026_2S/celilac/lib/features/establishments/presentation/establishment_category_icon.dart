import 'package:flutter/material.dart';

import '../domain/establishment_category.dart';

extension EstablishmentCategoryIcon on EstablishmentCategory {
  IconData get icon => switch (this) {
    EstablishmentCategory.restaurant => Icons.restaurant_outlined,
    EstablishmentCategory.bakery => Icons.bakery_dining_outlined,
    EstablishmentCategory.cafe => Icons.local_cafe_outlined,
    EstablishmentCategory.market => Icons.storefront_outlined,
  };
}
