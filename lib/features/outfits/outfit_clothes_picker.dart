import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wardrobe/core/catalog/catalogs.dart';
import 'package:wardrobe/core/catalog/category_tree.dart';
import 'package:wardrobe/core/catalog/cover_repository.dart';
import 'package:wardrobe/core/catalog/providers.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/sort.dart';
import 'package:wardrobe/core/design_system/theme.dart';
import 'package:wardrobe/features/wardrobe/providers.dart';
import 'package:wardrobe/widgets/common.dart';

/// Pick wardrobe clothes for an outfit: a top category, then a filtered grid.
class OutfitClothesPicker extends ConsumerWidget {
  const OutfitClothesPicker({
    super.key,
    required this.selectedIds,
    required this.onToggle,
    required this.rootId,
    required this.filterId,
    required this.onOpenRoot,
    required this.onBackToRoots,
    required this.onFilter,
  });

  final List<String> selectedIds;
  final ValueChanged<String> onToggle;
  final String? rootId;
  final String? filterId;
  final ValueChanged<String> onOpenRoot;
  final VoidCallback onBackToRoots;
  final ValueChanged<String?> onFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(clothingItemsProvider);
    final categories = ref.watch(clothingCategoryRowsProvider);
    final covers = ref.watch(categoryCoverRowsProvider);

    return asyncItems.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (items) {
        final root = rootId == null ? null : categoryById(categories, rootId!);
        if (root == null) {
          return _RootGrid(
            items: items,
            categories: categories,
            covers: covers,
            onOpen: onOpenRoot,
          );
        }
        final filters = childrenOf(categories, root.id);
        final scope = filterId ?? root.id;
        final shown = List<ClothingItem>.of(
          itemsInSubtree(items, categories, scope),
        )..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: onBackToRoots,
                    icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                    label: Text(root.label),
                  ),
                  const Spacer(),
                  Text(
                    '已选 ${selectedIds.length} 件',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (filters.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('全部'),
                        selected: filterId == null,
                        selectedColor: AppPalette.of(context).primarySoft,
                        checkmarkColor: AppPalette.of(context).primary,
                        onSelected: (_) => onFilter(null),
                      ),
                    ),
                    for (final child in filters)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(child.label),
                          selected: filterId == child.id,
                          selectedColor: AppPalette.of(context).primarySoft,
                          checkmarkColor: AppPalette.of(context).primary,
                          onSelected: (_) => onFilter(child.id),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: shown.isEmpty
                  ? const Center(
                      child: Text(
                        '这个分类里还没有衣物',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisSpacing: 22,
                            crossAxisSpacing: 22,
                            childAspectRatio: 0.82,
                          ),
                      itemCount: shown.length,
                      itemBuilder: (context, index) {
                        final item = shown[index];
                        final title = item.productName.trim().isNotEmpty
                            ? item.productName.trim()
                            : item.type.trim().isEmpty
                            ? categoryPath(categories, item.categoryId)
                            : item.type.trim();
                        return ItemTile(
                          coverPath: item.imagePath,
                          title: title,
                          subtitle: item.brand,
                          selected: selectedIds.contains(item.id),
                          onTap: () => onToggle(item.id),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _RootGrid extends StatelessWidget {
  const _RootGrid({
    required this.items,
    required this.categories,
    required this.covers,
    required this.onOpen,
  });

  final List<ClothingItem> items;
  final List<Category> categories;
  final List<CategoryCover> covers;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final roots = clothingRoots(categories);
    if (roots.isEmpty) {
      return const Center(
        child: Text('衣橱里还没有分类', style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 22,
        crossAxisSpacing: 22,
        childAspectRatio: 0.86,
      ),
      itemCount: roots.length,
      itemBuilder: (context, index) {
        final category = roots[index];
        final inTree = itemsInSubtree(items, categories, category.id);
        final cover = pickCoverItem(
          items: inTree,
          idOf: (item) => item.id,
          createdAt: (item) => item.createdAt,
          coverItemId: coverItemIdOf(
            covers,
            CategoryKind.clothing,
            category.id,
          ),
        );
        return CategoryCard(
          label: category.label,
          count: inTree.length,
          coverPath: cover?.imagePath,
          onTap: () => onOpen(category.id),
        );
      },
    );
  }
}
