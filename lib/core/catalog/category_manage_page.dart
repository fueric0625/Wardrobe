import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wardrobe/core/catalog/providers.dart';
import 'package:wardrobe/core/catalog/catalogs.dart';
import 'package:wardrobe/core/catalog/category_tree.dart';
import 'package:wardrobe/core/db/app_database.dart';
import 'package:wardrobe/core/theme.dart';

class CategoryManagePage extends ConsumerWidget {
  const CategoryManagePage({super.key, required this.kind});

  final CategoryKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCats = kind == CategoryKind.clothing
        ? ref.watch(clothingCategoriesProvider)
        : ref.watch(outfitCategoriesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: asyncCats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (categories) {
          final rows = flattenPreorder(categories);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 28, 8),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                      label: const Text('返回'),
                    ),
                    const Expanded(
                      child: Text(
                        '分类管理',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _addRoot(context, ref, kind),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('新增大分类'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final category = rows[index];
                    final depth = categoryDepth(categories, category);
                    final siblings = childrenOf(categories, category.parentId);
                    final siblingIndex =
                        siblings.indexWhere((c) => c.id == category.id);
                    return _CategoryRow(
                      category: category,
                      depth: depth,
                      canMoveUp: siblingIndex > 0,
                      canMoveDown: siblingIndex >= 0 &&
                          siblingIndex < siblings.length - 1,
                      canAddChild: canAddChild(categories, category),
                      onRename: () => _rename(context, ref, kind, category),
                      onAddChild: () => _addChild(context, ref, kind, category),
                      onDelete: () =>
                          _delete(context, ref, kind, categories, category),
                      onMove: (delta) => ref
                          .read(categoryRepositoryProvider)
                          .moveSibling(kind, category.id, delta),
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

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.depth,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.canAddChild,
    required this.onRename,
    required this.onAddChild,
    required this.onDelete,
    required this.onMove,
  });

  final Category category;
  final int depth;
  final bool canMoveUp;
  final bool canMoveDown;
  final bool canAddChild;
  final VoidCallback onRename;
  final VoidCallback onAddChild;
  final VoidCallback onDelete;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.0 + depth * 24, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            depth == 0 ? Icons.folder_outlined : Icons.subdirectory_arrow_right,
            size: 20,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              category.label,
              style: TextStyle(
                fontWeight: depth == 0 ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            tooltip: '上移',
            onPressed: canMoveUp ? () => onMove(-1) : null,
            icon: const Icon(Icons.keyboard_arrow_up),
          ),
          IconButton(
            tooltip: '下移',
            onPressed: canMoveDown ? () => onMove(1) : null,
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
          TextButton(onPressed: onRename, child: const Text('改名')),
          if (canAddChild)
            TextButton(onPressed: onAddChild, child: const Text('添加子分类')),
          if (!category.isSystem)
            TextButton(
              onPressed: onDelete,
              child: const Text('删除', style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
    );
  }
}

String _itemNoun(CategoryKind kind) =>
    kind == CategoryKind.outfit ? '穿搭' : '衣物';

Future<void> _addRoot(
  BuildContext context,
  WidgetRef ref,
  CategoryKind kind,
) async {
  final result = await _promptNewRoot(context, kind);
  if (result == null) return;
  if (!context.mounted) return;
  await _run(context, () {
    return ref.read(categoryRepositoryProvider).add(
          kind: kind,
          label: result.label,
          sizeFields: result.fields,
        );
  });
}

Future<void> _addChild(
  BuildContext context,
  WidgetRef ref,
  CategoryKind kind,
  Category parent,
) async {
  final label = await _promptName(context, title: '添加子分类');
  if (label == null) return;
  if (!context.mounted) return;
  await _run(context, () {
    return ref.read(categoryRepositoryProvider).add(
          kind: kind,
          parentId: parent.id,
          label: label,
        );
  });
}

Future<void> _rename(
  BuildContext context,
  WidgetRef ref,
  CategoryKind kind,
  Category category,
) async {
  final label = await _promptName(
    context,
    title: '修改名称',
    initial: category.label,
  );
  if (label == null) return;
  if (!context.mounted) return;
  await _run(context, () {
    return ref.read(categoryRepositoryProvider).rename(kind, category.id, label);
  });
}

Future<void> _run(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_errorText(e))),
    );
  }
}

String _errorText(Object error) {
  if (error is ArgumentError) return error.message?.toString() ?? '$error';
  if (error is StateError) return error.message;
  return '$error';
}

Future<void> _delete(
  BuildContext context,
  WidgetRef ref,
  CategoryKind kind,
  List<Category> categories,
  Category category,
) async {
  final fallbackId = itemsFallbackAfterDelete(categories, category);
  final fallbackLabel =
      categoryById(categories, fallbackId)?.label ?? '无分类';
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => _AppDialog(
      title: '删除「${category.label}」？',
      body: Text(
        '子分类会一起删除，里面的${_itemNoun(kind)}会回到「$fallbackLabel」。',
        style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.text),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await ref.read(categoryRepositoryProvider).deleteSubtree(kind, category.id);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_errorText(e))),
    );
  }
}

Future<String?> _promptName(
  BuildContext context, {
  required String title,
  String? initial,
}) async {
  final controller = TextEditingController(text: initial ?? '');
  final result = await showDialog<String>(
    context: context,
    builder: (context) => _AppDialog(
      title: title,
      body: _DialogField(
        controller: controller,
        hint: '分类名称',
        autofocus: true,
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('确定'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result == null || result.isEmpty) return null;
  return result;
}

class _NewRootResult {
  const _NewRootResult({required this.label, required this.fields});
  final String label;
  final List<String> fields;
}

Future<_NewRootResult?> _promptNewRoot(
  BuildContext context,
  CategoryKind kind,
) async {
  final controller = TextEditingController();
  var templateId = clothingSizeTemplates.first.id;
  final showTemplate = kind == CategoryKind.clothing;
  final result = await showDialog<_NewRootResult>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return _AppDialog(
            title: '新增大分类',
            body: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DialogField(
                  controller: controller,
                  hint: '分类名称',
                  autofocus: true,
                ),
                if (showTemplate) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '测量模板',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: templateId,
                    style: const TextStyle(fontSize: 14, color: AppColors.text),
                    dropdownColor: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: [
                      for (final template in clothingSizeTemplates)
                        DropdownMenuItem(
                          value: template.id,
                          child: Text(
                            template.label,
                            style: const TextStyle(fontSize: 14, color: AppColors.text),
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => templateId = value);
                    },
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
              FilledButton(
                onPressed: () {
                  final label = controller.text.trim();
                  if (label.isEmpty) return;
                  final fields = showTemplate
                      ? clothingSizeTemplates
                          .firstWhere((t) => t.id == templateId)
                          .fields
                      : const <String>[];
                  Navigator.pop(context, _NewRootResult(label: label, fields: fields));
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    },
  );
  controller.dispose();
  return result;
}

class _AppDialog extends StatelessWidget {
  const _AppDialog({
    required this.title,
    required this.body,
    required this.actions,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 18),
              body,
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      style: const TextStyle(fontSize: 14, color: AppColors.text),
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
