import 'package:wardrobe/core/database/app_database.dart';

/// System categories stay. Sibling order is the stored sort, then id.
bool categoryCanBeDeleted({required bool isSystem}) => !isSystem;

int compareCategorySiblings(Category a, Category b) {
  final byOrder = a.sortOrder.compareTo(b.sortOrder);
  if (byOrder != 0) return byOrder;
  return a.id.compareTo(b.id);
}
