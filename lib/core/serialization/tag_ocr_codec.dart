import 'dart:convert';

import 'package:wardrobe/core/vision/ocr/tag_ocr.dart';

String encodeTagOcr(TagOcrResult result) => jsonEncode(result.toJson());

TagOcrResult decodeTagOcr(String raw) {
  if (raw.trim().isEmpty) return const TagOcrResult();
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return TagOcrResult.fromJson(decoded);
    }
    if (decoded is Map) {
      return TagOcrResult.fromJson(decoded.cast<String, dynamic>());
    }
  } catch (_) {}
  return TagOcrResult(lines: raw.split('\n'));
}
