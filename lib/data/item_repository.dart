import 'package:drift/drift.dart';
import 'package:wardrobe/core/db/app_database.dart';
import 'package:wardrobe/core/storage/image_store.dart';

abstract class ItemRepository {
  Stream<List<ClothingItem>> watchAll();
  Future<ClothingItem?> getById(String id);
  Future<void> upsert(ClothingItemsCompanion item);
  Future<void> moveToCategory(Iterable<String> ids, String categoryId);
  Future<void> delete(String id);
}

class LocalItemRepository implements ItemRepository {
  LocalItemRepository(this._db, this._images);

  final AppDatabase _db;
  final ImageStore _images;

  @override
  Stream<List<ClothingItem>> watchAll() {
    return (_db.select(_db.clothingItems)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  @override
  Future<ClothingItem?> getById(String id) {
    return (_db.select(_db.clothingItems)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<void> upsert(ClothingItemsCompanion item) {
    return _db.into(_db.clothingItems).insertOnConflictUpdate(item);
  }

  @override
  Future<void> moveToCategory(Iterable<String> ids, String categoryId) async {
    final idList = ids.toList();
    if (idList.isEmpty) return;
    await (_db.update(_db.clothingItems)..where((t) => t.id.isIn(idList)))
        .write(ClothingItemsCompanion(categoryId: Value(categoryId)));
  }

  @override
  Future<void> delete(String id) async {
    final existing = await getById(id);
    await (_db.delete(_db.clothingItems)..where((t) => t.id.equals(id))).go();
    await _images.deleteIfOwned(existing?.imagePath);
  }
}
