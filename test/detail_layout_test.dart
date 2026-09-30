import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/core/serialization/custom_field_codec.dart';
import 'package:wardrobe/features/wardrobe/detail_layout.dart';

void main() {
  test('standard layout pairs the fields that share a row', () {
    final rows = visibleDetailRows(DetailLayout.standard);
    expect(
      rows.map(
        (row) =>
            row.right == null ? row.left.id : '${row.left.id}+${row.right!.id}',
      ),
      [
        BuiltinDetailField.productName,
        BuiltinDetailField.category,
        '${BuiltinDetailField.sizeCode}+${BuiltinDetailField.style}',
        BuiltinDetailField.color,
        '${BuiltinDetailField.fabric}+${BuiltinDetailField.season}',
        BuiltinDetailField.brand,
        BuiltinDetailField.care,
        '${BuiltinDetailField.price}+${BuiltinDetailField.purchasedAt}',
        BuiltinDetailField.measurements,
        BuiltinDetailField.location,
        BuiltinDetailField.tags,
        BuiltinDetailField.note,
        BuiltinDetailField.hangtag,
      ],
    );
  });

  test('moving brand above color keeps the other pairs', () {
    final color = DetailLayout.standard.slots.indexWhere(
      (slot) => slot.id == BuiltinDetailField.color,
    );
    final brand = DetailLayout.standard.slots.indexWhere(
      (slot) => slot.id == BuiltinDetailField.brand,
    );
    final moved = moveDetailSlot(DetailLayout.standard, brand, color);
    expect(
      moved.slots.map((slot) => slot.id).toList(),
      containsAllInOrder([BuiltinDetailField.brand, BuiltinDetailField.color]),
    );
    final rows = visibleDetailRows(moved);
    expect(
      rows.any(
        (row) =>
            row.left.id == BuiltinDetailField.sizeCode &&
            row.right?.id == BuiltinDetailField.style,
      ),
      isTrue,
    );
    expect(
      rows.indexWhere((row) => row.left.id == BuiltinDetailField.brand),
      lessThan(
        rows.indexWhere((row) => row.left.id == BuiltinDetailField.color),
      ),
    );
  });

  test('a field between a pair shows both on their own rows', () {
    final style = DetailLayout.standard.slots.indexWhere(
      (slot) => slot.id == BuiltinDetailField.style,
    );
    final color = DetailLayout.standard.slots.indexWhere(
      (slot) => slot.id == BuiltinDetailField.color,
    );
    final moved = moveDetailSlot(DetailLayout.standard, color, style);
    final rows = visibleDetailRows(moved);
    expect(
      rows.any(
        (row) =>
            row.left.id == BuiltinDetailField.sizeCode && row.right != null,
      ),
      isFalse,
    );
    expect(
      rows
          .where((row) => row.left.id == BuiltinDetailField.sizeCode)
          .single
          .right,
      isNull,
    );
  });

  test(
    'hiding a field keeps it in the layout and drops it from the detail',
    () {
      final hidden = setDetailSlotVisible(
        DetailLayout.standard,
        BuiltinDetailField.note,
        false,
      );
      expect(
        hidden.slots
            .singleWhere((slot) => slot.id == BuiltinDetailField.note)
            .visible,
        isFalse,
      );
      expect(
        visibleDetailRows(hidden)
            .any((row) => row.left.id == BuiltinDetailField.note),
        isFalse,
      );
    },
  );

  test('broken json and a missing builtin fall back without dropping data', () {
    expect(decodeDetailLayout('{').slots, DetailLayout.standard.slots);
    final decoded = decodeDetailLayout(
      '{"slots":[{"id":"productName","visible":false},{"id":"c1","kind":"multi","label":"场合","options":["通勤"," 运动 ","通勤",""]}]}',
    );
    expect(decoded.slots.first.id, BuiltinDetailField.productName);
    expect(decoded.slots.first.visible, isFalse);
    final custom = decoded.slots.singleWhere((slot) => slot.id == 'c1');
    expect(custom.kind, DetailSlotKind.multi);
    expect(custom.options, ['通勤', '运动']);
    expect(
      decoded.slots.map((slot) => slot.id),
      contains(BuiltinDetailField.hangtag),
    );
  });

  test('empty custom fields are rejected and valid ones append', () {
    expect(
      customDetailSlot(
        id: 'c1',
        label: '  ',
        kind: DetailSlotKind.text,
        options: const [],
      ),
      isNull,
    );
    expect(
      customDetailSlot(
        id: 'c1',
        label: '场合',
        kind: DetailSlotKind.multi,
        options: const [' '],
      ),
      isNull,
    );
    final slot = customDetailSlot(
      id: 'c1',
      label: ' 购入店铺 ',
      kind: DetailSlotKind.text,
      options: const ['忽略'],
    )!;
    final layout = appendCustomSlot(DetailLayout.standard, slot);
    expect(layout.slots.last.label, '购入店铺');
    expect(layout.slots.last.options, isEmpty);
    expect(appendCustomSlot(layout, slot).slots.length, layout.slots.length);
  });

  test('custom values round-trip and skip blanks', () {
    final encoded = encodeCustomFieldValues(
      const CustomFieldValues(
        text: {'shop': ' 国贸店 ', 'blank': ' '},
        choices: {
          'scene': ['通勤', ' ', '运动'],
        },
      ),
    );
    final values = decodeCustomFieldValues(encoded);
    expect(values.text, {'shop': '国贸店'});
    expect(values.choices, {
      'scene': ['通勤', '运动'],
    });
    expect(decodeCustomFieldValues('not json'), CustomFieldValues.empty);
  });
}
