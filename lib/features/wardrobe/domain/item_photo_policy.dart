import 'package:wardrobe/features/wardrobe/photo_role.dart';

/// List and cover use the cutout when one exists, otherwise the original.
String? preferredItemDisplayPath({
  required String? processedPath,
  required String? originalPath,
}) {
  if (processedPath != null && processedPath.isNotEmpty) return processedPath;
  if (originalPath != null && originalPath.isNotEmpty) return originalPath;
  return null;
}

/// Hangtag photos cannot be the item cover or an outfit collage piece.
bool photoCanBeCover(ItemPhotoRole role) => role == ItemPhotoRole.garment;

/// Recognition fills an empty field. Existing text stays.
String fillEmptyField(String current, String? suggestion) {
  if (current.trim().isNotEmpty) return current;
  final next = suggestion?.trim() ?? '';
  if (next.isEmpty) return current;
  return next;
}
