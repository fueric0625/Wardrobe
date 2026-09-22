import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wardrobe/app/providers.dart';
import 'package:wardrobe/core/db/app_database.dart';
import 'package:wardrobe/core/sort.dart';
import 'package:wardrobe/features/outfits/data/outfit_repository.dart';
import 'package:wardrobe/features/wardrobe/providers.dart';
import 'package:wardrobe/widgets/piece_collage.dart';

final outfitRepositoryProvider = Provider<OutfitRepository>((ref) {
  return LocalOutfitRepository(
    ref.watch(databaseProvider),
    ref.watch(imageStoreProvider),
  );
});

final outfitsProvider = StreamProvider<List<Outfit>>((ref) {
  return ref.watch(outfitRepositoryProvider).watchAll();
});

final outfitClothingIdsProvider =
    StreamProvider.family<List<String>, String>((ref, outfitId) {
  return ref.watch(outfitRepositoryProvider).watchClothingItemIds(outfitId);
});

final outfitLinksProvider = StreamProvider<List<OutfitItem>>((ref) {
  return ref.watch(outfitRepositoryProvider).watchLinks();
});

/// Resolved cover for each outfit: the full-body photo, or a collage.
final outfitCoversProvider = Provider<Map<String, OutfitCoverModel>>((ref) {
  final outfits = ref.watch(outfitsProvider).asData?.value ?? const <Outfit>[];
  final links = ref.watch(outfitLinksProvider).asData?.value ?? const <OutfitItem>[];
  final images = ref.watch(clothingCutoutsProvider);
  final idsByOutfit = <String, List<String>>{};
  for (final link in links) {
    if (!images.containsKey(link.clothingItemId)) continue;
    (idsByOutfit[link.outfitId] ??= []).add(link.clothingItemId);
  }
  return {
    for (final outfit in outfits)
      outfit.id: _coverFor(outfit, idsByOutfit[outfit.id] ?? const [], images),
  };
});

OutfitCoverModel _coverFor(
  Outfit outfit,
  List<String> clothingIds,
  Map<String, String> images,
) {
  if (isCollageRemoved(outfit.collageLayout)) {
    return const OutfitCoverModel(usesCollage: false, pieces: []);
  }
  final placements = mergeCollageLayout(
    decodeCollageLayout(outfit.collageLayout),
    clothingIds,
  );
  final pieces = [
    for (final placement in placements)
      if (images[placement.clothingItemId] != null)
        CollagePiece(path: images[placement.clothingItemId]!, placement: placement),
  ];
  return OutfitCoverModel(
    usesCollage: outfitUsesCollage(
      imagePath: outfit.imagePath,
      coverMode: outfit.coverMode,
      hasPieces: pieces.isNotEmpty,
    ),
    pieces: pieces,
  );
}

class OutfitSortNotifier extends Notifier<ListSort> {
  @override
  ListSort build() => ListSort.outfitDefault;

  void set(ListSort next) => state = next;
}

/// Cutout PNG from click segmentation when the clothing item has one.
final clothingCutoutsProvider = Provider<Map<String, String>>((ref) {
  final clothes = ref.watch(clothingItemsProvider).asData?.value ?? const <ClothingItem>[];
  final rows =
      ref.watch(clothingImageRowsProvider).asData?.value ?? const <ClothingItemImage>[];
  final byItem = <String, List<ClothingItemImage>>{};
  for (final row in rows) {
    (byItem[row.itemId] ??= []).add(row);
  }
  final paths = <String, String>{};
  for (final item in clothes) {
    final path = preferCutoutPath(
      imagePath: item.imagePath,
      images: [
        for (final row in byItem[item.id] ?? const <ClothingItemImage>[])
          (role: row.role, isPrimary: row.isPrimary, processedPath: row.processedPath),
      ],
    );
    if (path != null) paths[item.id] = path;
  }
  return paths;
});

final outfitSortProvider =
    NotifierProvider<OutfitSortNotifier, ListSort>(OutfitSortNotifier.new);
