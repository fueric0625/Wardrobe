import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:wardrobe/core/catalogs.dart';
import 'package:wardrobe/core/category_tree.dart';
import 'package:wardrobe/core/db/app_database.dart';

abstract class CategoryRepository {
  Stream<List<Category>> watch(CategoryKind kind);
  Future<List<Category>> get(CategoryKind kind);
  Future<void> rename(CategoryKind kind, String id, String label);
  Future<String> add({
    required CategoryKind kind,
    String? parentId,
    required String label,
    List<String> sizeFields = const [],
  });
  Future<void> moveSibling(CategoryKind kind, String id, int delta);
  Future<void> deleteSubtree(CategoryKind kind, String id);
}

class LocalCategoryRepository implements CategoryRepository {
  LocalCategoryRepository(this._db);

  final AppDatabase _db;

  Expression<bool> _ofKind(CategoryKind kind) =>
      _db.categories.kind.equals(kind.name);

  @override
  Stream<List<Category>> watch(CategoryKind kind) {
    return (_db.select(_db.categories)..where((t) => t.kind.equals(kind.name)))
        .watch();
  }

  @override
  Future<List<Category>> get(CategoryKind kind) {
    return (_db.select(_db.categories)..where((t) => t.kind.equals(kind.name)))
        .get();
  }

  @override
  Future<void> rename(CategoryKind kind, String id, String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('名称不能为空');
    }
    final all = await get(kind);
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
          ..where((t) => _ofKind(kind) & t.id.equals(id)))
        .write(CategoriesCompanion(label: Value(trimmed)));
  }

  @override
  Future<String> add({
    required CategoryKind kind,
    String? parentId,
    required String label,
    List<String> sizeFields = const [],
  }) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('名称不能为空');
    }
    final all = await get(kind);
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
            kind: kind.name,
            parentId: Value(parentId),
            label: trimmed,
            sortOrder: nextOrder,
            sizeFields: Value(
              encodeSizeFields(parentId == null ? sizeFields : const []),
            ),
          ),
        );
    return id;
  }

  @override
  Future<void> moveSibling(CategoryKind kind, String id, int delta) async {
    if (delta == 0) return;
    final all = await get(kind);
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
        where: (t) => _ofKind(kind) & t.id.equals(node.id),
      );
      batch.update(
        _db.categories,
        CategoriesCompanion(sortOrder: Value(node.sortOrder)),
        where: (t) => _ofKind(kind) & t.id.equals(other.id),
      );
    });
  }

  @override
  Future<void> deleteSubtree(CategoryKind kind, String id) async {
    final all = await get(kind);
    final node = categoryById(all, id);
    if (node == null) return;
    final ids = subtreeIds(all, id);
    if (ids.any((cid) => categoryById(all, cid)?.isSystem == true)) {
      throw StateError('系统分类不能删除');
    }
    final fallbackId = itemsFallbackAfterDelete(all, node);
    final idList = ids.toList();
    await _db.transaction(() async {
      if (kind == CategoryKind.clothing) {
        await (_db.update(_db.clothingItems)
              ..where((t) => t.categoryId.isIn(idList)))
            .write(
              ClothingItemsCompanion(categoryId: Value(fallbackId)),
            );
      } else {
        await (_db.update(_db.outfits)
              ..where((t) => t.categoryId.isIn(idList)))
            .write(
              OutfitsCompanion(categoryId: Value(fallbackId)),
            );
      }
      await (_db.delete(_db.categoryCovers)
            ..where(
              (t) => t.kind.equals(kind.name) & t.categoryId.isIn(idList),
            ))
          .go();
      await (_db.delete(_db.categories)
            ..where((t) => _ofKind(kind) & t.id.isIn(idList)))
          .go();
    });
  }
}
