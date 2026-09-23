import 'package:drift/drift.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/storage/image_store.dart';
import 'package:wardrobe/features/wardrobe/domain/item_photo_policy.dart';
import 'package:wardrobe/features/wardrobe/photo_role.dart';

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
  Stream<List<ClothingItemImage>> watchAllImages();
  Future<List<ClothingItemImage>> getImages(String itemId);
  Future<void> upsert(
    ClothingItemsCompanion item, {
    List<ItemImageDraft>? images,
  });
  Future<void> moveToCategory(Iterable<String> ids, String categoryId);
  Future<void> delete(String id);
}

class LocalItemRepository implements ItemRepository {
  LocalItemRepository(this._db, this._images);

  final AppDatabase _db;
  final ImageStore _images;

  @override
  Stream<List<ClothingItem>> watchAll() {
    return (_db.select(
      _db.clothingItems,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
  }

  @override
  Future<ClothingItem?> getById(String id) {
    return (_db.select(
      _db.clothingItems,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Stream<List<ClothingItemImage>> watchAllImages() {
    return (_db.select(_db.clothingItemImages)..orderBy([
          (t) => OrderingTerm.asc(t.itemId),
          (t) => OrderingTerm.asc(t.sortOrder),
        ]))
        .watch();
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
    final pending = <ImageImport>[];
    final retired = <String>[];
    try {
      await _db.transaction(() async {
        var toWrite = item;
        if (images != null) {
          final stored = await _replaceImages(
            item.id.value,
            images,
            pending,
            retired,
          );
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
          toWrite = item.copyWith(imagePath: Value(_displayPath(primary)));
        }
        await _db.into(_db.clothingItems).insertOnConflictUpdate(toWrite);
      });
    } catch (error) {
      for (final op in pending) {
        await op.rollback();
      }
      rethrow;
    }
    for (final op in pending) {
      try {
        await op.commit();
      } catch (error) {
        await _retargetPath(op.finalPath, op.tempPath);
        rethrow;
      }
    }
    for (final path in retired) {
      await _releaseOwned(path);
    }
  }

  Future<String> _stage(String source, List<ImageImport> pending) async {
    if (_images.isOwned(source) && !_images.isTemporary(source)) return source;
    final op = _images.isTemporary(source)
        ? _images.adoptTemporary(source)
        : await _images.beginImport(source);
    pending.add(op);
    return op.finalPath;
  }

  Future<void> _retargetPath(String from, String to) async {
    await (_db.update(_db.clothingItemImages)
          ..where((t) => t.originalPath.equals(from)))
        .write(ClothingItemImagesCompanion(originalPath: Value(to)));
    await (_db.update(_db.clothingItemImages)
          ..where((t) => t.processedPath.equals(from)))
        .write(ClothingItemImagesCompanion(processedPath: Value(to)));
    await (_db.update(_db.clothingItemImages)
          ..where((t) => t.maskPath.equals(from)))
        .write(ClothingItemImagesCompanion(maskPath: Value(to)));
    await (_db.update(_db.clothingItems)
          ..where((t) => t.imagePath.equals(from)))
        .write(ClothingItemsCompanion(imagePath: Value(to)));
  }

  Future<List<ItemImageDraft>> _replaceImages(
    String itemId,
    List<ItemImageDraft> drafts,
    List<ImageImport> pending,
    List<String> retired,
  ) async {
    final previous = await getImages(itemId);
    final stored = <ItemImageDraft>[];
    for (var i = 0; i < drafts.length; i++) {
      final draft = drafts[i];
      final original = await _stage(draft.originalPath, pending);
      String? processed;
      if (draft.processedPath != null && draft.processedPath!.isNotEmpty) {
        processed = await _stage(draft.processedPath!, pending);
      }
      String? mask;
      if (draft.maskPath != null && draft.maskPath!.isNotEmpty) {
        mask = await _stage(draft.maskPath!, pending);
      }
      stored.add(
        ItemImageDraft(
          id: draft.id,
          originalPath: original,
          processedPath: processed,
          maskPath: mask,
          role: draft.role,
          isPrimary:
              draft.role == ItemPhotoRole.garment &&
              (draft.isPrimary ||
                  (!drafts.any(
                        (d) => d.role == ItemPhotoRole.garment && d.isPrimary,
                      ) &&
                      i ==
                          drafts.indexWhere(
                            (d) => d.role == ItemPhotoRole.garment,
                          ))),
          colorJson: draft.colorJson,
          ocrJson: draft.ocrJson,
        ),
      );
    }

    await (_db.delete(
      _db.clothingItemImages,
    )..where((t) => t.itemId.equals(itemId))).go();
    for (var i = 0; i < stored.length; i++) {
      final draft = stored[i];
      await _db
          .into(_db.clothingItemImages)
          .insert(
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
          retired.add(path);
        }
      }
    }
    return stored;
  }

  String? _displayPath(ItemImageDraft? image) {
    if (image == null) return null;
    return preferredItemDisplayPath(
      processedPath: image.processedPath,
      originalPath: image.originalPath,
    );
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
    await (_db.delete(
      _db.clothingItemImages,
    )..where((t) => t.itemId.equals(id))).go();
    await (_db.delete(_db.clothingItems)..where((t) => t.id.equals(id))).go();
    for (final row in images) {
      await _releaseOwned(row.originalPath);
      await _releaseOwned(row.processedPath);
      await _releaseOwned(row.maskPath);
    }
    if (images.isEmpty) {
      await _releaseOwned(existing?.imagePath);
    }
  }

  Future<bool> _imageReferenced(String path) async {
    final imageRow =
        await (_db.select(_db.clothingItemImages)
              ..where(
                (t) =>
                    t.originalPath.equals(path) |
                    t.processedPath.equals(path) |
                    t.maskPath.equals(path),
              )
              ..limit(1))
            .getSingleOrNull();
    if (imageRow != null) return true;
    final itemRow =
        await (_db.select(_db.clothingItems)
              ..where((t) => t.imagePath.equals(path))
              ..limit(1))
            .getSingleOrNull();
    return itemRow != null;
  }

  Future<void> _releaseOwned(String? path) async {
    if (path == null || path.isEmpty) return;
    if (await _imageReferenced(path)) return;
    await _images.deleteIfOwned(path);
  }
}
