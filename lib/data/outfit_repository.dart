import 'package:drift/drift.dart';
import 'package:wardrobe/core/db/app_database.dart';
import 'package:wardrobe/core/storage/image_store.dart';

abstract class OutfitRepository {
  Stream<List<Outfit>> watchAll();
  Future<Outfit?> getById(String id);
  Future<void> upsert(OutfitsCompanion outfit);
  Future<void> moveToCategory(Iterable<String> ids, String categoryId);
  Future<void> delete(String id);
}

class LocalOutfitRepository implements OutfitRepository {
  LocalOutfitRepository(this._db, this._images);

  final AppDatabase _db;
  final ImageStore _images;

  @override
  Stream<List<Outfit>> watchAll() {
    return (_db.select(_db.outfits)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  @override
  Future<Outfit?> getById(String id) {
    return (_db.select(_db.outfits)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<void> upsert(OutfitsCompanion outfit) {
    return _db.into(_db.outfits).insertOnConflictUpdate(outfit);
  }

  @override
  Future<void> moveToCategory(Iterable<String> ids, String categoryId) async {
    final idList = ids.toList();
    if (idList.isEmpty) return;
    await (_db.update(_db.outfits)..where((t) => t.id.isIn(idList)))
        .write(OutfitsCompanion(categoryId: Value(categoryId)));
  }

  @override
  Future<void> delete(String id) async {
    final existing = await getById(id);
    await (_db.delete(_db.outfits)..where((t) => t.id.equals(id))).go();
    await _images.deleteIfOwned(existing?.imagePath);
  }
}
