import 'dart:convert';

/// Built-in detail fields. Photos and the top bar are not in this list.
abstract final class BuiltinDetailField {
  static const productName = 'productName';
  static const category = 'category';
  static const sizeCode = 'sizeCode';
  static const style = 'style';
  static const color = 'color';
  static const fabric = 'fabric';
  static const season = 'season';
  static const brand = 'brand';
  static const care = 'care';
  static const price = 'price';
  static const purchasedAt = 'purchasedAt';
  static const measurements = 'measurements';
  static const location = 'location';
  static const tags = 'tags';
  static const note = 'note';
  static const hangtag = 'hangtag';
}

const builtinDetailOrder = <String>[
  BuiltinDetailField.productName,
  BuiltinDetailField.category,
  BuiltinDetailField.sizeCode,
  BuiltinDetailField.style,
  BuiltinDetailField.color,
  BuiltinDetailField.fabric,
  BuiltinDetailField.season,
  BuiltinDetailField.brand,
  BuiltinDetailField.care,
  BuiltinDetailField.price,
  BuiltinDetailField.purchasedAt,
  BuiltinDetailField.measurements,
  BuiltinDetailField.location,
  BuiltinDetailField.tags,
  BuiltinDetailField.note,
  BuiltinDetailField.hangtag,
];

const builtinDetailLabels = <String, String>{
  BuiltinDetailField.productName: '品名',
  BuiltinDetailField.category: '分类',
  BuiltinDetailField.sizeCode: '尺码',
  BuiltinDetailField.style: '款式',
  BuiltinDetailField.color: '颜色',
  BuiltinDetailField.fabric: '面料',
  BuiltinDetailField.season: '季节',
  BuiltinDetailField.brand: '品牌',
  BuiltinDetailField.care: '洗涤维护',
  BuiltinDetailField.price: '价格',
  BuiltinDetailField.purchasedAt: '购入时间',
  BuiltinDetailField.measurements: '尺码测量',
  BuiltinDetailField.location: '存放位置',
  BuiltinDetailField.tags: '标签',
  BuiltinDetailField.note: '备注',
  BuiltinDetailField.hangtag: '吊牌原文',
};

const _orderedPairs = <(String, String)>[
  (BuiltinDetailField.sizeCode, BuiltinDetailField.style),
  (BuiltinDetailField.fabric, BuiltinDetailField.season),
  (BuiltinDetailField.price, BuiltinDetailField.purchasedAt),
];

enum DetailSlotKind { builtin, text, single, multi }

class DetailSlot {
  const DetailSlot({
    required this.id,
    required this.kind,
    required this.visible,
    this.label = '',
    this.options = const [],
  });

  final String id;
  final DetailSlotKind kind;
  final bool visible;
  final String label;
  final List<String> options;

  String get displayLabel =>
      kind == DetailSlotKind.builtin ? (builtinDetailLabels[id] ?? id) : label;

  String get typeLabel => switch (kind) {
    DetailSlotKind.builtin => '自带',
    DetailSlotKind.text => '文字',
    DetailSlotKind.single => '单选',
    DetailSlotKind.multi => '多选',
  };

  DetailSlot copyWith({bool? visible}) {
    return DetailSlot(
      id: id,
      kind: kind,
      visible: visible ?? this.visible,
      label: label,
      options: options,
    );
  }
}

class DetailLayout {
  const DetailLayout(this.slots);

  final List<DetailSlot> slots;

  static final standard = DetailLayout([
    for (final id in builtinDetailOrder)
      DetailSlot(id: id, kind: DetailSlotKind.builtin, visible: true),
  ]);
}

class DetailRow {
  const DetailRow.single(this.left) : right = null;

  const DetailRow.pair(this.left, this.right);

  final DetailSlot left;
  final DetailSlot? right;
}

/// Visible slots, pairing 尺码/款式, 面料/季节, 价格/购入时间 only when
/// they stay next to each other in that order.
List<DetailRow> visibleDetailRows(DetailLayout layout) {
  final slots = [
    for (final slot in layout.slots)
      if (slot.visible) slot,
  ];
  final rows = <DetailRow>[];
  var index = 0;
  while (index < slots.length) {
    final current = slots[index];
    final next = index + 1 < slots.length ? slots[index + 1] : null;
    if (next != null && _isOrderedPair(current.id, next.id)) {
      rows.add(DetailRow.pair(current, next));
      index += 2;
    } else {
      rows.add(DetailRow.single(current));
      index += 1;
    }
  }
  return rows;
}

bool _isOrderedPair(String left, String right) {
  for (final pair in _orderedPairs) {
    if (pair.$1 == left && pair.$2 == right) return true;
  }
  return false;
}

DetailLayout moveDetailSlot(DetailLayout layout, int from, int to) {
  if (from < 0 ||
      to < 0 ||
      from >= layout.slots.length ||
      to >= layout.slots.length) {
    return layout;
  }
  if (from == to) return layout;
  final next = [...layout.slots];
  final slot = next.removeAt(from);
  next.insert(to, slot);
  return DetailLayout(next);
}

DetailLayout setDetailSlotVisible(
  DetailLayout layout,
  String id,
  bool visible,
) {
  var changed = false;
  final next = <DetailSlot>[];
  for (final slot in layout.slots) {
    if (slot.id == id && slot.visible != visible) {
      changed = true;
      next.add(slot.copyWith(visible: visible));
    } else {
      next.add(slot);
    }
  }
  if (!changed) return layout;
  return DetailLayout(next);
}

DetailSlot? customDetailSlot({
  required String id,
  required String label,
  required DetailSlotKind kind,
  required List<String> options,
}) {
  final name = label.trim();
  if (id.trim().isEmpty || name.isEmpty) return null;
  if (kind == DetailSlotKind.builtin) return null;
  final cleaned = _cleanOptions(options);
  if (kind != DetailSlotKind.text && cleaned.isEmpty) return null;
  return DetailSlot(
    id: id.trim(),
    kind: kind,
    visible: true,
    label: name,
    options: kind == DetailSlotKind.text ? const [] : cleaned,
  );
}

DetailLayout appendCustomSlot(DetailLayout layout, DetailSlot slot) {
  if (slot.kind == DetailSlotKind.builtin) return layout;
  if (layout.slots.any((existing) => existing.id == slot.id)) return layout;
  return DetailLayout([...layout.slots, slot]);
}

List<String> _cleanOptions(List<String> options) {
  final seen = <String>{};
  final cleaned = <String>[];
  for (final option in options) {
    final text = option.trim();
    if (text.isEmpty || !seen.add(text)) continue;
    cleaned.add(text);
  }
  return cleaned;
}

String encodeDetailLayout(DetailLayout layout) {
  return jsonEncode({
    'slots': [
      for (final slot in layout.slots)
        {
          'id': slot.id,
          'visible': slot.visible,
          if (slot.kind != DetailSlotKind.builtin) 'kind': slot.kind.name,
          if (slot.kind != DetailSlotKind.builtin) 'label': slot.label,
          if (slot.options.isNotEmpty) 'options': slot.options,
        },
    ],
  });
}

DetailLayout decodeDetailLayout(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map && decoded['slots'] is List) {
      return _normalizeSlots(decoded['slots'] as List);
    }
  } catch (_) {}
  return DetailLayout.standard;
}

DetailLayout _normalizeSlots(List<dynamic> rawSlots) {
  final slots = <DetailSlot>[];
  final seen = <String>{};
  for (final raw in rawSlots) {
    if (raw is! Map) continue;
    final id = '${raw['id'] ?? ''}'.trim();
    if (id.isEmpty || !seen.add(id)) continue;
    final visible = raw['visible'] != false;
    if (builtinDetailLabels.containsKey(id)) {
      slots.add(
        DetailSlot(id: id, kind: DetailSlotKind.builtin, visible: visible),
      );
      continue;
    }
    final kind = _parseKind('${raw['kind'] ?? ''}');
    if (kind == null || kind == DetailSlotKind.builtin) continue;
    final slot = customDetailSlot(
      id: id,
      label: '${raw['label'] ?? ''}',
      kind: kind,
      options: [
        if (raw['options'] is List)
          for (final option in raw['options'] as List) '$option',
      ],
    );
    if (slot == null) continue;
    slots.add(slot.copyWith(visible: visible));
  }
  for (final id in builtinDetailOrder) {
    if (seen.contains(id)) continue;
    slots.add(DetailSlot(id: id, kind: DetailSlotKind.builtin, visible: true));
  }
  return DetailLayout(slots);
}

DetailSlotKind? _parseKind(String raw) {
  for (final kind in DetailSlotKind.values) {
    if (kind.name == raw) return kind;
  }
  return null;
}

List<String> orderedChoices(List<String> options, Set<String> selected) {
  return [
    for (final option in options)
      if (selected.contains(option)) option,
    for (final extra in selected)
      if (!options.contains(extra)) extra,
  ];
}
