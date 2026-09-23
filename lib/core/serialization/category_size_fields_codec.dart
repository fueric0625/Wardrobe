import 'dart:convert';

String encodeSizeFields(List<String> fields) => jsonEncode(fields);

List<String> decodeSizeFields(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .map((entry) => _normalizeSizeFieldName('$entry'))
          .where((name) => name.isNotEmpty)
          .toList();
    }
  } catch (_) {}
  return [];
}

String _normalizeSizeFieldName(String name) => name == '物件' ? '尺寸' : name;
