import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wardrobe/core/catalog/providers.dart';
import 'package:wardrobe/features/wardrobe/providers.dart';
import 'package:wardrobe/core/catalog/catalogs.dart';
import 'package:wardrobe/core/catalog/category_tree.dart';
import 'package:wardrobe/core/db/app_database.dart';
import 'package:wardrobe/core/sort.dart';
import 'package:wardrobe/core/theme.dart';
import 'package:wardrobe/core/catalog/cover_repository.dart';
import 'package:wardrobe/widgets/common.dart';

class WardrobePage extends ConsumerStatefulWidget {
  const WardrobePage({super.key});

  @override
  ConsumerState<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends ConsumerState<WardrobePage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(ClothingItem item, List<Category> categories, String q) {
    final hay = [
      item.type,
      item.style,
      item.brand,
      item.note,
      item.color,
      item.tags,
      categoryPath(categories, item.categoryId),
    ].join(' ').toLowerCase();
    return hay.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(clothingItemsProvider);
    final categories = ref.watch(clothingCategoryRowsProvider);
    final covers = ref.watch(categoryCoverRowsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: AddFab(
        onPressed: () => context.push('/wardrobe/item/new'),
      ),
      body: asyncItems.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (items) {
          final q = _query.trim().toLowerCase();
          final searching = q.isNotEmpty;
          final matched = searching
              ? sortClothingItems(
                  items.where((i) => _matches(i, categories, q)),
                  ListSort.clothingDefault,
                )
              : items;

          return Column(
            children: [
              PageHeader(
                title: '我的衣橱',
                leading: AppSearchField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                ),
                trailing: TextButton.icon(
                  onPressed: () => context.push('/wardrobe/categories'),
                  icon: const Icon(Icons.account_tree_outlined, size: 18),
                  label: const Text('分类管理'),
                ),
              ),
              Expanded(
                child: searching
                    ? _ItemSearchGrid(items: matched, categories: categories)
                    : _CategoryGrid(
                        items: items,
                        categories: categories,
                        covers: covers,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

void openClothingCategory(BuildContext context, String categoryId) {
  context.push('/wardrobe/c/$categoryId');
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.items,
    required this.categories,
    required this.covers,
  });

  final List<ClothingItem> items;
  final List<Category> categories;
  final List<CategoryCover> covers;

  @override
  Widget build(BuildContext context) {
    final roots = clothingRoots(categories);
    if (roots.isEmpty) {
      return const Center(
        child: Text('还没有分类', style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 88),
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
          idOf: (i) => i.id,
          createdAt: (i) => i.createdAt,
          coverItemId: coverItemIdOf(covers, CategoryKind.clothing, category.id),
        );
        return CategoryCard(
          label: category.label,
          count: inTree.length,
          coverPath: cover?.imagePath,
          onTap: () => openClothingCategory(context, category.id),
        );
      },
    );
  }
}

class _ItemSearchGrid extends StatelessWidget {
  const _ItemSearchGrid({required this.items, required this.categories});

  final List<ClothingItem> items;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('没有匹配的衣物', style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 88),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 22,
        crossAxisSpacing: 22,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ItemTile(
          coverPath: item.imagePath,
          title: item.type.isEmpty
              ? categoryPath(categories, item.categoryId)
              : item.type,
          subtitle: item.brand,
          onTap: () => context.push('/wardrobe/item/${item.id}'),
        );
      },
    );
  }
}
