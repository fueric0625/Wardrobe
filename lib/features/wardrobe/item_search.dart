import 'package:wardrobe/core/catalog/category_tree.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/serialization/custom_field_codec.dart';
import 'package:wardrobe/features/wardrobe/detail_layout.dart';
import 'package:wardrobe/features/wardrobe/item_attributes.dart';

/// Case-insensitive match against fields the shared layout currently shows.
///
/// Price, purchase date, measurements, and hangtag text are never searched.
/// The legacy [ClothingItem.type] always is, even though the page no longer
/// shows it.
bool clothingItemMatches({
  required ClothingItem item,
  required DetailLayout layout,
  required List<Category> categories,
  required String query,
}) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  return _searchText(item, layout, categories).toLowerCase().contains(needle);
}

String _searchText(
  ClothingItem item,
  DetailLayout layout,
  List<Category> categories,
) {
  final parts = <String>[item.type];
  void add(String id, String value) {
    if (_slotVisible(layout, id)) parts.add(value);
  }

  add(BuiltinDetailField.productName, item.productName);
  add(BuiltinDetailField.sizeCode, item.sizeCode);
  add(BuiltinDetailField.style, item.style);
  add(BuiltinDetailField.color, item.color);
  add(BuiltinDetailField.fabric, item.fabric);
  add(BuiltinDetailField.season, item.season);
  add(BuiltinDetailField.brand, item.brand);
  if (_slotVisible(layout, BuiltinDetailField.care)) {
    for (final id in decodeCare(item.careJson)) {
      final label = careOptions[id]?.label;
      if (label != null) parts.add(label);
    }
  }
  if (_slotVisible(layout, BuiltinDetailField.category)) {
    parts.add(categoryPath(categories, item.categoryId));
  }
  add(BuiltinDetailField.location, item.location);
  add(BuiltinDetailField.tags, item.tags);
  add(BuiltinDetailField.note, item.note);

  final custom = decodeCustomFieldValues(item.customJson);
  for (final slot in layout.slots) {
    if (!slot.visible || slot.kind == DetailSlotKind.builtin) continue;
    if (slot.kind == DetailSlotKind.multi) {
      parts.addAll(custom.choices[slot.id] ?? const []);
    } else {
      final text = custom.text[slot.id];
      if (text != null) parts.add(text);
    }
  }
  return parts.join(' ');
}

bool _slotVisible(DetailLayout layout, String id) {
  for (final slot in layout.slots) {
    if (slot.id == id) return slot.visible;
  }
  return false;
}
