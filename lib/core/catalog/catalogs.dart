import 'dart:convert';

enum CategoryKind { clothing, outfit }

class SizeTemplate {
  const SizeTemplate({
    required this.id,
    required this.label,
    required this.fields,
  });

  final String id;
  final String label;
  final List<String> fields;
}

class ClothingCategorySeed {
  const ClothingCategorySeed({
    required this.id,
    required this.label,
    required this.sortOrder,
    this.sizeFields = const [],
    this.isSystem = false,
  });

  final String id;
  final String label;
  final int sortOrder;
  final List<String> sizeFields;
  final bool isSystem;
}

const uncategorizedClothingId = 'uncategorized';

/// Max small-category layers under a top-level category (上装 / 卫衣 / 兜帽卫衣).
const maxCategoryDepth = 2;

const clothingSizeTemplates = <SizeTemplate>[
  SizeTemplate(id: 'none', label: '无尺码', fields: []),
  SizeTemplate(
    id: 'tops',
    label: '上装 / 内衣',
    fields: ['衣长', '胸围', '肩宽', '下摆围'],
  ),
  SizeTemplate(
    id: 'bottoms',
    label: '下装',
    fields: ['裤长', '腰围', '臀围', '大腿围', '裤脚围'],
  ),
  SizeTemplate(id: 'shoes', label: '鞋子', fields: ['鞋码']),
  SizeTemplate(id: 'object', label: '物件', fields: ['尺寸']),
];

const outfitCategorySeeds = <ClothingCategorySeed>[
  ClothingCategorySeed(
    id: uncategorizedClothingId,
    label: '无分类',
    sortOrder: 0,
    isSystem: true,
  ),
  ClothingCategorySeed(id: 'work', label: '工作', sortOrder: 1),
  ClothingCategorySeed(id: 'casual', label: '休闲', sortOrder: 2),
  ClothingCategorySeed(id: 'party', label: '派对', sortOrder: 3),
  ClothingCategorySeed(id: 'sport', label: '运动', sortOrder: 4),
  ClothingCategorySeed(id: 'vacation', label: '度假', sortOrder: 5),
];

const clothingCategorySeeds = <ClothingCategorySeed>[
  ClothingCategorySeed(
    id: uncategorizedClothingId,
    label: '无分类',
    sortOrder: 0,
    isSystem: true,
  ),
  ClothingCategorySeed(
    id: 'underwear',
    label: '内衣',
    sortOrder: 1,
    sizeFields: ['衣长', '胸围', '肩宽', '下摆围'],
  ),
  ClothingCategorySeed(
    id: 'tops',
    label: '上装',
    sortOrder: 2,
    sizeFields: ['衣长', '胸围', '肩宽', '下摆围'],
  ),
  ClothingCategorySeed(
    id: 'bottoms',
    label: '下装',
    sortOrder: 3,
    sizeFields: ['裤长', '腰围', '臀围', '大腿围', '裤脚围'],
  ),
  ClothingCategorySeed(
    id: 'shoes',
    label: '鞋子',
    sortOrder: 4,
    sizeFields: ['鞋码'],
  ),
  ClothingCategorySeed(
    id: 'bags',
    label: '包包',
    sortOrder: 5,
    sizeFields: ['尺寸'],
  ),
  ClothingCategorySeed(
    id: 'accessories',
    label: '配饰',
    sortOrder: 6,
    sizeFields: ['尺寸'],
  ),
];

const seasons = ['春', '夏', '秋', '冬'];

String encodeSizeFields(List<String> fields) => jsonEncode(fields);

List<String> decodeSizeFields(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .map((e) => _normalizeSizeFieldName('$e'))
          .where((s) => s.isNotEmpty)
          .toList();
    }
  } catch (_) {}
  return [];
}

List<String> allSizeFieldNames() {
  final names = <String>{};
  for (final template in clothingSizeTemplates) {
    names.addAll(template.fields);
  }
  for (final seed in clothingCategorySeeds) {
    names.addAll(seed.sizeFields);
  }
  return names.toList();
}

String _normalizeSizeFieldName(String name) {
  return name == '物件' ? '尺寸' : name;
}

Map<String, String> decodeMeasurements(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return decoded.map(
        (k, v) => MapEntry(_normalizeSizeFieldName('$k'), '$v'),
      );
    }
  } catch (_) {}
  return {};
}
