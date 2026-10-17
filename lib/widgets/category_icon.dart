import 'package:flutter/material.dart';

import '../models/item_category.dart';

extension ItemCategoryIcon on ItemCategory {
  IconData get icon => switch (this) {
    ItemCategory.electronics => Icons.headphones_rounded,
    ItemCategory.bags => Icons.backpack_rounded,
    ItemCategory.keys => Icons.key_rounded,
    ItemCategory.walletsCards => Icons.account_balance_wallet_rounded,
    ItemCategory.idDocuments => Icons.badge_rounded,
    ItemCategory.clothing => Icons.checkroom_rounded,
    ItemCategory.accessories => Icons.watch_rounded,
    ItemCategory.booksStationery => Icons.menu_book_rounded,
    ItemCategory.bottles => Icons.water_drop_rounded,
    ItemCategory.other => Icons.category_rounded,
  };
}
