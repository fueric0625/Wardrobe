import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wardrobe/core/catalog/providers.dart';
import 'package:wardrobe/features/outfits/providers.dart';
import 'package:wardrobe/core/catalog/catalogs.dart';
import 'package:wardrobe/core/catalog/category_tree.dart';
import 'package:wardrobe/core/db/app_database.dart';
import 'package:wardrobe/core/sort.dart';
import 'package:wardrobe/core/theme.dart';
import 'package:wardrobe/core/catalog/cover_repository.dart';
import 'package:wardrobe/features/outfits/outfits_page.dart';
import 'package:wardrobe/core/catalog/category_item_dialogs.dart';
import 'package:wardrobe/widgets/common.dart';
import 'package:wardrobe/widgets/piece_collage.dart';

class OutfitCategoryPage extends ConsumerStatefulWidget {
  const OutfitCategoryPage({super.key, required this.categoryId});

  final String categoryId;

  @override
  ConsumerState<OutfitCategoryPage> createState() => _OutfitCategoryPageState();
}

class _OutfitCategoryPageState extends ConsumerState<OutfitCategoryPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _resetCover() {
    return ref.read(categoryCoverRepositoryProvider).setCover(
          kind: CategoryKind.outfit,
          categoryId: widget.categoryId,
          itemId: null,
        );
  }

  Future<void> _addChild(List<Outfit> directItems) async {
    final result = await promptAddSubcategory(
      context,
      pickHint: '把当前分类里的穿搭移入（可选）',
      items: [
        for (final item in directItems)
          CategoryPickItem(
            id: item.id,
            imagePath: item.imagePath,
            cover: outfitCoverArt(ref.read(outfitCoversProvider)[item.id]),
            label: item.name.trim().isEmpty ? '未命名' : item.name.trim(),
          ),
      ],
    );
    if (result == null || !mounted) return;
    try {
      final id = await ref.read(categoryRepositoryProvider).add(
            kind: CategoryKind.outfit,
            parentId: widget.categoryId,
            label: result.label,
          );
      if (result.itemIds.isNotEmpty) {
        await ref.read(outfitRepositoryProvider).moveToCategory(result.itemIds, id);
      }
      if (!mounted) return;
      final moved = result.itemIds.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            moved == 0
                ? '已添加「${result.label}」'
                : '已添加「${result.label}」，移入 $moved 件',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is StateError
          ? e.message
          : e is ArgumentError
              ? (e.message?.toString() ?? '$e')
              : '$e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(outfitCategoryRowsProvider);
    final category = categoryById(categories, widget.categoryId);
    final asyncItems = ref.watch(outfitsProvider);
    final covers = ref.watch(categoryCoverRowsProvider);
    final coversById = ref.watch(outfitCoversProvider);
    final customCoverId = coverItemIdOf(
      covers,
      CategoryKind.outfit,
      widget.categoryId,
    );

    if (category == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: TextButton(
            onPressed: () => context.go('/outfits'),
            child: const Text('找不到这个分类，返回穿搭'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: AddFab(
        onPressed: () =>
            context.push('/outfits/item/new?category=${widget.categoryId}'),
      ),
      body: asyncItems.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (all) {
          final sort = ref.watch(outfitSortProvider);
          final q = _query.trim().toLowerCase();
          final children = childrenOf(categories, widget.categoryId)
              .where((child) => q.isEmpty || child.label.toLowerCase().contains(q))
              .toList();
          final directItems = outfitsDirectlyIn(all, widget.categoryId);
          final items = sortOutfits(
            directItems.where((item) {
              if (q.isEmpty) return true;
              final hay = [item.name, item.note, item.season].join(' ').toLowerCase();
              return hay.contains(q);
            }),
            sort,
          );

          return Column(
            children: [
              PageHeader(
                title: category.label,
                leading: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        final parentId = category.parentId;
                        if (parentId == null) {
                          context.go('/outfits');
                        } else {
                          context.go('/outfits/c/$parentId');
                        }
                      },
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    ),
                    AppSearchField(
                      controller: _search,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canAddChild(categories, category))
                      TextButton.icon(
                        onPressed: () => _addChild(directItems),
                        icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                        label: const Text('添加子分类'),
                      ),
                    if (customCoverId != null)
                      TextButton(
                        onPressed: () async {
                          await _resetCover();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已恢复为最新添加的单品')),
                          );
                        },
                        child: const Text('恢复默认封面'),
                      ),
                    SortButton(
                      value: sort,
                      fields: ListSort.outfitFields,
                      onChanged: (next) =>
                          ref.read(outfitSortProvider.notifier).set(next),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: children.isEmpty && items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '这个分类还没有穿搭',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                            if (canAddChild(categories, category)) ...[
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () => _addChild(directItems),
                                icon: const Icon(
                                  Icons.create_new_folder_outlined,
                                  size: 18,
                                ),
                                label: const Text('添加子分类'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(32, 8, 32, 88),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          mainAxisSpacing: 22,
                          crossAxisSpacing: 22,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: children.length + items.length,
                        itemBuilder: (context, index) {
                          if (index < children.length) {
                            final child = children[index];
                            final inTree =
                                outfitsInSubtree(all, categories, child.id);
                            final cover = pickCoverItem(
                              items: inTree,
                              idOf: (i) => i.id,
                              createdAt: (i) => i.createdAt,
                              coverItemId: coverItemIdOf(
                                covers,
                                CategoryKind.outfit,
                                child.id,
                              ),
                            );
                            return CategoryCard(
                              label: child.label,
                              count: inTree.length,
                              coverPath: cover?.imagePath,
                              cover: outfitCoverArt(cover == null ? null : coversById[cover.id]),
                              onTap: () => openOutfitCategory(context, child.id),
                            );
                          }
                          final item = items[index - children.length];
                          return ItemTile(
                            coverPath: item.imagePath,
                            cover: outfitCoverArt(coversById[item.id]),
                            title: item.name.isEmpty ? '未命名' : item.name,
                            subtitle: item.season,
                            isCover: customCoverId == item.id,
                            onTap: () =>
                                context.push('/outfits/item/${item.id}'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
