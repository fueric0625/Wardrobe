import 'dart:convert';

String encodeMeasurements(Map<String, String> measures) => jsonEncode(measures);

Map<String, String> decodeMeasurements(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return decoded.map(
        (key, value) => MapEntry(_normalizeSizeFieldName('$key'), '$value'),
      );
    }
  } catch (_) {}
  return {};
}

String _normalizeSizeFieldName(String name) => name == '物件' ? '尺寸' : name;
