import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wardrobe/core/catalog/providers.dart';
import 'package:wardrobe/core/catalog/catalogs.dart';
import 'package:wardrobe/core/catalog/category_tree.dart';
import 'package:wardrobe/core/db/app_database.dart';
import 'package:wardrobe/core/theme.dart';
import 'package:wardrobe/core/catalog/cover_repository.dart';
import 'package:wardrobe/widgets/common.dart';

class AddSubcategoryResult {
  const AddSubcategoryResult({required this.label, this.itemIds = const []});

  final String label;
  final List<String> itemIds;
}

class CategoryPickItem {
  const CategoryPickItem({
    required this.id,
    required this.label,
    this.imagePath,
    this.cover,
  });

  final String id;
  final String label;
  final String? imagePath;
  final Widget? cover;
}

Future<AddSubcategoryResult?> promptAddSubcategory(
  BuildContext context, {
  List<CategoryPickItem> items = const [],
  String pickHint = '把当前分类里的衣物移入（可选）',
}) async {
  final controller = TextEditingController();
  final selected = <String>{};
  final result = await showDialog<AddSubcategoryResult>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: items.isEmpty ? 400 : 520,
                maxHeight: MediaQuery.sizeOf(context).height * 0.82,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '添加子分类',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(fontSize: 14, color: AppColors.text),
                      onSubmitted: (value) {
                        final label = value.trim();
                        if (label.isEmpty) return;
                        Navigator.pop(
                          context,
                          AddSubcategoryResult(
                            label: label,
                            itemIds: selected.toList(),
                          ),
                        );
                      },
                      decoration: const InputDecoration(
                        hintText: '分类名称',
                        hintStyle: TextStyle(fontSize: 14, color: AppColors.textMuted),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    if (items.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        selected.isEmpty
                            ? pickHint
                            : '已选 ${selected.length} 件',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: GridView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 92,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.82,
                          ),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final checked = selected.contains(item.id);
                            return _SelectableItemThumb(
                              item: item,
                              selected: checked,
                              onTap: () => setState(() {
                                if (checked) {
                                  selected.remove(item.id);
                                } else {
                                  selected.add(item.id);
                                }
                              }),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                        FilledButton(
                          onPressed: () {
                            final label = controller.text.trim();
                            if (label.isEmpty) return;
                            Navigator.pop(
                              context,
                              AddSubcategoryResult(
                                label: label,
                                itemIds: selected.toList(),
                              ),
                            );
                          },
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
  controller.dispose();
  return result;
}

Future<Category?> promptMoveToCategory(
  BuildContext context, {
  required List<Category> categories,
  required String currentId,
}) {
  final rows = flattenPreorder(categories);
  if (rows.isEmpty) return Future.value();
  return showDialog<Category>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '移动到',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final category = rows[index];
                    final depth = categoryDepth(categories, category);
                    final current = category.id == currentId;
                    return Material(
                      color: current ? AppColors.primarySoft : AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: current ? null : () => Navigator.pop(context, category),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(12.0 + depth * 22, 10, 12, 10),
                          child: Row(
                            children: [
                              Icon(
                                depth == 0
                                    ? Icons.folder_outlined
                                    : Icons.subdirectory_arrow_right,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  category.label,
                                  style: TextStyle(
                                    fontWeight: depth == 0
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                              if (current)
                                const Text(
                                  '当前',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SelectableItemThumb extends StatelessWidget {
  const _SelectableItemThumb({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final CategoryPickItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Material(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.cover ?? LocalCover(path: item.imagePath),
                  if (selected)
                    const ColoredBox(color: Color(0x665B6CFF)),
                  if (selected)
                    const Align(
                      child: Icon(Icons.check_circle, color: Colors.white, size: 22),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.text),
        ),
      ],
    );
  }
}

class CategoryCoverActions extends ConsumerWidget {
  const CategoryCoverActions({
    super.key,
    required this.itemId,
    required this.kind,
    required this.covers,
    required this.targets,
  });

  final String itemId;
  final CategoryKind kind;
  final List<CategoryCover> covers;
  final List<Category> targets;

  bool _isCoverOf(String categoryId) {
    return coverItemIdOf(covers, kind, categoryId) == itemId;
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, Category category) async {
    final clearing = _isCoverOf(category.id);
    await ref.read(categoryCoverRepositoryProvider).setCover(
          kind: kind,
          categoryId: category.id,
          itemId: clearing ? null : itemId,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          clearing
              ? '已恢复「${category.label}」为最新添加的单品'
              : '已设为「${category.label}」封面',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (targets.isEmpty) return const SizedBox.shrink();
    if (targets.length == 1) {
      final category = targets.first;
      final isCover = _isCoverOf(category.id);
      return TextButton(
        onPressed: () => _toggle(context, ref, category),
        child: Text(isCover ? '恢复默认' : '设为封面'),
      );
    }

    final anyCover = targets.any((category) => _isCoverOf(category.id));
    return PopupMenuButton<String>(
      tooltip: '设为封面',
      offset: const Offset(0, 8),
      onSelected: (id) {
        final category = targets.firstWhere((c) => c.id == id);
        _toggle(context, ref, category);
      },
      itemBuilder: (context) => [
        for (final category in targets)
          CheckedPopupMenuItem<String>(
            value: category.id,
            checked: _isCoverOf(category.id),
            child: Text('「${category.label}」封面'),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              anyCover ? '封面设置' : '设为封面',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
