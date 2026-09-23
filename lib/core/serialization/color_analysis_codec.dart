import 'dart:convert';

import 'package:wardrobe/core/vision/cutout/color_extract.dart';

String encodeColorAnalysis(ColorAnalysis analysis) => jsonEncode({
  'colors': analysis.colors.map((c) => c.toJson()).toList(),
  if (analysis.palette.isNotEmpty)
    'palette': analysis.palette.map((c) => c.toJson()).toList(),
});

ColorAnalysis decodeColorAnalysis(String raw) {
  if (raw.trim().isEmpty) return ColorAnalysis.empty;
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final list = map['colors'] as List<dynamic>? ?? const [];
    final pal = map['palette'] as List<dynamic>? ?? const [];
    return ColorAnalysis(
      [
        for (final item in list)
          if (item is Map<String, dynamic>) ColorShare.fromJson(item),
      ],
      palette: [
        for (final item in pal)
          if (item is Map<String, dynamic>) RgbSwatch.fromJson(item),
      ],
    );
  } catch (_) {
    return ColorAnalysis.empty;
  }
}
