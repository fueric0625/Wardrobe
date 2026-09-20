import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wardrobe/app/providers.dart';
import 'package:wardrobe/core/catalogs.dart';
import 'package:wardrobe/core/category_tree.dart';
import 'package:wardrobe/core/db/app_database.dart';
import 'package:wardrobe/core/sort.dart';
import 'package:wardrobe/core/theme.dart';
import 'package:wardrobe/data/cover_repository.dart';
import 'package:wardrobe/widgets/common.dart';

class OutfitsPage extends ConsumerStatefulWidget {
  const OutfitsPage({super.key});

  @override
  ConsumerState<OutfitsPage> createState() => _OutfitsPageState();
}

class _OutfitsPageState extends ConsumerState<OutfitsPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Outfit item, List<Category> categories, String q) {
    final hay = [
      item.name,
      item.note,
      item.season,
      categoryPath(categories, item.categoryId),
    ].join(' ').toLowerCase();
    return hay.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(outfitsProvider);
    final categories = ref.watch(outfitCategoryRowsProvider);
    final covers = ref.watch(categoryCoverRowsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: AddFab(
        onPressed: () => context.push('/outfits/item/new'),
      ),
      body: asyncItems.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (items) {
          final q = _query.trim().toLowerCase();
          final searching = q.isNotEmpty;
          final matched = searching
              ? sortOutfits(
                  items.where((i) => _matches(i, categories, q)),
                  ListSort.outfitDefault,
                )
              : items;

          return Column(
            children: [
              PageHeader(
                title: '我的穿搭',
                leading: AppSearchField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                ),
                trailing: TextButton.icon(
                  onPressed: () => context.push('/outfits/categories'),
                  icon: const Icon(Icons.account_tree_outlined, size: 18),
                  label: const Text('分类管理'),
                ),
              ),
              Expanded(
                child: searching
                    ? _OutfitSearchGrid(items: matched, categories: categories)
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

void openOutfitCategory(BuildContext context, String categoryId) {
  context.push('/outfits/c/$categoryId');
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.items,
    required this.categories,
    required this.covers,
  });

  final List<Outfit> items;
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
        final inTree = outfitsInSubtree(items, categories, category.id);
        final cover = pickCoverItem(
          items: inTree,
          idOf: (i) => i.id,
          createdAt: (i) => i.createdAt,
          coverItemId: coverItemIdOf(covers, CategoryKind.outfit, category.id),
        );
        return CategoryCard(
          label: category.label,
          count: inTree.length,
          coverPath: cover?.imagePath,
          onTap: () => openOutfitCategory(context, category.id),
        );
      },
    );
  }
}

class _OutfitSearchGrid extends StatelessWidget {
  const _OutfitSearchGrid({required this.items, required this.categories});

  final List<Outfit> items;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('没有匹配的穿搭', style: TextStyle(color: AppColors.textMuted)),
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
          title: item.name.isEmpty
              ? categoryPath(categories, item.categoryId)
              : item.name,
          subtitle: item.season,
          onTap: () => context.push('/outfits/item/${item.id}'),
        );
      },
    );
  }
}
