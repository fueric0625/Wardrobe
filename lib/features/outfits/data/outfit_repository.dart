import 'package:drift/drift.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/storage/image_store.dart';
import 'package:wardrobe/features/outfits/domain/outfit_cover_policy.dart';

abstract class OutfitRepository {
  Stream<List<Outfit>> watchAll();
  Future<Outfit?> getById(String id);
  Stream<List<String>> watchClothingItemIds(String outfitId);
  Stream<List<OutfitItem>> watchLinks();
  Future<void> save(OutfitsCompanion outfit, List<String> clothingItemIds);
  Future<void> moveToCategory(Iterable<String> ids, String categoryId);
  Future<void> clearPhoto(String id);
  Future<void> clearCollage(String id);
  Future<void> delete(String id);
}

class LocalOutfitRepository implements OutfitRepository {
  LocalOutfitRepository(this._db, this._images);

  final AppDatabase _db;
  final ImageStore _images;

  @override
  Stream<List<Outfit>> watchAll() {
    return (_db.select(
      _db.outfits,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
  }

  @override
  Future<Outfit?> getById(String id) {
    return (_db.select(
      _db.outfits,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Stream<List<String>> watchClothingItemIds(String outfitId) {
    final query = _db.select(_db.outfitItems)
      ..where((t) => t.outfitId.equals(outfitId))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return query.watch().map(
      (rows) => [for (final row in rows) row.clothingItemId],
    );
  }

  @override
  Stream<List<OutfitItem>> watchLinks() {
    return (_db.select(_db.outfitItems)..orderBy([
          (t) => OrderingTerm.asc(t.outfitId),
          (t) => OrderingTerm.asc(t.sortOrder),
        ]))
        .watch();
  }

  @override
  Future<void> save(
    OutfitsCompanion outfit,
    List<String> clothingItemIds,
  ) async {
    final id = outfit.id.value;
    await _db.transaction(() async {
      await _db.into(_db.outfits).insertOnConflictUpdate(outfit);
      await (_db.delete(
        _db.outfitItems,
      )..where((t) => t.outfitId.equals(id))).go();
      final seen = <String>{};
      var order = 0;
      for (final clothingId in clothingItemIds) {
        if (!seen.add(clothingId)) continue;
        await _db
            .into(_db.outfitItems)
            .insert(
              OutfitItemsCompanion.insert(
                outfitId: id,
                clothingItemId: clothingId,
                sortOrder: Value(order),
              ),
            );
        order++;
      }
    });
  }

  @override
  Future<void> moveToCategory(Iterable<String> ids, String categoryId) async {
    final idList = ids.toList();
    if (idList.isEmpty) return;
    await (_db.update(_db.outfits)..where((t) => t.id.isIn(idList))).write(
      OutfitsCompanion(categoryId: Value(categoryId)),
    );
  }

  @override
  Future<void> clearPhoto(String id) async {
    final existing = await getById(id);
    if (existing == null) return;
    await (_db.update(_db.outfits)..where((t) => t.id.equals(id))).write(
      OutfitsCompanion(
        imagePath: const Value(null),
        sourceImagePath: const Value(null),
        coverMode: Value(
          coverModeAfterChange(
            hasPhoto: false,
            hasCollage: _savedCollageRemains(existing.collageLayout),
            coverMode: existing.coverMode,
          ),
        ),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await _images.deleteIfOwned(existing.imagePath);
    if (existing.sourceImagePath != existing.imagePath) {
      await _images.deleteIfOwned(existing.sourceImagePath);
    }
  }

  @override
  Future<void> clearCollage(String id) async {
    final existing = await getById(id);
    if (existing == null) return;
    final hasPhoto =
        existing.imagePath != null && existing.imagePath!.isNotEmpty;
    await (_db.update(_db.outfits)..where((t) => t.id.equals(id))).write(
      OutfitsCompanion(
        collageLayout: const Value(''),
        coverMode: Value(
          coverModeAfterChange(
            hasPhoto: hasPhoto,
            hasCollage: false,
            coverMode: existing.coverMode,
          ),
        ),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    final existing = await getById(id);
    await _db.transaction(() async {
      await (_db.delete(
        _db.outfitItems,
      )..where((t) => t.outfitId.equals(id))).go();
      await (_db.delete(_db.outfits)..where((t) => t.id.equals(id))).go();
    });
    await _images.deleteIfOwned(existing?.imagePath);
    if (existing?.sourceImagePath != existing?.imagePath) {
      await _images.deleteIfOwned(existing?.sourceImagePath);
    }
  }
}

/// A saved collage is a non-empty layout string. Null means nothing was
/// saved, and empty string means the user removed the collage.
bool _savedCollageRemains(String? layout) =>
    layout != null && layout.isNotEmpty;
