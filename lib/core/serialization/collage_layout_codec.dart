import 'dart:convert';

import 'package:wardrobe/features/outfits/domain/collage_placement.dart';

/// `x/y/w/h` are fractions of the fixed 3:4 collage canvas and are restored
/// as stored, including values outside `0..1`. Empty string means the user
/// removed the collage. Null or missing layout means there is no saved
/// arrangement.
List<CollagePlacement> decodeCollageLayout(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final placements = <CollagePlacement>[];
    for (final entry in decoded) {
      if (entry is! Map) continue;
      final id = entry['id'];
      if (id is! String || id.isEmpty) continue;
      placements.add(
        CollagePlacement(
          clothingItemId: id,
          x: _num(entry['x']),
          y: _num(entry['y']),
          w: _num(entry['w'], fallback: 0.4),
          h: _num(entry['h'], fallback: 0.4),
          z: (entry['z'] as num?)?.round() ?? placements.length,
        ),
      );
    }
    return placements;
  } catch (_) {
    return const [];
  }
}

String? encodeCollageLayout(List<CollagePlacement> placements) {
  if (placements.isEmpty) return null;
  return jsonEncode([
    for (final placement in placements)
      {
        'id': placement.clothingItemId,
        'x': placement.x,
        'y': placement.y,
        'w': placement.w,
        'h': placement.h,
        'z': placement.z,
      },
  ]);
}

double _num(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return fallback;
}
