import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wardrobe/app/providers.dart';
import 'package:wardrobe/core/db/app_database.dart';
import 'package:wardrobe/core/sort.dart';
import 'package:wardrobe/features/wardrobe/data/item_repository.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return LocalItemRepository(
    ref.watch(databaseProvider),
    ref.watch(imageStoreProvider),
  );
});

final clothingItemsProvider = StreamProvider<List<ClothingItem>>((ref) {
  return ref.watch(itemRepositoryProvider).watchAll();
});

final itemImagesProvider =
    StreamProvider.family<List<ClothingItemImage>, String>((ref, itemId) {
  return ref.watch(itemRepositoryProvider).watchImages(itemId);
});

final clothingImageRowsProvider = StreamProvider<List<ClothingItemImage>>((ref) {
  return ref.watch(itemRepositoryProvider).watchAllImages();
});

class ClothingSortNotifier extends Notifier<ListSort> {
  @override
  ListSort build() => ListSort.clothingDefault;

  void set(ListSort next) => state = next;
}

final clothingSortProvider =
    NotifierProvider<ClothingSortNotifier, ListSort>(ClothingSortNotifier.new);
