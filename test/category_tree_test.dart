import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/core/catalog/catalogs.dart';
import 'package:wardrobe/core/catalog/category_tree.dart';
import 'package:wardrobe/core/database/app_database.dart';

Category cat({
  required String id,
  required String label,
  String? parentId,
  int sortOrder = 0,
  List<String> sizeFields = const [],
}) {
  return Category(
    id: id,
    kind: CategoryKind.clothing.name,
    parentId: parentId,
    label: label,
    sortOrder: sortOrder,
    sizeFields: encodeSizeFields(sizeFields),
    isSystem: id == 'uncategorized',
  );
}

void main() {
  final tops = cat(id: 'tops', label: '上装', sizeFields: ['衣长', '胸围']);
  final hoodie = cat(id: 'hoodie', label: '卫衣', parentId: 'tops', sortOrder: 0);
  final hooded = cat(
    id: 'hooded',
    label: '兜帽卫衣',
    parentId: 'hoodie',
    sortOrder: 0,
  );
  final shirt = cat(id: 'shirt', label: '衬衫', parentId: 'tops', sortOrder: 1);
  final all = [tops, hoodie, hooded, shirt];

  test('depth is 0/1/2 and third layer cannot add children', () {
    expect(categoryDepth(all, tops), 0);
    expect(categoryDepth(all, hoodie), 1);
    expect(categoryDepth(all, hooded), 2);
    expect(canAddChild(all, tops), isTrue);
    expect(canAddChild(all, hoodie), isTrue);
    expect(canAddChild(all, hooded), isFalse);
  });

  test('path and inherited size fields walk to the root', () {
    expect(categoryPath(all, 'hooded'), '上装 / 卫衣 / 兜帽卫衣');
    expect(inheritedSizeFields(all, hooded), ['衣长', '胸围']);
  });

  test('subtree includes descendants and children stay ordered', () {
    expect(subtreeIds(all, 'tops'), {'tops', 'hoodie', 'hooded', 'shirt'});
    expect(childrenOf(all, 'tops').map((c) => c.id).toList(), [
      'hoodie',
      'shirt',
    ]);
  });

  test('deleting a child category returns items to its parent', () {
    expect(itemsFallbackAfterDelete(all, hoodie), 'tops');
    expect(itemsFallbackAfterDelete(all, hooded), 'hoodie');
    expect(itemsFallbackAfterDelete(all, tops), uncategorizedClothingId);
  });

  test('an item can cover its own category and ancestors, not siblings', () {
    expect(coverCategoriesForItem(all, 'hooded').map((c) => c.id).toList(), [
      'tops',
      'hoodie',
      'hooded',
    ]);
    expect(coverCategoriesForItem(all, 'hoodie').map((c) => c.id).toList(), [
      'tops',
      'hoodie',
    ]);
    expect(coverCategoriesForItem(all, 'tops').map((c) => c.id).toList(), [
      'tops',
    ]);
    expect(subtreeIds(all, 'hoodie').contains('hooded'), isTrue);
    expect(subtreeIds(all, 'shirt').contains('hooded'), isFalse);
  });

  test('drag reorder stays inside the same parent', () {
    final bottoms = cat(id: 'bottoms', label: '下装', sortOrder: 1);
    final tree = [tops, bottoms, hoodie, shirt];
    expect(
      siblingIdsAfterDrop(
        tree,
        draggedId: 'hoodie',
        targetId: 'shirt',
        insertAfter: true,
      ),
      ['shirt', 'hoodie'],
    );
    expect(
      siblingIdsAfterDrop(
        tree,
        draggedId: 'tops',
        targetId: 'bottoms',
        insertAfter: true,
      ),
      ['bottoms', 'tops'],
    );
    expect(
      siblingIdsAfterDrop(
        tree,
        draggedId: 'hoodie',
        targetId: 'bottoms',
        insertAfter: false,
      ),
      isNull,
    );
    expect(
      siblingIdsAfterDrop(
        tree,
        draggedId: 'shirt',
        targetId: 'shirt',
        insertAfter: true,
      ),
      isNull,
    );
  });

  test('sibling labels must be unique, other branches may reuse', () {
    expect(siblingLabelTaken(all, parentId: null, label: '上装'), isTrue);
    expect(siblingLabelTaken(all, parentId: 'tops', label: '卫衣'), isTrue);
    expect(siblingLabelTaken(all, parentId: 'tops', label: '针织衫'), isFalse);
    expect(siblingLabelTaken(all, parentId: 'hoodie', label: '卫衣'), isFalse);
    expect(
      siblingLabelTaken(all, parentId: 'tops', label: '卫衣', exceptId: 'hoodie'),
      isFalse,
    );
  });

  test('subcategory filter keeps only that branch of clothes', () {
    final now = DateTime.utc(2026, 1, 1);
    ClothingItem piece(String id, String categoryId) {
      return ClothingItem(
        id: id,
        categoryId: categoryId,
        type: '',
        productName: '',
        sizeCode: '',
        style: '',
        careJson: '',
        color: '',
        season: '',
        fabric: '',
        brand: '',
        measurements: '{}',
        purchaseInfo: '',
        location: '',
        tags: '',
        note: '',
        createdAt: now,
        updatedAt: now,
      );
    }

    final items = [
      piece('hoodie-item', 'hoodie'),
      piece('hooded-item', 'hooded'),
      piece('shirt-item', 'shirt'),
    ];
    expect(itemsInSubtree(items, all, 'tops').map((item) => item.id).toSet(), {
      'hoodie-item',
      'hooded-item',
      'shirt-item',
    });
    expect(
      itemsInSubtree(items, all, 'hoodie').map((item) => item.id).toList(),
      ['hoodie-item', 'hooded-item'],
    );
    expect(
      itemsInSubtree(items, all, 'shirt').map((item) => item.id).toList(),
      ['shirt-item'],
    );
  });
}
