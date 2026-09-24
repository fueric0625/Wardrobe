import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wardrobe/core/catalog/catalogs.dart';
import 'package:wardrobe/core/catalog/category_tree.dart';
import 'package:wardrobe/core/catalog/providers.dart';
import 'package:wardrobe/core/design_system/theme.dart';
import 'package:wardrobe/features/outfits/presentation/outfit_edit_controller.dart';
import 'package:wardrobe/features/outfits/providers.dart';
import 'package:wardrobe/widgets/common.dart';
import 'package:wardrobe/widgets/piece_collage.dart';

class OutfitDetailStep extends ConsumerWidget {
  const OutfitDetailStep({
    super.key,
    required this.editKey,
    required this.onDeletePhoto,
    required this.onDeleteCollage,
  });

  final OutfitEditKey editKey;
  final Future<void> Function() onDeletePhoto;
  final Future<void> Function() onDeleteCollage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(outfitEditControllerProvider(editKey));
    final controller = ref.read(outfitEditControllerProvider(editKey).notifier);
    final categories = ref.watch(outfitCategoryRowsProvider);
    ref.watch(clothingCutoutsProvider);
    final selectedId =
        categoryById(categories, state.categoryId)?.id ??
        (categories.isEmpty ? state.categoryId : uncategorizedClothingId);
    final collage = controller.collage(honorRemoval: true);
    final hasPhoto = state.displayPath != null && state.displayPath!.isNotEmpty;
    final showCollage = collage.placements.isNotEmpty;
    final cutout =
        hasPhoto && state.displayPath!.toLowerCase().endsWith('.png');
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 280,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (!hasPhoto && !showCollage)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Text(
                        '还没有封面',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  if (hasPhoto)
                    LabeledCoverCard(
                      label: '全身照',
                      onDelete: onDeletePhoto,
                      child: LocalCover(
                        path: state.displayPath,
                        fit: BoxFit.contain,
                        checkerboard: cutout,
                      ),
                    ),
                  if (hasPhoto && showCollage) const SizedBox(height: 16),
                  if (showCollage)
                    LabeledCoverCard(
                      label: '拼图',
                      onDelete: onDeleteCollage,
                      child: OutfitPieceCollage(
                        pieces: [
                          for (final placement in collage.placements)
                            if (collage.images[placement.clothingItemId] !=
                                null)
                              CollagePiece(
                                path: collage.images[placement.clothingItemId]!,
                                placement: placement,
                              ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '分类',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (categories.isEmpty)
                      const Text(
                        '暂无分类',
                        style: TextStyle(color: AppColors.textMuted),
                      )
                    else
                      DropdownButtonFormField<String>(
                        key: ValueKey(selectedId),
                        initialValue: selectedId,
                        items: [
                          for (final category in flattenPreorder(categories))
                            DropdownMenuItem(
                              value: category.id,
                              child: Text(
                                categoryPath(categories, category.id),
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) controller.setCategory(value);
                        },
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      '名称',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller.name,
                      decoration: const InputDecoration(hintText: '给这套穿搭起个名字'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '季节',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final season in seasons)
                          FilterChip(
                            label: Text(season),
                            selected: state.seasons.contains(season),
                            selectedColor: AppPalette.of(context).primarySoft,
                            checkmarkColor: AppPalette.of(context).primary,
                            onSelected: (on) =>
                                controller.toggleSeason(season, on: on),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '备注',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller.note,
                      maxLines: 5,
                      decoration: const InputDecoration(hintText: '输入备注信息'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.clothingIds.isEmpty
                          ? '未关联衣物'
                          : '已关联 ${state.clothingIds.length} 件衣物',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
