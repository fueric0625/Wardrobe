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
import 'package:wardrobe/features/wardrobe/item_attribute_editor.dart';
import 'package:wardrobe/features/wardrobe/item_attributes.dart';
import 'package:wardrobe/features/wardrobe/photo_role.dart';
import 'package:wardrobe/core/catalog/category_item_dialogs.dart';
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
        final measures = decodeMeasurements(item.measurements);
        final sizeFields = category == null
            ? <String>[]
            : inheritedSizeFields(categories, category);
        final path = categoryPath(categories, item.categoryId);
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
                            children: [
                              ReadOnlyField(
                                label: '品名',
                                value: item.productName,
                              ),
                              ReadOnlyField(label: '分类', value: path),
                              _split(
                                ReadOnlyField(
                                  label: '尺码',
                                  value: item.sizeCode,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '款式',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SelectedLabels(
                                      labels: orderedStyle(
                                        decodeStyle(item.style),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ReadOnlyField(label: '颜色', value: item.color),
                              _split(
                                ReadOnlyField(label: '面料', value: item.fabric),
                                ReadOnlyField(
                                  label: '季节',
                                  value: _joinTokens(item.season),
                                ),
                              ),
                              ReadOnlyField(label: '品牌', value: item.brand),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '洗涤维护',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SelectedLabels(
                                    labels: [
                                      for (final group in careGroups)
                                        for (final option in group.options)
                                          if (decodeCare(item.careJson)
                                              .contains(option.id))
                                            option.label,
                                    ],
                                    icons: [
                                      for (final group in careGroups)
                                        for (final option in group.options)
                                          if (decodeCare(item.careJson)
                                              .contains(option.id))
                                            careGroupIcon(group.label),
                                    ],
                                  ),
                                ],
                              ),
                              _split(
                                ReadOnlyField(
                                  label: '价格',
                                  value: _priceText(item.price),
                                ),
                                ReadOnlyField(
                                  label: '购入时间',
                                  value: item.purchasedAt == null
                                      ? null
                                      : DateFormat('yyyy-MM-dd')
                                            .format(item.purchasedAt!),
                                ),
                              ),
                              if (sizeFields.isNotEmpty) ...[
                                const Text(
                                  '尺码测量',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                Wrap(
                                  spacing: 24,
                                  runSpacing: 12,
                                  children: [
                                    for (final field in sizeFields)
                                      SizedBox(
                                        width: 140,
                                        child: ReadOnlyField(
                                          label: field,
                                          value: measures[field],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                              ReadOnlyField(
                                label: '存放位置',
                                value: item.location,
                              ),
                              ReadOnlyField(label: '标签', value: item.tags),
                              ReadOnlyField(label: '备注', value: item.note),
                              if (tagOcr.isNotEmpty || tagPaths.isNotEmpty)
                                HangtagOcrBlock(
                                  text: tagOcr,
                                  imagePaths: tagPaths,
                                ),
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

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/wardrobe');
    }
  }

  static Widget _split(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
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
