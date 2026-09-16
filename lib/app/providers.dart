import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wardrobe/core/db/app_database.dart';
import 'package:wardrobe/core/sort.dart';
import 'package:wardrobe/core/storage/image_store.dart';
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
  return ref.watch(categoryRepositoryProvider).watchClothing();
});

final clothingCategoryRowsProvider = Provider<List<Category>>((ref) {
  return ref.watch(clothingCategoriesProvider).maybeWhen(
    data: (rows) => rows,
    orElse: () => const [],
  );
});

final clothingItemsProvider = StreamProvider<List<ClothingItem>>((ref) {
  return ref.watch(itemRepositoryProvider).watchAll();
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
