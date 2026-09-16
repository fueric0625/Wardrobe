import 'package:wardrobe/core/catalogs.dart';
import 'package:wardrobe/core/db/app_database.dart';

List<Category> clothingRoots(List<Category> all) => childrenOf(all, null);

List<Category> childrenOf(List<Category> all, String? parentId) {
  final children = all.where((c) => c.parentId == parentId).toList()
    ..sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) return byOrder;
      return a.id.compareTo(b.id);
    });
  return children;
}

Category? categoryById(List<Category> all, String id) {
  for (final category in all) {
    if (category.id == id) return category;
  }
  return null;
}

int categoryDepth(List<Category> all, Category node) {
  var depth = 0;
  var current = node;
  final seen = <String>{current.id};
  while (current.parentId != null) {
    final parent = categoryById(all, current.parentId!);
    if (parent == null || !seen.add(parent.id)) break;
    depth++;
    current = parent;
  }
  return depth;
}

bool canAddChild(List<Category> all, Category node) {
  return categoryDepth(all, node) < maxCategoryDepth;
}

/// Same parent (including roots) cannot share a label. Other branches may.
bool siblingLabelTaken(
  List<Category> all, {
  required String? parentId,
  required String label,
  String? exceptId,
}) {
  final name = label.trim();
  for (final sibling in childrenOf(all, parentId)) {
    if (exceptId != null && sibling.id == exceptId) continue;
    if (sibling.label.trim() == name) return true;
  }
  return false;
}

Category rootOf(List<Category> all, Category node) {
  var current = node;
  final seen = <String>{current.id};
  while (current.parentId != null) {
    final parent = categoryById(all, current.parentId!);
    if (parent == null || !seen.add(parent.id)) break;
    current = parent;
  }
  return current;
}

List<String> inheritedSizeFields(List<Category> all, Category node) {
  return decodeSizeFields(rootOf(all, node).sizeFields);
}

List<Category> ancestorsAndSelf(List<Category> all, Category node) {
  final chain = <Category>[node];
  var current = node;
  final seen = <String>{current.id};
  while (current.parentId != null) {
    final parent = categoryById(all, current.parentId!);
    if (parent == null || !seen.add(parent.id)) break;
    chain.add(parent);
    current = parent;
  }
  return chain.reversed.toList();
}

String categoryPath(List<Category> all, String id, {String fallback = '无分类'}) {
  final node = categoryById(all, id);
  if (node == null) return fallback;
  return ancestorsAndSelf(all, node).map((c) => c.label).join(' / ');
}

/// After deleting [node] (and its subtree), items land on the parent.
/// Top-level categories fall back to 无分类.
String itemsFallbackAfterDelete(List<Category> all, Category node) {
  final parentId = node.parentId;
  if (parentId == null) return uncategorizedClothingId;
  if (categoryById(all, parentId) == null) return uncategorizedClothingId;
  return parentId;
}

Set<String> subtreeIds(List<Category> all, String id) {
  final ids = <String>{id};
  final queue = [id];
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    for (final child in childrenOf(all, current)) {
      if (ids.add(child.id)) queue.add(child.id);
    }
  }
  return ids;
}

List<Category> flattenPreorder(List<Category> all) {
  final out = <Category>[];
  void walk(Category node) {
    out.add(node);
    for (final child in childrenOf(all, node.id)) {
      walk(child);
    }
  }

  for (final root in clothingRoots(all)) {
    walk(root);
  }
  return out;
}

List<ClothingItem> itemsInSubtree(
  List<ClothingItem> items,
  List<Category> categories,
  String id,
) {
  final ids = subtreeIds(categories, id);
  return items.where((item) => ids.contains(item.categoryId)).toList();
}

List<ClothingItem> itemsDirectlyIn(List<ClothingItem> items, String id) {
  return items.where((item) => item.categoryId == id).toList();
}

/// Categories this item may cover: itself and every ancestor.
/// A 卫衣 item can be 上装's cover, but never 衬衫's.
List<Category> coverCategoriesForItem(List<Category> all, String itemCategoryId) {
  final node = categoryById(all, itemCategoryId);
  if (node == null) return const [];
  return ancestorsAndSelf(all, node);
}
