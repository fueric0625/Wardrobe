import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wardrobe/app/providers.dart';
import 'package:wardrobe/core/catalogs.dart';
import 'package:wardrobe/core/category_tree.dart';
import 'package:wardrobe/core/db/app_database.dart';
import 'package:wardrobe/core/theme.dart';
import 'package:wardrobe/features/wardrobe/category_item_dialogs.dart';
import 'package:wardrobe/widgets/common.dart';

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
                  const Text('找不到这套穿搭', style: TextStyle(color: AppColors.textMuted)),
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
        final coverTargets = coverCategoriesForItem(categories, item.categoryId);
        final season = item.season
            .split(RegExp(r'[,，\s]+'))
            .where((s) => s.isNotEmpty)
            .join('、');

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
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                      onPressed: () => context.push('/outfits/item/${item.id}/edit'),
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
                          child: DetailHeroImage(path: item.imagePath),
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
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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
