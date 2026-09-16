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
import 'package:wardrobe/features/wardrobe/category_item_dialogs.dart';
import 'package:wardrobe/features/wardrobe/wardrobe_page.dart';
import 'package:wardrobe/widgets/common.dart';

class CategoryItemsPage extends ConsumerStatefulWidget {
  const CategoryItemsPage({super.key, required this.categoryId});

  final String categoryId;

  @override
  ConsumerState<CategoryItemsPage> createState() => _CategoryItemsPageState();
}

class _CategoryItemsPageState extends ConsumerState<CategoryItemsPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _resetCover() {
    return ref.read(categoryCoverRepositoryProvider).setCover(
          kind: CategoryKind.clothing,
          categoryId: widget.categoryId,
          itemId: null,
        );
  }

  Future<void> _addChild(List<ClothingItem> directItems) async {
    final result = await promptAddSubcategory(context, items: directItems);
    if (result == null || !mounted) return;
    try {
      final id = await ref.read(categoryRepositoryProvider).add(
            parentId: widget.categoryId,
            label: result.label,
          );
      if (result.itemIds.isNotEmpty) {
        await ref.read(itemRepositoryProvider).moveToCategory(result.itemIds, id);
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
    final categories = ref.watch(clothingCategoryRowsProvider);
    final category = categoryById(categories, widget.categoryId);
    final asyncItems = ref.watch(clothingItemsProvider);
    final covers = ref.watch(categoryCoverRowsProvider);
    final customCoverId = coverItemIdOf(
      covers,
      CategoryKind.clothing,
      widget.categoryId,
    );

    if (category == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: TextButton(
            onPressed: () => context.go('/wardrobe'),
            child: const Text('找不到这个分类，返回衣橱'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: AddFab(
        onPressed: () =>
            context.push('/wardrobe/item/new?category=${widget.categoryId}'),
      ),
      body: asyncItems.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (all) {
          final sort = ref.watch(clothingSortProvider);
          final q = _query.trim().toLowerCase();
          final children = childrenOf(categories, widget.categoryId)
              .where((child) => q.isEmpty || child.label.toLowerCase().contains(q))
              .toList();
          final directItems = itemsDirectlyIn(all, widget.categoryId);
          final items = sortClothingItems(
            directItems.where((item) {
              if (q.isEmpty) return true;
              final hay = [item.type, item.style, item.brand, item.note, item.tags]
                  .join(' ')
                  .toLowerCase();
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
                          context.go('/wardrobe');
                        } else {
                          context.go('/wardrobe/c/$parentId');
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
                      fields: ListSort.clothingFields,
                      onChanged: (next) =>
                          ref.read(clothingSortProvider.notifier).set(next),
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
                              '这个分类还没有衣物',
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
                                itemsInSubtree(all, categories, child.id);
                            final cover = pickCoverItem(
                              items: inTree,
                              idOf: (i) => i.id,
                              createdAt: (i) => i.createdAt,
                              coverItemId: coverItemIdOf(
                                covers,
                                CategoryKind.clothing,
                                child.id,
                              ),
                            );
                            return CategoryCard(
                              label: child.label,
                              count: inTree.length,
                              coverPath: cover?.imagePath,
                              onTap: () =>
                                  openClothingCategory(context, child.id),
                            );
                          }
                          final item = items[index - children.length];
                          return ItemTile(
                            coverPath: item.imagePath,
                            title: item.type.isEmpty ? '未命名' : item.type,
                            subtitle: item.brand,
                            isCover: customCoverId == item.id,
                            onTap: () =>
                                context.push('/wardrobe/item/${item.id}'),
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
