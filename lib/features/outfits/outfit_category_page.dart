import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wardrobe/app/providers.dart';
import 'package:wardrobe/core/catalogs.dart';
import 'package:wardrobe/core/sort.dart';
import 'package:wardrobe/core/theme.dart';
import 'package:wardrobe/data/cover_repository.dart';
import 'package:wardrobe/widgets/common.dart';

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

  @override
  Widget build(BuildContext context) {
    final category = outfitCategoryById(widget.categoryId);
    final asyncItems = ref.watch(outfitsProvider);
    final covers = ref.watch(categoryCoverRowsProvider);
    final customCoverId = coverItemIdOf(
      covers,
      CategoryKind.outfit,
      widget.categoryId,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: AddFab(
        onPressed: () => context.push('/outfits/item/new?category=${widget.categoryId}'),
      ),
      body: asyncItems.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (all) {
          final sort = ref.watch(outfitSortProvider);
          final q = _query.trim().toLowerCase();
          final items = sortOutfits(
            all.where((item) {
              if (item.categoryId != widget.categoryId) return false;
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
                      onPressed: () => context.go('/outfits'),
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
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          '这个分类还没有穿搭',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : GridView.builder(
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
                            title: item.name.isEmpty ? '未命名' : item.name,
                            subtitle: item.season,
                            isCover: customCoverId == item.id,
                            onTap: () => context.push('/outfits/item/${item.id}'),
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
