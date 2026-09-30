import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/core/catalog/catalogs.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/serialization/custom_field_codec.dart';
import 'package:wardrobe/features/wardrobe/detail_layout.dart';
import 'package:wardrobe/features/wardrobe/item_search.dart';

void main() {
  final now = DateTime.utc(2026, 9, 30);
  final categories = [
    Category(
      id: 'tops',
      kind: CategoryKind.clothing.name,
      label: '上装',
      sortOrder: 0,
      sizeFields: '',
      isSystem: true,
    ),
    Category(
      id: 'shirt',
      kind: CategoryKind.clothing.name,
      parentId: 'tops',
      label: '衬衫',
      sortOrder: 0,
      sizeFields: '',
      isSystem: false,
    ),
  ];

  ClothingItem piece({
    String type = '旧T恤',
    String productName = '牛津衬衫',
    String brand = '优衣库',
    String careJson = 'wash-hand',
    String note = '只在备注里',
    String tags = '通勤',
    String customJson = '',
    double? price = 199,
    String measurements = '{"衣长":"吊牌密文"}',
  }) {
    return ClothingItem(
      id: 'item',
      categoryId: 'shirt',
      type: type,
      productName: productName,
      sizeCode: '175/92A',
      style: '直身',
      careJson: careJson,
      color: '白色',
      season: '春',
      fabric: '棉',
      brand: brand,
      price: price,
      measurements: measurements,
      purchasedAt: DateTime.utc(2020, 3, 1),
      purchaseInfo: '',
      location: '衣柜',
      tags: tags,
      note: note,
      customJson: customJson,
      createdAt: now,
      updatedAt: now,
    );
  }

  bool matches(ClothingItem item, DetailLayout layout, String query) {
    return clothingItemMatches(
      item: item,
      layout: layout,
      categories: categories,
      query: query,
    );
  }

  test('hidden fields are not searched', () {
    final layout = setDetailSlotVisible(
      DetailLayout.standard,
      BuiltinDetailField.brand,
      false,
    );
    final item = piece();
    expect(matches(item, layout, '优衣库'), isFalse);
    expect(matches(item, DetailLayout.standard, '优衣库'), isTrue);
    expect(matches(item, layout, '牛津'), isTrue);
  });

  test('care matches the Chinese label, not the option id', () {
    final item = piece();
    expect(matches(item, DetailLayout.standard, '手洗'), isTrue);
    expect(matches(item, DetailLayout.standard, 'wash-hand'), isFalse);
    final hidden = setDetailSlotVisible(
      DetailLayout.standard,
      BuiltinDetailField.care,
      false,
    );
    expect(matches(item, hidden, '手洗'), isFalse);
  });

  test('custom option text is searched only while that field is visible', () {
    final slot = customDetailSlot(
      id: 'c_place',
      label: '场合',
      kind: DetailSlotKind.multi,
      options: ['通勤', '运动', '居家'],
    )!;
    final shown = appendCustomSlot(DetailLayout.standard, slot);
    final hidden = setDetailSlotVisible(shown, slot.id, false);
    final item = piece(
      tags: '',
      customJson: encodeCustomFieldValues(
        const CustomFieldValues(
          text: {'c_shop': '国贸店'},
          choices: {
            'c_place': ['运动'],
          },
        ),
      ),
    );
    final withShop = appendCustomSlot(
      shown,
      customDetailSlot(
        id: 'c_shop',
        label: '购入店铺',
        kind: DetailSlotKind.text,
        options: const [],
      )!,
    );
    expect(matches(item, shown, '运动'), isTrue);
    expect(matches(item, hidden, '运动'), isFalse);
    expect(matches(item, withShop, '国贸店'), isTrue);
  });

  test('legacy type always matches', () {
    final layout = setDetailSlotVisible(
      setDetailSlotVisible(
        DetailLayout.standard,
        BuiltinDetailField.productName,
        false,
      ),
      BuiltinDetailField.category,
      false,
    );
    expect(matches(piece(productName: ''), layout, '旧t恤'), isTrue);
    expect(matches(piece(productName: ''), layout, '衬衫'), isFalse);
  });

  test('price, purchase date, measurements, and hangtag text are skipped', () {
    final item = piece();
    expect(matches(item, DetailLayout.standard, '199'), isFalse);
    expect(matches(item, DetailLayout.standard, '2020'), isFalse);
    expect(matches(item, DetailLayout.standard, '吊牌密文'), isFalse);
    expect(matches(item, DetailLayout.standard, '白色'), isTrue);
  });
}
