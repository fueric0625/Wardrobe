import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wardrobe/core/catalog/providers.dart';
import 'package:wardrobe/features/wardrobe/providers.dart';
import 'package:wardrobe/core/catalog/catalogs.dart';
import 'package:wardrobe/core/catalog/category_tree.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/design_system/theme.dart';
import 'package:wardrobe/core/vision/ocr/tag_ocr.dart';
import 'package:wardrobe/core/serialization/custom_field_codec.dart';
import 'package:wardrobe/features/wardrobe/detail_layout.dart';
import 'package:wardrobe/features/wardrobe/detail_layout_store.dart';
import 'package:wardrobe/features/wardrobe/item_attribute_editor.dart';
import 'package:wardrobe/features/wardrobe/item_attributes.dart';
import 'package:wardrobe/features/wardrobe/photo_role.dart';
import 'package:wardrobe/core/catalog/category_item_dialogs.dart';
import 'package:wardrobe/features/wardrobe/item_delete_dialog.dart';
import 'package:wardrobe/features/wardrobe/item_photos.dart';
import 'package:wardrobe/widgets/common.dart';

class ItemDetailPage extends ConsumerWidget {
  const ItemDetailPage({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(clothingItemsProvider);
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
        final item = items.where((i) => i.id == itemId).firstOrNull;
        if (item == null) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '找不到这件衣物',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
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

        final categories = ref.watch(clothingCategoryRowsProvider);
        final category = categoryById(categories, item.categoryId);
        final title = item.productName.trim().isEmpty
            ? '单品详情'
            : item.productName.trim();
        final path = categoryPath(categories, item.categoryId);
        final sizeFields = category == null
            ? <String>[]
            : inheritedSizeFields(categories, category);
        final coverTargets = coverCategoriesForItem(
          categories,
          item.categoryId,
        );
        final images = ref
            .watch(itemImagesProvider(item.id))
            .maybeWhen(
              data: (rows) => rows,
              orElse: () => const <ClothingItemImage>[],
            );
        final tagOcr = _tagOcrText(images);
        final tagPaths = _tagImagePaths(images);
        final layout = ref.watch(detailLayoutProvider);
        final measures = decodeMeasurements(item.measurements);

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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    CategoryCoverActions(
                      itemId: item.id,
                      kind: CategoryKind.clothing,
                      covers: covers,
                      targets: coverTargets,
                    ),
                    TextButton(
                      onPressed: () =>
                          context.push('/wardrobe/item/${item.id}/layout'),
                      child: const Text('布局'),
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
                    TextButton(
                      onPressed: () => _delete(context, ref, item.id),
                      child: const Text(
                        '删除',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () =>
                          context.push('/wardrobe/item/${item.id}/edit'),
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
                          child: ItemPhotoViewer(
                            images: images,
                            fallbackPath: item.imagePath,
                          ),
                        ),
                        const SizedBox(width: 28),
                        Expanded(
                          child: DetailFormCard(
                            children: _detailFields(
                              layout: layout,
                              item: item,
                              path: path,
                              sizeFields: sizeFields,
                              measures: measures,
                              tagOcr: tagOcr,
                              tagPaths: tagPaths,
                            ),
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
    required ClothingItem item,
    required List<Category> categories,
  }) async {
    final dest = await promptMoveToCategory(
      context,
      categories: categories,
      currentId: item.categoryId,
    );
    if (dest == null || !context.mounted) return;
    await ref.read(itemRepositoryProvider).moveToCategory([item.id], dest.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已移动到「${categoryPath(categories, dest.id)}」')),
    );
  }

  static Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String itemId,
  ) async {
    final ok = await confirmDeleteClothingItem(context);
    if (!ok || !context.mounted) return;
    try {
      await ref.read(itemRepositoryProvider).delete(itemId);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('删除失败')));
      return;
    }
    if (!context.mounted) return;
    _back(context);
  }

  static void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/wardrobe');
    }
  }
}

List<Widget> _detailFields({
  required DetailLayout layout,
  required ClothingItem item,
  required String path,
  required List<String> sizeFields,
  required Map<String, String> measures,
  required String tagOcr,
  required List<String> tagPaths,
}) {
  final custom = decodeCustomFieldValues(item.customJson);
  final widgets = <Widget>[];
  for (final row in visibleDetailRows(layout)) {
    if (row.right == null) {
      final child = _detailSlot(
        row.left,
        item: item,
        path: path,
        sizeFields: sizeFields,
        measures: measures,
        tagOcr: tagOcr,
        tagPaths: tagPaths,
        custom: custom,
      );
      if (child != null) widgets.add(child);
    } else {
      widgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _detailSlot(
                row.left,
                item: item,
                path: path,
                sizeFields: sizeFields,
                measures: measures,
                tagOcr: tagOcr,
                tagPaths: tagPaths,
                custom: custom,
              )!,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _detailSlot(
                row.right!,
                item: item,
                path: path,
                sizeFields: sizeFields,
                measures: measures,
                tagOcr: tagOcr,
                tagPaths: tagPaths,
                custom: custom,
              )!,
            ),
          ],
        ),
      );
    }
  }
  return widgets;
}

Widget? _detailSlot(
  DetailSlot slot, {
  required ClothingItem item,
  required String path,
  required List<String> sizeFields,
  required Map<String, String> measures,
  required String tagOcr,
  required List<String> tagPaths,
  required CustomFieldValues custom,
}) {
  if (slot.kind != DetailSlotKind.builtin) {
    if (slot.kind == DetailSlotKind.multi) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slot.displayLabel,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 4),
          SelectedLabels(
            labels: orderedChoices(slot.options, {
              ...custom.choices[slot.id] ?? const <String>[],
            }),
          ),
        ],
      );
    }
    return ReadOnlyField(label: slot.displayLabel, value: custom.text[slot.id]);
  }

  switch (slot.id) {
    case BuiltinDetailField.productName:
      return ReadOnlyField(label: '品名', value: item.productName);
    case BuiltinDetailField.category:
      return ReadOnlyField(label: '分类', value: path);
    case BuiltinDetailField.sizeCode:
      return ReadOnlyField(label: '尺码', value: item.sizeCode);
    case BuiltinDetailField.style:
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '款式',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 4),
          SelectedLabels(labels: orderedStyle(decodeStyle(item.style))),
        ],
      );
    case BuiltinDetailField.color:
      return ReadOnlyField(label: '颜色', value: item.color);
    case BuiltinDetailField.fabric:
      return ReadOnlyField(label: '面料', value: item.fabric);
    case BuiltinDetailField.season:
      return ReadOnlyField(label: '季节', value: _joinTokens(item.season));
    case BuiltinDetailField.brand:
      return ReadOnlyField(label: '品牌', value: item.brand);
    case BuiltinDetailField.care:
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '洗涤维护',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 4),
          SelectedLabels(
            labels: [
              for (final group in careGroups)
                for (final option in group.options)
                  if (decodeCare(item.careJson).contains(option.id))
                    option.label,
            ],
            icons: [
              for (final group in careGroups)
                for (final option in group.options)
                  if (decodeCare(item.careJson).contains(option.id))
                    careGroupIcon(group.label),
            ],
          ),
        ],
      );
    case BuiltinDetailField.price:
      return ReadOnlyField(label: '价格', value: _priceText(item.price));
    case BuiltinDetailField.purchasedAt:
      return ReadOnlyField(
        label: '购入时间',
        value: item.purchasedAt == null
            ? null
            : DateFormat('yyyy-MM-dd').format(item.purchasedAt!),
      );
    case BuiltinDetailField.measurements:
      if (sizeFields.isEmpty) return null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('尺码测量', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              for (final field in sizeFields)
                SizedBox(
                  width: 140,
                  child: ReadOnlyField(label: field, value: measures[field]),
                ),
            ],
          ),
        ],
      );
    case BuiltinDetailField.location:
      return ReadOnlyField(label: '存放位置', value: item.location);
    case BuiltinDetailField.tags:
      return ReadOnlyField(label: '标签', value: item.tags);
    case BuiltinDetailField.note:
      return ReadOnlyField(label: '备注', value: item.note);
    case BuiltinDetailField.hangtag:
      if (tagOcr.isEmpty && tagPaths.isEmpty) return null;
      return HangtagOcrBlock(text: tagOcr, imagePaths: tagPaths);
    default:
      return null;
  }
}

String? _priceText(double? price) {
  if (price == null) return null;
  final text = price == price.roundToDouble()
      ? price.toInt().toString()
      : price.toString();
  return '$text 元';
}

String? _joinTokens(String raw) {
  final parts = raw.split(RegExp(r'[,，\s]+')).where((s) => s.isNotEmpty);
  if (parts.isEmpty) return null;
  return parts.join('、');
}

String _tagOcrText(List<ClothingItemImage> images) {
  final parts = <String>[];
  for (final image in images) {
    if (ItemPhotoRole.parse(image.role) != ItemPhotoRole.tag) continue;
    final text = TagOcrResult.decode(image.ocrJson).text;
    if (text.isNotEmpty) parts.add(text);
  }
  return parts.join('\n\n');
}

List<String> _tagImagePaths(List<ClothingItemImage> images) {
  return [
    for (final image in images)
      if (ItemPhotoRole.parse(image.role) == ItemPhotoRole.tag)
        itemImagePreviewPath(image),
  ];
}
