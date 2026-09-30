import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/core/list_sort_store.dart';
import 'package:wardrobe/core/sort.dart';

void main() {
  test('a missing or broken sort file falls back to newest first', () {
    expect(decodeRememberedListSorts(''), RememberedListSorts.standard);
    expect(decodeRememberedListSorts('not-json'), RememberedListSorts.standard);
    expect(decodeRememberedListSorts('[]'), RememberedListSorts.standard);
  });

  test('an unknown field or direction resets only that list', () {
    final mixed = decodeRememberedListSorts(
      jsonEncode({
        'clothing': {'field': 'nope', 'direction': 'desc'},
        'outfit': {'field': 'updatedAt', 'direction': 'asc'},
      }),
    );
    expect(mixed.clothing, ListSort.clothingDefault);
    expect(
      mixed.outfit,
      const ListSort(field: SortField.updatedAt, direction: SortDirection.asc),
    );

    final badDirection = decodeRememberedListSorts(
      jsonEncode({
        'clothing': {'field': 'price', 'direction': 'sideways'},
        'outfit': {'field': 'createdAt', 'direction': 'desc'},
      }),
    );
    expect(badDirection.clothing, ListSort.clothingDefault);
    expect(badDirection.outfit, ListSort.outfitDefault);
  });

  test('price is remembered for clothes and rejected for outfits', () {
    final sorts = decodeRememberedListSorts(
      jsonEncode({
        'clothing': {'field': 'price', 'direction': 'asc'},
        'outfit': {'field': 'price', 'direction': 'desc'},
      }),
    );
    expect(
      sorts.clothing,
      const ListSort(field: SortField.price, direction: SortDirection.asc),
    );
    expect(sorts.outfit, ListSort.outfitDefault);

    final again = decodeRememberedListSorts(encodeRememberedListSorts(sorts));
    expect(again.clothing, sorts.clothing);
    expect(again.outfit, sorts.outfit);
  });
}
