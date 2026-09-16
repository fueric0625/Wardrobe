import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/core/sort.dart';

void main() {
  SortKey key({
    required String id,
    required DateTime created,
    DateTime? updated,
    DateTime? purchased,
    double? price,
  }) {
    return SortKey(
      id: id,
      createdAt: created,
      updatedAt: updated ?? created,
      purchasedAt: purchased,
      price: price,
    );
  }

  final older = DateTime(2026, 1, 1);
  final newer = DateTime(2026, 6, 1);

  test('default clothing sort is 添加时间 descending', () {
    expect(ListSort.clothingDefault.fieldLabel, '添加时间');
    expect(ListSort.clothingDefault.direction, SortDirection.desc);
  });

  test('toggling direction flips desc and asc', () {
    expect(ListSort.clothingDefault.toggled.direction, SortDirection.asc);
    expect(ListSort.clothingDefault.toggled.toggled, ListSort.clothingDefault);
  });

  test('price direction labels are 高→低 / 低→高', () {
    expect(
      const ListSort(field: SortField.price, direction: SortDirection.desc)
          .directionLabel,
      '高→低',
    );
    expect(
      const ListSort(field: SortField.price, direction: SortDirection.asc)
          .directionLabel,
      '低→高',
    );
  });

  test('createdAt desc puts newest first', () {
    final items = [
      key(id: 'old', created: older),
      key(id: 'new', created: newer),
    ];
    final sorted = sortByKeys(
      items,
      const ListSort(field: SortField.createdAt, direction: SortDirection.desc),
      (k) => k,
    );
    expect(sorted.map((k) => k.id).toList(), ['new', 'old']);
  });

  test('purchasedAt keeps missing dates after filled ones in both directions', () {
    final withDate = key(id: 'dated', created: older, purchased: newer);
    final missing = key(id: 'missing', created: newer);
    final desc = sortByKeys(
      [missing, withDate],
      const ListSort(field: SortField.purchasedAt, direction: SortDirection.desc),
      (k) => k,
    );
    final asc = sortByKeys(
      [missing, withDate],
      const ListSort(field: SortField.purchasedAt, direction: SortDirection.asc),
      (k) => k,
    );
    expect(desc.map((k) => k.id).toList(), ['dated', 'missing']);
    expect(asc.map((k) => k.id).toList(), ['dated', 'missing']);
  });

  test('price keeps missing values after priced items', () {
    final cheap = key(id: 'cheap', created: older, price: 10);
    final expensive = key(id: 'expensive', created: older, price: 90);
    final none = key(id: 'none', created: newer);
    final desc = sortByKeys(
      [none, cheap, expensive],
      const ListSort(field: SortField.price, direction: SortDirection.desc),
      (k) => k,
    );
    expect(desc.map((k) => k.id).toList(), ['expensive', 'cheap', 'none']);
  });

  test('newestByCreatedAt ignores list order', () {
    final a = key(id: 'a', created: older);
    final b = key(id: 'b', created: newer);
    expect(newestByCreatedAt([a, b], (k) => k.createdAt)?.id, 'b');
    expect(newestByCreatedAt([b, a], (k) => k.createdAt)?.id, 'b');
  });

  test('pickCoverItem uses custom id when present', () {
    final a = key(id: 'a', created: newer);
    final b = key(id: 'b', created: older);
    expect(
      pickCoverItem(
        items: [a, b],
        idOf: (k) => k.id,
        createdAt: (k) => k.createdAt,
        coverItemId: 'b',
      )?.id,
      'b',
    );
  });

  test('pickCoverItem falls back to newest when custom id is missing', () {
    final a = key(id: 'a', created: older);
    final b = key(id: 'b', created: newer);
    expect(
      pickCoverItem(
        items: [a, b],
        idOf: (k) => k.id,
        createdAt: (k) => k.createdAt,
        coverItemId: 'gone',
      )?.id,
      'b',
    );
  });
}
