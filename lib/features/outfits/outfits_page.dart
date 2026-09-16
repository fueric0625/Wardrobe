import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wardrobe/app/providers.dart';
import 'package:wardrobe/core/catalogs.dart';
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

  bool _matches(Outfit item, String q) {
    final hay = [
      item.name,
      item.note,
      item.season,
      outfitCategoryById(item.categoryId).label,
    ].join(' ').toLowerCase();
    return hay.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(outfitsProvider);
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
          final sort = ref.watch(outfitSortProvider);
          final q = _query.trim().toLowerCase();
          final searching = q.isNotEmpty;
          final matched = searching
              ? sortOutfits(items.where((i) => _matches(i, q)), sort)
              : items;

          return Column(
            children: [
              PageHeader(
                title: '我的穿搭',
                leading: AppSearchField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                ),
                trailing: SortButton(
                  value: sort,
                  fields: ListSort.outfitFields,
                  onChanged: (next) =>
                      ref.read(outfitSortProvider.notifier).set(next),
                ),
              ),
              Expanded(
                child: searching
                    ? _OutfitSearchGrid(items: matched)
                    : _CategoryGrid(items: items, covers: covers),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.items, required this.covers});

  final List<Outfit> items;
  final List<CategoryCover> covers;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 88),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 22,
        crossAxisSpacing: 22,
        childAspectRatio: 0.86,
      ),
      itemCount: outfitCategories.length,
      itemBuilder: (context, index) {
        final category = outfitCategories[index];
        final inCategory = items.where((i) => i.categoryId == category.id);
        final cover = pickCoverItem(
          items: inCategory,
          idOf: (i) => i.id,
          createdAt: (i) => i.createdAt,
          coverItemId: coverItemIdOf(covers, CategoryKind.outfit, category.id),
        );
        return CategoryCard(
          label: category.label,
          count: inCategory.length,
          coverPath: cover?.imagePath,
          onTap: () {
            if (inCategory.isEmpty) {
              context.push('/outfits/item/new?category=${category.id}');
            } else {
              context.push('/outfits/c/${category.id}');
            }
          },
        );
      },
    );
  }
}

class _OutfitSearchGrid extends StatelessWidget {
  const _OutfitSearchGrid({required this.items});

  final List<Outfit> items;

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
          title: item.name.isEmpty ? outfitCategoryById(item.categoryId).label : item.name,
          subtitle: item.season,
          onTap: () => context.push('/outfits/item/${item.id}'),
        );
      },
    );
  }
}
