import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wardrobe/app/providers.dart';
import 'package:wardrobe/core/catalogs.dart';
import 'package:wardrobe/core/theme.dart';
import 'package:wardrobe/data/cover_repository.dart';
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

        final category = outfitCategoryById(item.categoryId);
        final title = item.name.trim().isEmpty ? '穿搭详情' : item.name.trim();
        final season = item.season
            .split(RegExp(r'[,，\s]+'))
            .where((s) => s.isNotEmpty)
            .join('、');
        final isCover =
            coverItemIdOf(covers, CategoryKind.outfit, item.categoryId) == item.id;

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
                    TextButton(
                      onPressed: () async {
                        await ref.read(categoryCoverRepositoryProvider).setCover(
                              kind: CategoryKind.outfit,
                              categoryId: item.categoryId,
                              itemId: isCover ? null : item.id,
                            );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isCover
                                  ? '已恢复为最新添加的单品'
                                  : '已设为「${category.label}」封面',
                            ),
                          ),
                        );
                      },
                      child: Text(isCover ? '恢复默认' : '设为封面'),
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
                              ReadOnlyField(label: '场合', value: category.label),
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

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/outfits');
    }
  }
}
