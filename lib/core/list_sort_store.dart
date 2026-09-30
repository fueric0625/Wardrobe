import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:wardrobe/core/sort.dart';
import 'package:wardrobe/core/storage/app_paths.dart';

class RememberedListSorts {
  const RememberedListSorts({required this.clothing, required this.outfit});

  static const standard = RememberedListSorts(
    clothing: ListSort.clothingDefault,
    outfit: ListSort.outfitDefault,
  );

  final ListSort clothing;
  final ListSort outfit;

  RememberedListSorts copyWith({ListSort? clothing, ListSort? outfit}) {
    return RememberedListSorts(
      clothing: clothing ?? this.clothing,
      outfit: outfit ?? this.outfit,
    );
  }
}

String encodeRememberedListSorts(RememberedListSorts sorts) {
  return jsonEncode({
    'clothing': _encodeOne(sorts.clothing),
    'outfit': _encodeOne(sorts.outfit),
  });
}

/// A missing file, broken JSON, or an unknown field or direction sends that
/// list back to 「添加时间、新的在前」. The other list is kept when its own
/// section is still readable.
RememberedListSorts decodeRememberedListSorts(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return RememberedListSorts.standard;
    return RememberedListSorts(
      clothing: _decodeOne(
        decoded['clothing'],
        fields: ListSort.clothingFields,
        fallback: ListSort.clothingDefault,
      ),
      outfit: _decodeOne(
        decoded['outfit'],
        fields: ListSort.outfitFields,
        fallback: ListSort.outfitDefault,
      ),
    );
  } catch (_) {
    return RememberedListSorts.standard;
  }
}

Map<String, String> _encodeOne(ListSort sort) {
  return {'field': sort.field.name, 'direction': sort.direction.name};
}

ListSort _decodeOne(
  Object? raw, {
  required List<SortField> fields,
  required ListSort fallback,
}) {
  if (raw is! Map) return fallback;
  final fieldName = raw['field'];
  final directionName = raw['direction'];
  SortField? field;
  for (final candidate in SortField.values) {
    if (candidate.name == fieldName) field = candidate;
  }
  SortDirection? direction;
  for (final candidate in SortDirection.values) {
    if (candidate.name == directionName) direction = candidate;
  }
  if (field == null || direction == null || !fields.contains(field)) {
    return fallback;
  }
  return ListSort(field: field, direction: direction);
}

class ListSortStore {
  static Future<File> _file() async {
    final dir = await AppPaths.ensureSupportDirectory();
    return File(p.join(dir.path, 'list_sort.json'));
  }

  static Future<RememberedListSorts> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return RememberedListSorts.standard;
      return decodeRememberedListSorts(await file.readAsString());
    } catch (_) {
      return RememberedListSorts.standard;
    }
  }

  static Future<void> write(RememberedListSorts sorts) async {
    final file = await _file();
    await file.writeAsString(encodeRememberedListSorts(sorts));
  }
}

final rememberedListSortSeedProvider = Provider<RememberedListSorts>(
  (ref) => RememberedListSorts.standard,
);
