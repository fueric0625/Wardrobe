import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/design_system/theme.dart';
import 'package:wardrobe/features/wardrobe/detail_layout.dart';
import 'package:wardrobe/features/wardrobe/detail_layout_store.dart';
import 'package:wardrobe/features/wardrobe/item_photos.dart';
import 'package:wardrobe/features/wardrobe/providers.dart';

class DetailLayoutPage extends ConsumerWidget {
  const DetailLayoutPage({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(detailLayoutProvider);
    final items = ref
        .watch(clothingItemsProvider)
        .maybeWhen(data: (rows) => rows, orElse: () => const []);
    final item = items.where((row) => row.id == itemId).firstOrNull;
    final images = ref
        .watch(itemImagesProvider(itemId))
        .maybeWhen(
          data: (rows) => rows,
          orElse: () => const <ClothingItemImage>[],
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 28, 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/wardrobe/item/$itemId');
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                  label: const Text('返回'),
                ),
                const Expanded(
                  child: Text(
                    '详情布局',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                const Text(
                  '全衣橱共用',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(32, 0, 32, 12),
            child: Text(
              '拖动排序，开关控制是否出现在详情和编辑里。关掉后已填内容仍保留。照片、返回、移动、修改不参与排序。尺码测量和吊牌原文各占一行。',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 320,
                    child: ItemPhotoViewer(
                      images: images,
                      fallbackPath: item?.imagePath,
                    ),
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            padding: const EdgeInsets.only(bottom: 12),
                            itemCount: layout.slots.length,
                            onReorderItem: (oldIndex, newIndex) {
                              ref
                                  .read(detailLayoutProvider.notifier)
                                  .move(oldIndex, newIndex);
                            },
                            itemBuilder: (context, index) {
                              final slot = layout.slots[index];
                              final custom =
                                  slot.kind != DetailSlotKind.builtin;
                              return Padding(
                                key: ValueKey(slot.id),
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      8,
                                      4,
                                      8,
                                      4,
                                    ),
                                    child: Row(
                                      children: [
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(
                                              Icons.drag_indicator,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            slot.displayLabel,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: slot.visible
                                                  ? AppColors.text
                                                  : AppColors.textMuted,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: custom
                                                ? AppPalette.of(context)
                                                      .primarySoft
                                                : const Color(0xFFF0F1F5),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            slot.typeLabel,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: custom
                                                  ? AppPalette.of(context)
                                                        .primary
                                                  : AppColors.textMuted,
                                            ),
                                          ),
                                        ),
                                        Switch(
                                          value: slot.visible,
                                          onChanged: (value) {
                                            ref
                                                .read(
                                                  detailLayoutProvider.notifier,
                                                )
                                                .setVisible(slot.id, value);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _addField(context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text('添加字段'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addField(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_NewFieldInput>(
      context: context,
      builder: (context) => const _NewFieldDialog(),
    );
    if (result == null) return;
    final added = await ref
        .read(detailLayoutProvider.notifier)
        .addCustom(
          label: result.label,
          kind: result.kind,
          options: result.options,
        );
    if (!context.mounted || added) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('请填写名称。单选和多选至少要有一个选项。')));
  }
}

class _NewFieldInput {
  const _NewFieldInput({
    required this.label,
    required this.kind,
    required this.options,
  });

  final String label;
  final DetailSlotKind kind;
  final List<String> options;
}

class _NewFieldDialog extends StatefulWidget {
  const _NewFieldDialog();

  @override
  State<_NewFieldDialog> createState() => _NewFieldDialogState();
}

class _NewFieldDialogState extends State<_NewFieldDialog> {
  final _name = TextEditingController();
  final _options = <TextEditingController>[TextEditingController()];
  var _kind = DetailSlotKind.multi;

  @override
  void dispose() {
    _name.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  bool get _valid {
    if (_name.text.trim().isEmpty) return false;
    if (_kind == DetailSlotKind.text) return true;
    return _options.any((option) => option.text.trim().isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建字段'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '名称',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(hintText: '例如 场合'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              const Text(
                '类型',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final kind in const [
                    DetailSlotKind.text,
                    DetailSlotKind.single,
                    DetailSlotKind.multi,
                  ])
                    ChoiceChip(
                      label: Text(switch (kind) {
                        DetailSlotKind.text => '一行文字',
                        DetailSlotKind.single => '单选',
                        DetailSlotKind.multi => '多选',
                        DetailSlotKind.builtin => '',
                      }),
                      selected: _kind == kind,
                      showCheckmark: false,
                      selectedColor: AppPalette.of(context).primarySoft,
                      side: _kind == kind
                          ? BorderSide.none
                          : const BorderSide(color: AppColors.border),
                      onSelected: (_) => setState(() => _kind = kind),
                    ),
                ],
              ),
              if (_kind != DetailSlotKind.text) ...[
                const SizedBox(height: 16),
                const Text(
                  '选项',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _options.length; i++) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _options[i],
                          decoration: const InputDecoration(hintText: '选项'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      IconButton(
                        onPressed: _options.length == 1
                            ? null
                            : () {
                                final removed = _options.removeAt(i);
                                setState(() {});
                                WidgetsBinding.instance.addPostFrameCallback(
                                  (_) => removed.dispose(),
                                );
                              },
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                TextButton.icon(
                  onPressed: () {
                    setState(() => _options.add(TextEditingController()));
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('添加选项'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: !_valid
              ? null
              : () {
                  Navigator.pop(
                    context,
                    _NewFieldInput(
                      label: _name.text,
                      kind: _kind,
                      options: [for (final option in _options) option.text],
                    ),
                  );
                },
          child: const Text('添加'),
        ),
      ],
    );
  }
}
