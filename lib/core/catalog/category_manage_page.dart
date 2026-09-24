import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wardrobe/core/catalog/providers.dart';
import 'package:wardrobe/core/catalog/catalogs.dart';
import 'package:wardrobe/core/catalog/category_tree.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/design_system/theme.dart';

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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
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
                child: _CategoryList(
                  categories: categories,
                  onReorder: (parentId, orderedIds) {
                    return ref
                        .read(categoryRepositoryProvider)
                        .reorderSiblings(kind, parentId, orderedIds);
                  },
                  onRename: (category) => _rename(context, ref, kind, category),
                  onAddChild: (category) =>
                      _addChild(context, ref, kind, category),
                  onDelete: (category) =>
                      _delete(context, ref, kind, categories, category),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryList extends StatefulWidget {
  const _CategoryList({
    required this.categories,
    required this.onReorder,
    required this.onRename,
    required this.onAddChild,
    required this.onDelete,
  });

  final List<Category> categories;
  final Future<void> Function(String? parentId, List<String> orderedIds)
  onReorder;
  final ValueChanged<Category> onRename;
  final ValueChanged<Category> onAddChild;
  final ValueChanged<Category> onDelete;

  @override
  State<_CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<_CategoryList> {
  String? _draggingId;
  String? _hoverId;
  bool _insertAfter = false;

  bool _inDraggedSubtree(Category category) {
    final draggingId = _draggingId;
    if (draggingId == null) return false;
    var current = category;
    final seen = <String>{};
    while (seen.add(current.id)) {
      if (current.id == draggingId) return true;
      final parentId = current.parentId;
      if (parentId == null) return false;
      final parent = categoryById(widget.categories, parentId);
      if (parent == null) return false;
      current = parent;
    }
    return false;
  }

  Future<void> _drop(String draggedId, String targetId) async {
    final ordered = siblingIdsAfterDrop(
      widget.categories,
      draggedId: draggedId,
      targetId: targetId,
      insertAfter: _insertAfter,
    );
    final dragged = categoryById(widget.categories, draggedId);
    if (ordered == null || dragged == null) return;
    await widget.onReorder(dragged.parentId, ordered);
  }

  @override
  Widget build(BuildContext context) {
    final rows = flattenPreorder(widget.categories);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final category = rows[index];
        return _CategoryRow(
          categories: widget.categories,
          category: category,
          depth: categoryDepth(widget.categories, category),
          canAddChild: canAddChild(widget.categories, category),
          dimmed: _inDraggedSubtree(category),
          showBefore: _hoverId == category.id && !_insertAfter,
          showAfter: _hoverId == category.id && _insertAfter,
          onRename: () => widget.onRename(category),
          onAddChild: () => widget.onAddChild(category),
          onDelete: () => widget.onDelete(category),
          onDragStarted: () => setState(() => _draggingId = category.id),
          onDragEnd: () => setState(() {
            _draggingId = null;
            _hoverId = null;
          }),
          onHover: (insertAfter) => setState(() {
            _hoverId = category.id;
            _insertAfter = insertAfter;
          }),
          onLeave: () {
            if (_hoverId == category.id) {
              setState(() => _hoverId = null);
            }
          },
          onDrop: (draggedId) => _drop(draggedId, category.id),
        );
      },
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categories,
    required this.category,
    required this.depth,
    required this.canAddChild,
    required this.dimmed,
    required this.showBefore,
    required this.showAfter,
    required this.onRename,
    required this.onAddChild,
    required this.onDelete,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.onHover,
    required this.onLeave,
    required this.onDrop,
  });

  final List<Category> categories;
  final Category category;
  final int depth;
  final bool canAddChild;
  final bool dimmed;
  final bool showBefore;
  final bool showAfter;
  final VoidCallback onRename;
  final VoidCallback onAddChild;
  final VoidCallback onDelete;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;
  final ValueChanged<bool> onHover;
  final VoidCallback onLeave;
  final ValueChanged<String> onDrop;

  @override
  Widget build(BuildContext context) {
    final accent = AppPalette.of(context).primary;
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        final dragged = categoryById(categories, details.data);
        if (dragged == null || dragged.id == category.id) return false;
        return dragged.parentId == category.parentId;
      },
      onMove: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        final local = box.globalToLocal(details.offset);
        onHover(local.dy > box.size.height / 2);
      },
      onLeave: (_) => onLeave(),
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidate, _) {
        final active = candidate.isNotEmpty && (showBefore || showAfter);
        return Opacity(
          opacity: dimmed ? 0.35 : 1,
          child: Container(
            padding: EdgeInsets.fromLTRB(8.0 + depth * 24, 6, 12, 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active ? accent : AppColors.border,
                width: active ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Draggable<String>(
                  data: category.id,
                  dragAnchorStrategy: pointerDragAnchorStrategy,
                  onDragStarted: onDragStarted,
                  onDragEnd: (_) => onDragEnd(),
                  feedback: Material(
                    color: AppColors.surface,
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        category.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  childWhenDragging: const Icon(
                    Icons.drag_indicator,
                    color: AppColors.textMuted,
                  ),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Tooltip(
                      message: '拖动排序',
                      child: Semantics(
                        container: true,
                        child: const Icon(
                          Icons.drag_indicator,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  depth == 0
                      ? Icons.folder_outlined
                      : Icons.subdirectory_arrow_right,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.label,
                    style: TextStyle(
                      fontWeight: depth == 0
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(onPressed: onRename, child: const Text('改名')),
                if (canAddChild)
                  TextButton(onPressed: onAddChild, child: const Text('添加子分类')),
                if (!category.isSystem)
                  TextButton(
                    onPressed: onDelete,
                    child: const Text(
                      '删除',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
    return ref
        .read(categoryRepositoryProvider)
        .add(kind: kind, label: result.label, sizeFields: result.fields);
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
    return ref
        .read(categoryRepositoryProvider)
        .add(kind: kind, parentId: parent.id, label: label);
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
    return ref
        .read(categoryRepositoryProvider)
        .rename(kind, category.id, label);
  });
}

Future<void> _run(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(_errorText(e))));
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
  final fallbackLabel = categoryById(categories, fallbackId)?.label ?? '无分类';
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => _AppDialog(
      title: '删除「${category.label}」？',
      body: Text(
        '子分类会一起删除，里面的${_itemNoun(kind)}会回到「$fallbackLabel」。',
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: AppColors.text,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('删除'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await ref.read(categoryRepositoryProvider).deleteSubtree(kind, category.id);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(_errorText(e))));
  }
}

Future<String?> _promptName(
  BuildContext context, {
  required String title,
  String? initial,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _NamePromptDialog(title: title, initial: initial),
  );
}

class _NamePromptDialog extends StatefulWidget {
  const _NamePromptDialog({required this.title, this.initial});

  final String title;
  final String? initial;

  @override
  State<_NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends State<_NamePromptDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _controller.text.trim();
    if (label.isEmpty) return;
    Navigator.pop(context, label);
  }

  @override
  Widget build(BuildContext context) {
    return _AppDialog(
      title: widget.title,
      body: _DialogField(
        controller: _controller,
        hint: '分类名称',
        autofocus: true,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('确定')),
      ],
    );
  }
}

class _NewRootResult {
  const _NewRootResult({required this.label, required this.fields});
  final String label;
  final List<String> fields;
}

Future<_NewRootResult?> _promptNewRoot(
  BuildContext context,
  CategoryKind kind,
) {
  return showDialog<_NewRootResult>(
    context: context,
    builder: (context) => _NewRootDialog(kind: kind),
  );
}

class _NewRootDialog extends StatefulWidget {
  const _NewRootDialog({required this.kind});

  final CategoryKind kind;

  @override
  State<_NewRootDialog> createState() => _NewRootDialogState();
}

class _NewRootDialogState extends State<_NewRootDialog> {
  final TextEditingController _controller = TextEditingController();
  var _templateId = clothingSizeTemplates.first.id;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _controller.text.trim();
    if (label.isEmpty) return;
    final fields = widget.kind == CategoryKind.clothing
        ? clothingSizeTemplates.firstWhere((t) => t.id == _templateId).fields
        : const <String>[];
    Navigator.pop(context, _NewRootResult(label: label, fields: fields));
  }

  @override
  Widget build(BuildContext context) {
    final showTemplate = widget.kind == CategoryKind.clothing;
    return _AppDialog(
      title: '新增大分类',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DialogField(controller: _controller, hint: '分类名称', autofocus: true),
          if (showTemplate) ...[
            const SizedBox(height: 16),
            const Text(
              '测量模板',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _templateId,
              style: const TextStyle(fontSize: 14, color: AppColors.text),
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              items: [
                for (final template in clothingSizeTemplates)
                  DropdownMenuItem(
                    value: template.id,
                    child: Text(
                      template.label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _templateId = value);
              },
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('确定')),
      ],
    );
  }
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
              Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}
