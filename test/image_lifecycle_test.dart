import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/storage/image_store.dart';
import 'package:wardrobe/features/wardrobe/data/item_repository.dart';
import 'package:wardrobe/features/wardrobe/photo_role.dart';

void main() {
  late Directory root;
  late ImageStore images;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('wardrobe_images_');
    images = ImageStore(
      directory: Directory('${root.path}${Platform.pathSeparator}images'),
    );
    await images.init();
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test('a failed import removes the temporary file', () async {
    final op = await images.beginBytes(Uint8List.fromList([7, 8]), 'png');
    expect(File(op.tempPath).existsSync(), isTrue);
    expect(File(op.finalPath).existsSync(), isFalse);
    await op.rollback();
    expect(File(op.tempPath).existsSync(), isFalse);
    expect(File(op.finalPath).existsSync(), isFalse);
  });

  test('owned files are deleted and outside files are kept', () async {
    final owned = await images.writeBytes(Uint8List.fromList([1, 2, 3]), 'png');
    final outside = File('${root.path}${Platform.pathSeparator}user.png');
    await outside.writeAsBytes([9]);

    expect(images.isOwned(owned), isTrue);
    expect(images.isOwned(outside.path), isFalse);

    await images.deleteIfOwned(owned);
    await images.deleteIfOwned(outside.path);

    expect(File(owned).existsSync(), isFalse);
    expect(outside.existsSync(), isTrue);
  });

  test('deleting an item removes its owned image files', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = LocalItemRepository(db, images);
    final original = await images.writeBytes(Uint8List.fromList([1]), 'jpg');
    final processed = await images.writeBytes(Uint8List.fromList([2]), 'png');
    final mask = await images.writeBytes(Uint8List.fromList([3]), 'png');
    final outside = File('${root.path}${Platform.pathSeparator}camera.jpg');
    await outside.writeAsBytes([4]);

    final now = DateTime.utc(2026, 1, 1);
    await repo.upsert(
      ClothingItemsCompanion.insert(
        id: 'item',
        categoryId: 'tops',
        createdAt: now,
        updatedAt: now,
      ),
      images: [
        ItemImageDraft(
          id: 'photo',
          originalPath: original,
          processedPath: processed,
          maskPath: mask,
          role: ItemPhotoRole.garment,
          isPrimary: true,
        ),
      ],
    );

    await repo.delete('item');

    expect(File(original).existsSync(), isFalse);
    expect(File(processed).existsSync(), isFalse);
    expect(File(mask).existsSync(), isFalse);
    expect(outside.existsSync(), isTrue);
    expect(await repo.getById('item'), isNull);
  });

  test(
    'replacing images deletes the previous processed and mask files',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = LocalItemRepository(db, images);
      final original = await images.writeBytes(Uint8List.fromList([1]), 'jpg');
      final processed = await images.writeBytes(Uint8List.fromList([2]), 'png');
      final mask = await images.writeBytes(Uint8List.fromList([3]), 'png');
      final now = DateTime.utc(2026, 1, 1);
      await repo.upsert(
        ClothingItemsCompanion.insert(
          id: 'item',
          categoryId: 'tops',
          createdAt: now,
          updatedAt: now,
        ),
        images: [
          ItemImageDraft(
            id: 'photo',
            originalPath: original,
            processedPath: processed,
            maskPath: mask,
            isPrimary: true,
          ),
        ],
      );

      await repo.upsert(
        ClothingItemsCompanion.insert(
          id: 'item',
          categoryId: 'tops',
          createdAt: now,
          updatedAt: now,
        ),
        images: [
          ItemImageDraft(id: 'photo', originalPath: original, isPrimary: true),
        ],
      );

      expect(File(original).existsSync(), isTrue);
      expect(File(processed).existsSync(), isFalse);
      expect(File(mask).existsSync(), isFalse);
    },
  );

  test('deleting one item keeps a file still used by another item', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = LocalItemRepository(db, images);
    final shared = await images.writeBytes(Uint8List.fromList([9]), 'jpg');
    final now = DateTime.utc(2026, 1, 1);

    Future<void> save(String id) {
      return repo.upsert(
        ClothingItemsCompanion.insert(
          id: id,
          categoryId: 'tops',
          createdAt: now,
          updatedAt: now,
        ),
        images: [
          ItemImageDraft(
            id: '$id-photo',
            originalPath: shared,
            role: ItemPhotoRole.garment,
            isPrimary: true,
          ),
        ],
      );
    }

    await save('first');
    await save('second');
    await repo.delete('first');

    expect(File(shared).existsSync(), isTrue);
    expect((await repo.getImages('second')).single.originalPath, shared);

    await repo.delete('second');
    expect(File(shared).existsSync(), isFalse);
  });
}
