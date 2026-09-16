import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:wardrobe/core/catalogs.dart';
import 'package:wardrobe/core/category_tree.dart';
import 'package:wardrobe/core/db/app_database.dart';

abstract class CategoryRepository {
  Stream<List<Category>> watchClothing();
  Future<List<Category>> getClothing();
  Future<void> rename(String id, String label);
  Future<String> add({
    String? parentId,
    required String label,
    List<String> sizeFields = const [],
  });
  Future<void> moveSibling(String id, int delta);
  Future<void> deleteSubtree(String id);
}

class LocalCategoryRepository implements CategoryRepository {
  LocalCategoryRepository(this._db);

  final AppDatabase _db;

  Expression<bool> get _clothing => _db.categories.kind.equals(CategoryKind.clothing.name);

  @override
  Stream<List<Category>> watchClothing() {
    return (_db.select(_db.categories)..where((t) => t.kind.equals(CategoryKind.clothing.name)))
        .watch();
  }

  @override
  Future<List<Category>> getClothing() {
    return (_db.select(_db.categories)..where((t) => t.kind.equals(CategoryKind.clothing.name)))
        .get();
  }

  @override
  Future<void> rename(String id, String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('名称不能为空');
    }
    final all = await getClothing();
    final node = categoryById(all, id);
    if (node == null) return;
    if (siblingLabelTaken(
      all,
      parentId: node.parentId,
      label: trimmed,
      exceptId: id,
    )) {
      throw StateError('同一层已有「$trimmed」');
    }
    await (_db.update(_db.categories)
          ..where((t) => _clothing & t.id.equals(id)))
        .write(CategoriesCompanion(label: Value(trimmed)));
  }

  @override
  Future<String> add({
    String? parentId,
    required String label,
    List<String> sizeFields = const [],
  }) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('名称不能为空');
    }
    final all = await getClothing();
    if (parentId != null) {
      final parent = categoryById(all, parentId);
      if (parent == null) {
        throw StateError('找不到父分类');
      }
      if (!canAddChild(all, parent)) {
        throw StateError('小分类最多两层');
      }
    }
    final siblings = childrenOf(all, parentId);
    if (siblingLabelTaken(all, parentId: parentId, label: trimmed)) {
      throw StateError('同一层已有「$trimmed」');
    }
    final nextOrder = siblings.isEmpty ? 0 : siblings.last.sortOrder + 1;
    final id = const Uuid().v4();
    await _db.into(_db.categories).insert(
          CategoriesCompanion.insert(
            id: id,
            kind: CategoryKind.clothing.name,
            parentId: Value(parentId),
            label: trimmed,
            sortOrder: nextOrder,
            sizeFields: Value(encodeSizeFields(parentId == null ? sizeFields : const [])),
          ),
        );
    return id;
  }

  @override
  Future<void> moveSibling(String id, int delta) async {
    if (delta == 0) return;
    final all = await getClothing();
    final node = categoryById(all, id);
    if (node == null) return;
    final siblings = childrenOf(all, node.parentId);
    final index = siblings.indexWhere((c) => c.id == id);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= siblings.length) return;
    final other = siblings[target];
    await _db.batch((batch) {
      batch.update(
        _db.categories,
        CategoriesCompanion(sortOrder: Value(other.sortOrder)),
        where: (t) => _clothing & t.id.equals(node.id),
      );
      batch.update(
        _db.categories,
        CategoriesCompanion(sortOrder: Value(node.sortOrder)),
        where: (t) => _clothing & t.id.equals(other.id),
      );
    });
  }

  @override
  Future<void> deleteSubtree(String id) async {
    final all = await getClothing();
    final node = categoryById(all, id);
    if (node == null) return;
    final ids = subtreeIds(all, id);
    if (ids.any((cid) => categoryById(all, cid)?.isSystem == true)) {
      throw StateError('系统分类不能删除');
    }
    final fallbackId = itemsFallbackAfterDelete(all, node);
    await _db.transaction(() async {
      await (_db.update(_db.clothingItems)
            ..where((t) => t.categoryId.isIn(ids.toList())))
          .write(
            ClothingItemsCompanion(
              categoryId: Value(fallbackId),
            ),
          );
      await (_db.delete(_db.categoryCovers)
            ..where(
              (t) =>
                  t.kind.equals(CategoryKind.clothing.name) &
                  t.categoryId.isIn(ids.toList()),
            ))
          .go();
      await (_db.delete(_db.categories)
            ..where((t) => _clothing & t.id.isIn(ids.toList())))
          .go();
    });
  }
}
