import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wardrobe/core/catalogs.dart';
import 'package:wardrobe/core/db/app_database.dart';
import 'package:wardrobe/core/sort.dart';
import 'package:wardrobe/core/storage/image_store.dart';
import 'package:wardrobe/core/vision/garment_pipeline.dart';
import 'package:wardrobe/core/vision/sam_click.dart';
import 'package:wardrobe/core/vision/u2net_segmenter.dart';
import 'package:wardrobe/data/category_repository.dart';
import 'package:wardrobe/data/cover_repository.dart';
import 'package:wardrobe/data/item_repository.dart';
import 'package:wardrobe/data/outfit_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  throw StateError('databaseProvider must be overridden in main()');
});

final imageStoreProvider = Provider<ImageStore>((ref) {
  throw StateError('imageStoreProvider must be overridden in main()');
});

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return LocalItemRepository(
    ref.watch(databaseProvider),
    ref.watch(imageStoreProvider),
  );
});

final u2netSegmenterProvider = Provider<U2NetSegmenter>((ref) {
  final segmenter = U2NetSegmenter();
  ref.onDispose(segmenter.dispose);
  return segmenter;
});

final samClickSegmenterProvider = Provider<SamClickSegmenter>((ref) {
  final segmenter = SamClickSegmenter();
  ref.onDispose(segmenter.dispose);
  return segmenter;
});

final garmentPipelineProvider = Provider<GarmentPipeline>((ref) {
  return GarmentPipeline(
    ref.watch(u2netSegmenterProvider),
    clickSegmenter: ref.watch(samClickSegmenterProvider),
  );
});

final outfitRepositoryProvider = Provider<OutfitRepository>((ref) {
  return LocalOutfitRepository(
    ref.watch(databaseProvider),
    ref.watch(imageStoreProvider),
  );
});

final categoryCoverRepositoryProvider = Provider<CategoryCoverRepository>((ref) {
  return LocalCategoryCoverRepository(ref.watch(databaseProvider));
});

final categoryCoversProvider = StreamProvider<List<CategoryCover>>((ref) {
  return ref.watch(categoryCoverRepositoryProvider).watchAll();
});

final categoryCoverRowsProvider = Provider<List<CategoryCover>>((ref) {
  return ref.watch(categoryCoversProvider).maybeWhen(
    data: (rows) => rows,
    orElse: () => const [],
  );
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return LocalCategoryRepository(ref.watch(databaseProvider));
});

final clothingCategoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watch(CategoryKind.clothing);
});

final clothingCategoryRowsProvider = Provider<List<Category>>((ref) {
  return ref.watch(clothingCategoriesProvider).maybeWhen(
    data: (rows) => rows,
    orElse: () => const [],
  );
});

final outfitCategoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watch(CategoryKind.outfit);
});

final outfitCategoryRowsProvider = Provider<List<Category>>((ref) {
  return ref.watch(outfitCategoriesProvider).maybeWhen(
    data: (rows) => rows,
    orElse: () => const [],
  );
});

final clothingItemsProvider = StreamProvider<List<ClothingItem>>((ref) {
  return ref.watch(itemRepositoryProvider).watchAll();
});

final itemImagesProvider =
    StreamProvider.family<List<ClothingItemImage>, String>((ref, itemId) {
  return ref.watch(itemRepositoryProvider).watchImages(itemId);
});

final outfitsProvider = StreamProvider<List<Outfit>>((ref) {
  return ref.watch(outfitRepositoryProvider).watchAll();
});

class ClothingSortNotifier extends Notifier<ListSort> {
  @override
  ListSort build() => ListSort.clothingDefault;

  void set(ListSort next) => state = next;
}

class OutfitSortNotifier extends Notifier<ListSort> {
  @override
  ListSort build() => ListSort.outfitDefault;

  void set(ListSort next) => state = next;
}

final clothingSortProvider =
    NotifierProvider<ClothingSortNotifier, ListSort>(ClothingSortNotifier.new);

final outfitSortProvider =
    NotifierProvider<OutfitSortNotifier, ListSort>(OutfitSortNotifier.new);
