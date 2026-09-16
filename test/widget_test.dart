import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/core/catalogs.dart';

void main() {
  test('preset clothing category seeds match the v1 labels and size fields', () {
    expect(clothingCategorySeeds.map((c) => c.label).toList(), [
      '无分类',
      '内衣',
      '上装',
      '下装',
      '鞋子',
      '包包',
      '配饰',
    ]);
    expect(
      clothingCategorySeeds.firstWhere((c) => c.id == 'tops').sizeFields,
      ['衣长', '胸围', '肩宽', '下摆围'],
    );
    expect(
      clothingCategorySeeds.firstWhere((c) => c.id == 'bottoms').sizeFields,
      ['裤长', '腰围', '臀围', '大腿围', '裤脚围'],
    );
  });

  test('preset outfit categories match the v1 plan', () {
    expect(outfitCategories.map((c) => c.label).toList(), [
      '无分类',
      '工作',
      '休闲',
      '派对',
      '运动',
      '度假',
    ]);
  });
}
