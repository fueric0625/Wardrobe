import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/app/providers.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/storage/image_store.dart';
import 'package:wardrobe/features/outfits/data/outfit_repository.dart';
import 'package:wardrobe/features/outfits/presentation/outfit_edit_controller.dart';
import 'package:wardrobe/features/outfits/providers.dart';

void main() {
  late Directory root;
  late ImageStore images;
  late AppDatabase db;
  late LocalOutfitRepository repo;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('wardrobe_outfit_edit_');
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

  Future<String> saveLook() async {
    final photo = await images.writeBytes(Uint8List.fromList([1, 2, 3]), 'jpg');
    final now = DateTime.utc(2026, 9, 1);
    await repo.save(
      OutfitsCompanion.insert(
        id: 'look',
        categoryId: 'uncategorized',
        imagePath: Value(photo),
        sourceImagePath: Value(photo),
        createdAt: now,
        updatedAt: now,
      ),
      const [],
    );
    return photo;
  }

  test('deleting an edited outfit drops the new uncommitted photo', () async {
    final savedPhoto = await saveLook();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        imageStoreProvider.overrideWithValue(images),
      ],
    );
    addTearDown(container.dispose);
    const key = (outfitId: 'look', categoryId: null);
    final subscription = container.listen(
      outfitEditControllerProvider(key),
      (previous, next) {},
    );
    addTearDown(subscription.close);

    final editor = container.read(outfitEditControllerProvider(key).notifier);
    await _waitUntilLoaded(container, key);
    await editor.stagePhotoBytes(Uint8List.fromList([9, 9, 9]));
    final staged = container
        .read(outfitEditControllerProvider(key))
        .displayPath!;
    expect(File(staged).existsSync(), isTrue);
    expect(staged, isNot(savedPhoto));

    await editor.delete();

    expect(await repo.getById('look'), isNull);
    expect(File(staged).existsSync(), isFalse);
    expect(File(savedPhoto).existsSync(), isFalse);
  });

  test('a failed delete keeps the new photo until the editor closes', () async {
    final savedPhoto = await saveLook();
    final failing = _DeleteFails(repo);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        imageStoreProvider.overrideWithValue(images),
        outfitRepositoryProvider.overrideWithValue(failing),
      ],
    );
    const key = (outfitId: 'look', categoryId: null);
    final subscription = container.listen(
      outfitEditControllerProvider(key),
      (previous, next) {},
    );

    final editor = container.read(outfitEditControllerProvider(key).notifier);
    await _waitUntilLoaded(container, key);
    await editor.stagePhotoBytes(Uint8List.fromList([9, 9, 9]));
    final staged = container
        .read(outfitEditControllerProvider(key))
        .displayPath!;

    await expectLater(editor.delete(), throwsA(isA<StateError>()));
    expect(await repo.getById('look'), isNotNull);
    expect(File(staged).existsSync(), isTrue);
    expect(File(savedPhoto).existsSync(), isTrue);

    subscription.close();
    container.dispose();
    await _waitUntilGone(staged);
    expect(File(savedPhoto).existsSync(), isTrue);
    expect(await repo.getById('look'), isNotNull);
  });
}

Future<void> _waitUntilLoaded(
  ProviderContainer container,
  OutfitEditKey key,
) async {
  for (var i = 0; i < 50; i++) {
    if (container.read(outfitEditControllerProvider(key)).loaded) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('outfit editor did not finish loading');
}

Future<void> _waitUntilGone(String path) async {
  for (var i = 0; i < 50; i++) {
    if (!File(path).existsSync()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('temporary photo was not removed');
}

class _DeleteFails implements OutfitRepository {
  _DeleteFails(this._inner);

  final OutfitRepository _inner;

  @override
  Future<void> delete(String id) =>
      Future<void>.error(StateError('delete failed'));

  @override
  Future<Outfit?> getById(String id) => _inner.getById(id);

  @override
  Future<void> save(OutfitsCompanion outfit, List<String> clothingItemIds) =>
      _inner.save(outfit, clothingItemIds);

  @override
  Future<void> clearPhoto(String id) => _inner.clearPhoto(id);

  @override
  Future<void> clearCollage(String id) => _inner.clearCollage(id);

  @override
  Future<void> moveToCategory(Iterable<String> ids, String categoryId) =>
      _inner.moveToCategory(ids, categoryId);

  @override
  Stream<List<Outfit>> watchAll() => _inner.watchAll();

  @override
  Stream<List<String>> watchClothingItemIds(String outfitId) =>
      _inner.watchClothingItemIds(outfitId);

  @override
  Stream<List<OutfitItem>> watchLinks() => _inner.watchLinks();
}
