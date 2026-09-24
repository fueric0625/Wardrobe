import 'package:drift/drift.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/serialization/measurement_codec.dart';

/// Fields the item form is ready to write. The page does not assemble the row.
class ItemEditDraft {
  const ItemEditDraft({
    required this.id,
    required this.categoryId,
    required this.productName,
    required this.sizeCode,
    required this.careJson,
    required this.type,
    required this.style,
    required this.color,
    required this.season,
    required this.fabric,
    required this.brand,
    required this.priceText,
    required this.measurements,
    required this.purchaseInfo,
    required this.location,
    required this.tags,
    required this.note,
    required this.now,
    this.purchasedAt,
    this.createdAt,
  });

  final String id;
  final String categoryId;
  final String productName;
  final String sizeCode;
  final String careJson;
  final String type;
  final String style;
  final String color;
  final String season;
  final String fabric;
  final String brand;
  final String priceText;
  final Map<String, String> measurements;
  final String purchaseInfo;
  final String location;
  final String tags;
  final String note;
  final DateTime now;
  final DateTime? purchasedAt;
  final DateTime? createdAt;

  ClothingItemsCompanion toCompanion() {
    final price = priceText.trim().isEmpty
        ? null
        : double.tryParse(priceText.trim());
    return ClothingItemsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      type: Value(type.trim()),
      productName: Value(productName.trim()),
      sizeCode: Value(sizeCode.trim()),
      style: Value(style.trim()),
      careJson: Value(careJson.trim()),
      color: Value(color.trim()),
      season: Value(season),
      fabric: Value(fabric.trim()),
      brand: Value(brand.trim()),
      price: Value(price),
      measurements: Value(encodeMeasurements(measurements)),
      purchasedAt: Value(purchasedAt),
      purchaseInfo: Value(purchaseInfo.trim()),
      location: Value(location.trim()),
      tags: Value(tags.trim()),
      note: Value(note.trim()),
      createdAt: Value(createdAt ?? now),
      updatedAt: Value(now),
    );
  }
}
