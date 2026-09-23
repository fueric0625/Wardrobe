import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wardrobe/app/providers.dart';
import 'package:wardrobe/core/catalog/catalogs.dart';
import 'package:wardrobe/core/catalog/category_repository.dart';
import 'package:wardrobe/core/catalog/cover_repository.dart';
import 'package:wardrobe/core/database/app_database.dart';

final categoryCoverRepositoryProvider = Provider<CategoryCoverRepository>((
  ref,
) {
  return LocalCategoryCoverRepository(ref.watch(databaseProvider));
});

final categoryCoversProvider = StreamProvider<List<CategoryCover>>((ref) {
  return ref.watch(categoryCoverRepositoryProvider).watchAll();
});

final categoryCoverRowsProvider = Provider<List<CategoryCover>>((ref) {
  return ref
      .watch(categoryCoversProvider)
      .maybeWhen(data: (rows) => rows, orElse: () => const []);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return LocalCategoryRepository(ref.watch(databaseProvider));
});

final clothingCategoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watch(CategoryKind.clothing);
});

final clothingCategoryRowsProvider = Provider<List<Category>>((ref) {
  return ref
      .watch(clothingCategoriesProvider)
      .maybeWhen(data: (rows) => rows, orElse: () => const []);
});

final outfitCategoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watch(CategoryKind.outfit);
});

final outfitCategoryRowsProvider = Provider<List<Category>>((ref) {
  return ref
      .watch(outfitCategoriesProvider)
      .maybeWhen(data: (rows) => rows, orElse: () => const []);
});
