import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wardrobe/core/catalog/providers.dart';
import 'package:wardrobe/features/outfits/providers.dart';
import 'package:wardrobe/core/catalog/catalogs.dart';
import 'package:wardrobe/core/catalog/category_tree.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/design_system/theme.dart';
import 'package:wardrobe/core/catalog/category_item_dialogs.dart';
import 'package:wardrobe/features/wardrobe/providers.dart';
import 'package:wardrobe/widgets/common.dart';
import 'package:wardrobe/widgets/piece_collage.dart';
import 'package:wardrobe/widgets/zoom_viewport.dart';

class OutfitDetailPage extends ConsumerWidget {
  const OutfitDetailPage({super.key, required this.outfitId});

  final String outfitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(outfitsProvider);
    final covers = ref.watch(categoryCoverRowsProvider);

    return asyncItems.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('加载失败：$e')),
      ),
      data: (items) {
        final item = items.where((i) => i.id == outfitId).firstOrNull;
        if (item == null) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '找不到这套穿搭',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _back(context),
                    child: const Text('返回'),
                  ),
                ],
              ),
            ),
          );
        }

        final categories = ref.watch(outfitCategoryRowsProvider);
        final title = item.name.trim().isEmpty ? '穿搭详情' : item.name.trim();
        final path = categoryPath(categories, item.categoryId);
        final coverTargets = coverCategoriesForItem(
          categories,
          item.categoryId,
        );
        final season = item.season
            .split(RegExp(r'[,，\s]+'))
            .where((s) => s.isNotEmpty)
            .join('、');
        final clothingCategories = ref.watch(clothingCategoryRowsProvider);
        final linkedIds = ref
            .watch(outfitClothingIdsProvider(item.id))
            .maybeWhen(data: (ids) => ids, orElse: () => const <String>[]);
        final clothes = ref
            .watch(clothingItemsProvider)
            .maybeWhen(
              data: (rows) => rows,
              orElse: () => const <ClothingItem>[],
            );
        final byId = {for (final piece in clothes) piece.id: piece};
        final linked = [
          for (final id in linkedIds)
            if (byId[id] != null) byId[id]!,
        ];
        final cutout = item.imagePath?.toLowerCase().endsWith('.png') ?? false;
        final hasPhoto = item.imagePath != null && item.imagePath!.isNotEmpty;
        final cover = ref.watch(outfitCoversProvider)[item.id];
        final collagePieces = cover?.pieces ?? const <CollagePiece>[];
        final hasCollage =
            !isCollageRemoved(item.collageLayout) && collagePieces.isNotEmpty;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 28, 8),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _back(context),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                      label: const Text('返回'),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    CategoryCoverActions(
                      itemId: item.id,
                      kind: CategoryKind.outfit,
                      covers: covers,
                      targets: coverTargets,
                    ),
                    TextButton(
                      onPressed: () => _move(
                        context,
                        ref,
                        item: item,
                        categories: categories,
                      ),
                      child: const Text('移动'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () =>
                          context.push('/outfits/item/${item.id}/edit'),
                      child: const Text('修改'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 320,
                          child: Column(
                            children: [
                              if (!hasPhoto && !hasCollage)
                                const Padding(
                                  padding: EdgeInsets.only(top: 48),
                                  child: Text(
                                    '还没有照片',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              if (hasPhoto)
                                LabeledCoverCard(
                                  label: '全身照',
                                  onDelete: () =>
                                      _deletePhoto(context, ref, item),
                                  child: ZoomViewport(
                                    child: LocalCover(
                                      path: item.imagePath,
                                      fit: BoxFit.contain,
                                      checkerboard: cutout,
                                    ),
                                  ),
                                ),
                              if (hasPhoto && hasCollage)
                                const SizedBox(height: 16),
                              if (hasCollage)
                                LabeledCoverCard(
                                  label: '拼图',
                                  onDelete: () =>
                                      _deleteCollage(context, ref, item.id),
                                  child: OutfitPieceCollage(
                                    pieces: collagePieces,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 28),
                        Expanded(
                          child: DetailFormCard(
                            children: [
                              ReadOnlyField(label: '分类', value: path),
                              ReadOnlyField(label: '名称', value: item.name),
                              ReadOnlyField(label: '季节', value: season),
                              ReadOnlyField(label: '备注', value: item.note),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (linked.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const Text(
                        '这套衣服',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: linked.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final piece = linked[index];
                            final title = piece.type.trim().isEmpty
                                ? categoryPath(
                                    clothingCategories,
                                    piece.categoryId,
                                  )
                                : piece.type.trim();
                            return SizedBox(
                              width: 150,
                              child: ItemTile(
                                coverPath: piece.imagePath,
                                title: title,
                                subtitle: piece.brand,
                                onTap: () =>
                                    context.push('/wardrobe/item/${piece.id}'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<bool> _confirmRemove(BuildContext context, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  static Future<void> _deletePhoto(
    BuildContext context,
    WidgetRef ref,
    Outfit item,
  ) async {
    if (!await _confirmRemove(context, '删除这张全身照？')) return;
    await ref.read(outfitRepositoryProvider).clearPhoto(item.id);
  }

  static Future<void> _deleteCollage(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    if (!await _confirmRemove(context, '删除这张拼图？')) return;
    await ref.read(outfitRepositoryProvider).clearCollage(id);
  }

  static Future<void> _move(
    BuildContext context,
    WidgetRef ref, {
    required Outfit item,
    required List<Category> categories,
  }) async {
    final dest = await promptMoveToCategory(
      context,
      categories: categories,
      currentId: item.categoryId,
    );
    if (dest == null || !context.mounted) return;
    await ref.read(outfitRepositoryProvider).moveToCategory([item.id], dest.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已移动到「${categoryPath(categories, dest.id)}」')),
    );
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/outfits');
    }
  }
}
