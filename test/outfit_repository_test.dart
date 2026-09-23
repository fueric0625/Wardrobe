import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/storage/image_store.dart';
import 'package:wardrobe/features/outfits/data/outfit_repository.dart';
import 'package:wardrobe/widgets/piece_collage.dart';

void main() {
  late Directory root;
  late ImageStore images;
  late AppDatabase db;
  late LocalOutfitRepository repo;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('wardrobe_outfits_');
    images = ImageStore(
      directory: Directory('${root.path}${Platform.pathSeparator}images'),
    );
    await images.init();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalOutfitRepository(db, images);
  });

  tearDown(() async {
    await db.close();
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  Future<void> saveLook({
    required String id,
    String? imagePath,
    String? collageLayout,
    String coverMode = 'photo',
  }) {
    final now = DateTime.utc(2026, 9, 1);
    return repo.save(
      OutfitsCompanion.insert(
        id: id,
        categoryId: 'uncategorized',
        imagePath: Value(imagePath),
        sourceImagePath: Value(imagePath),
        coverMode: Value(coverMode),
        collageLayout: Value(collageLayout),
        createdAt: now,
        updatedAt: now,
      ),
      const [],
    );
  }

  test('clearPhoto leaves the cover alone when no collage was saved', () async {
    final photo = await images.writeBytes(Uint8List.fromList([1]), 'jpg');
    await saveLook(id: 'look', imagePath: photo);

    await repo.clearPhoto('look');

    final row = await repo.getById('look');
    expect(row!.imagePath, isNull);
    expect(row.coverMode, 'photo');
    expect(File(photo).existsSync(), isFalse);
  });

  test(
    'clearPhoto leaves the cover alone when the collage was removed',
    () async {
      final photo = await images.writeBytes(Uint8List.fromList([1]), 'jpg');
      await saveLook(id: 'look', imagePath: photo, collageLayout: '');

      await repo.clearPhoto('look');

      expect((await repo.getById('look'))!.coverMode, 'photo');
    },
  );

  test('clearPhoto switches the cover when a collage layout remains', () async {
    final photo = await images.writeBytes(Uint8List.fromList([1]), 'jpg');
    await saveLook(
      id: 'look',
      imagePath: photo,
      collageLayout: encodeCollageLayout(autoPlacements(const ['shirt'])),
    );

    await repo.clearPhoto('look');

    expect((await repo.getById('look'))!.coverMode, 'collage');
  });

  test('a saved collage layout reloads with the same placement', () async {
    const piece = CollagePlacement(
      clothingItemId: 'shirt',
      x: -0.25,
      y: 1.1,
      w: 1.4,
      h: 0.08,
      z: 4,
    );
    await saveLook(
      id: 'look',
      collageLayout: encodeCollageLayout(const [piece]),
    );

    final back = decodeCollageLayout(
      (await repo.getById('look'))!.collageLayout,
    ).single;
    expect(back.clothingItemId, piece.clothingItemId);
    expect(back.x, piece.x);
    expect(back.y, piece.y);
    expect(back.w, piece.w);
    expect(back.h, piece.h);
    expect(back.z, piece.z);
  });
}
