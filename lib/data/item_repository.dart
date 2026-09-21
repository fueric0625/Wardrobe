import 'package:drift/drift.dart';
import 'package:wardrobe/core/db/app_database.dart';
import 'package:wardrobe/core/storage/image_store.dart';
import 'package:wardrobe/core/vision/garment_pipeline.dart';

class ItemImageDraft {
  ItemImageDraft({
    required this.id,
    required this.originalPath,
    this.processedPath,
    this.maskPath,
    this.role = ItemPhotoRole.garment,
    this.isPrimary = false,
    this.colorJson = '',
    this.ocrJson = '',
  });

  final String id;
  final String originalPath;
  final String? processedPath;
  final String? maskPath;
  final ItemPhotoRole role;
  final bool isPrimary;
  final String colorJson;
  final String ocrJson;
}

abstract class ItemRepository {
  Stream<List<ClothingItem>> watchAll();
  Future<ClothingItem?> getById(String id);
  Stream<List<ClothingItemImage>> watchImages(String itemId);
  Future<List<ClothingItemImage>> getImages(String itemId);
  Future<void> upsert(ClothingItemsCompanion item, {List<ItemImageDraft>? images});
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
  Stream<List<ClothingItemImage>> watchImages(String itemId) {
    return (_db.select(_db.clothingItemImages)
          ..where((t) => t.itemId.equals(itemId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  @override
  Future<List<ClothingItemImage>> getImages(String itemId) {
    return (_db.select(_db.clothingItemImages)
          ..where((t) => t.itemId.equals(itemId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  @override
  Future<void> upsert(
    ClothingItemsCompanion item, {
    List<ItemImageDraft>? images,
  }) async {
    await _db.transaction(() async {
      var toWrite = item;
      if (images != null) {
        final stored = await _replaceImages(item.id.value, images);
        ItemImageDraft? primary;
        for (final image in stored) {
          if (image.isPrimary) {
            primary = image;
            break;
          }
        }
        primary ??= stored.cast<ItemImageDraft?>().firstWhere(
              (image) => image?.role == ItemPhotoRole.garment,
              orElse: () => null,
            );
        toWrite = item.copyWith(
          imagePath: Value(_displayPath(primary)),
        );
      }
      await _db.into(_db.clothingItems).insertOnConflictUpdate(toWrite);
    });
  }

  Future<List<ItemImageDraft>> _replaceImages(
    String itemId,
    List<ItemImageDraft> drafts,
  ) async {
    final previous = await getImages(itemId);
    final stored = <ItemImageDraft>[];
    for (var i = 0; i < drafts.length; i++) {
      final draft = drafts[i];
      final original = await _images.importOrKeep(draft.originalPath);
      String? processed;
      if (draft.processedPath != null && draft.processedPath!.isNotEmpty) {
        processed = await _images.importOrKeep(draft.processedPath!);
      }
      String? mask;
      if (draft.maskPath != null && draft.maskPath!.isNotEmpty) {
        mask = await _images.importOrKeep(draft.maskPath!);
      }
      stored.add(
        ItemImageDraft(
          id: draft.id,
          originalPath: original,
          processedPath: processed,
          maskPath: mask,
          role: draft.role,
          isPrimary: draft.role == ItemPhotoRole.garment &&
              (draft.isPrimary ||
                  (!drafts.any((d) => d.role == ItemPhotoRole.garment && d.isPrimary) &&
                      i == drafts.indexWhere((d) => d.role == ItemPhotoRole.garment))),
          colorJson: draft.colorJson,
          ocrJson: draft.ocrJson,
        ),
      );
    }

    await (_db.delete(_db.clothingItemImages)
          ..where((t) => t.itemId.equals(itemId)))
        .go();
    for (var i = 0; i < stored.length; i++) {
      final draft = stored[i];
      await _db.into(_db.clothingItemImages).insert(
            ClothingItemImagesCompanion.insert(
              id: draft.id,
              itemId: itemId,
              sortOrder: i,
              role: Value(draft.role.name),
              originalPath: draft.originalPath,
              processedPath: Value(draft.processedPath),
              maskPath: Value(draft.maskPath),
              colorJson: Value(draft.colorJson),
              ocrJson: Value(draft.ocrJson),
              isPrimary: Value(draft.isPrimary),
            ),
          );
    }

    final keep = <String>{};
    for (final draft in stored) {
      keep.add(draft.originalPath);
      if (draft.processedPath != null) keep.add(draft.processedPath!);
      if (draft.maskPath != null) keep.add(draft.maskPath!);
    }
    for (final row in previous) {
      for (final path in [row.originalPath, row.processedPath, row.maskPath]) {
        if (path != null && path.isNotEmpty && !keep.contains(path)) {
          await _images.deleteIfOwned(path);
        }
      }
    }
    return stored;
  }

  String? _displayPath(ItemImageDraft? image) {
    if (image == null) return null;
    final processed = image.processedPath;
    if (processed != null && processed.isNotEmpty) return processed;
    return image.originalPath;
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
    final images = await getImages(id);
    await (_db.delete(_db.clothingItemImages)..where((t) => t.itemId.equals(id))).go();
    await (_db.delete(_db.clothingItems)..where((t) => t.id.equals(id))).go();
    for (final row in images) {
      await _images.deleteIfOwned(row.originalPath);
      await _images.deleteIfOwned(row.processedPath);
      await _images.deleteIfOwned(row.maskPath);
    }
    if (images.isEmpty) {
      await _images.deleteIfOwned(existing?.imagePath);
    }
  }
}
