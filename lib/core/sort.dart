import 'package:flutter/foundation.dart';
import 'package:wardrobe/core/database/app_database.dart';

enum SortField {
  createdAt,
  purchasedAt,
  updatedAt,
  price;

  String get label => switch (this) {
    createdAt => '添加时间',
    purchasedAt => '购买时间',
    updatedAt => '修改时间',
    price => '价格',
  };
}

enum SortDirection { desc, asc }

@immutable
class ListSort {
  const ListSort({required this.field, required this.direction});

  static const clothingDefault = ListSort(
    field: SortField.createdAt,
    direction: SortDirection.desc,
  );

  static const outfitDefault = ListSort(
    field: SortField.createdAt,
    direction: SortDirection.desc,
  );

  static const clothingFields = [
    SortField.createdAt,
    SortField.purchasedAt,
    SortField.updatedAt,
    SortField.price,
  ];

  static const outfitFields = [SortField.createdAt, SortField.updatedAt];

  final SortField field;
  final SortDirection direction;

  String get fieldLabel => field.label;

  String get directionLabel => field == SortField.price
      ? (direction == SortDirection.desc ? '高→低' : '低→高')
      : (direction == SortDirection.desc ? '新→旧' : '旧→新');

  ListSort get toggled => ListSort(
    field: field,
    direction: direction == SortDirection.desc
        ? SortDirection.asc
        : SortDirection.desc,
  );

  ListSort withField(SortField next) =>
      ListSort(field: next, direction: direction);

  @override
  bool operator ==(Object other) =>
      other is ListSort && other.field == field && other.direction == direction;

  @override
  int get hashCode => Object.hash(field, direction);
}

@immutable
class SortKey {
  const SortKey({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.purchasedAt,
    this.price,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? purchasedAt;
  final double? price;
}

int compareSortKeys(SortKey a, SortKey b, ListSort sort) {
  final descending = sort.direction == SortDirection.desc;
  final cmp = switch (sort.field) {
    SortField.createdAt => _compareNonNull(
      a.createdAt,
      b.createdAt,
      descending,
    ),
    SortField.updatedAt => _compareNonNull(
      a.updatedAt,
      b.updatedAt,
      descending,
    ),
    SortField.purchasedAt => _compareNullable(
      a.purchasedAt,
      b.purchasedAt,
      descending,
    ),
    SortField.price => _compareNullable(a.price, b.price, descending),
  };
  if (cmp != 0) return cmp;
  return a.id.compareTo(b.id);
}

int _compareNonNull<T extends Comparable<T>>(T a, T b, bool descending) {
  final cmp = a.compareTo(b);
  return descending ? -cmp : cmp;
}

/// Missing values always sort after filled ones, regardless of direction.
int _compareNullable<T extends Comparable<T>>(T? a, T? b, bool descending) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return _compareNonNull(a, b, descending);
}

List<T> sortByKeys<T>(
  Iterable<T> items,
  ListSort sort,
  SortKey Function(T) keyOf,
) {
  final copy = [...items];
  copy.sort((a, b) => compareSortKeys(keyOf(a), keyOf(b), sort));
  return copy;
}

List<ClothingItem> sortClothingItems(
  Iterable<ClothingItem> items,
  ListSort sort,
) {
  return sortByKeys(
    items,
    sort,
    (item) => SortKey(
      id: item.id,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      purchasedAt: item.purchasedAt,
      price: item.price,
    ),
  );
}

List<Outfit> sortOutfits(Iterable<Outfit> items, ListSort sort) {
  final safe = ListSort.outfitFields.contains(sort.field)
      ? sort
      : ListSort.outfitDefault;
  return sortByKeys(
    items,
    safe,
    (item) => SortKey(
      id: item.id,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    ),
  );
}

T? newestByCreatedAt<T>(Iterable<T> items, DateTime Function(T) createdAt) {
  T? best;
  for (final item in items) {
    if (best == null || createdAt(item).isAfter(createdAt(best))) {
      best = item;
    }
  }
  return best;
}

T? pickCoverItem<T>({
  required Iterable<T> items,
  required String Function(T) idOf,
  required DateTime Function(T) createdAt,
  String? coverItemId,
}) {
  if (coverItemId != null) {
    for (final item in items) {
      if (idOf(item) == coverItemId) return item;
    }
  }
  return newestByCreatedAt(items, createdAt);
}
