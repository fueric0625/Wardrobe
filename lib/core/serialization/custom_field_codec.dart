import 'dart:convert';

class CustomFieldValues {
  const CustomFieldValues({this.text = const {}, this.choices = const {}});

  final Map<String, String> text;
  final Map<String, List<String>> choices;

  static const empty = CustomFieldValues();
}

String encodeCustomFieldValues(CustomFieldValues values) {
  final payload = <String, Object>{};
  for (final entry in values.text.entries) {
    final text = entry.key.trim().isEmpty ? '' : entry.value.trim();
    if (entry.key.trim().isEmpty || text.isEmpty) continue;
    payload[entry.key.trim()] = text;
  }
  for (final entry in values.choices.entries) {
    if (entry.key.trim().isEmpty) continue;
    final choices = [
      for (final choice in entry.value)
        if (choice.trim().isNotEmpty) choice.trim(),
    ];
    if (choices.isEmpty) continue;
    payload[entry.key.trim()] = choices;
  }
  if (payload.isEmpty) return '';
  return jsonEncode(payload);
}

CustomFieldValues decodeCustomFieldValues(String raw) {
  if (raw.trim().isEmpty) return CustomFieldValues.empty;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return CustomFieldValues.empty;
    final text = <String, String>{};
    final choices = <String, List<String>>{};
    for (final entry in decoded.entries) {
      final id = '${entry.key}'.trim();
      if (id.isEmpty) continue;
      final value = entry.value;
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) text[id] = trimmed;
      } else if (value is List) {
        final items = [
          for (final item in value)
            if ('$item'.trim().isNotEmpty) '$item'.trim(),
        ];
        if (items.isNotEmpty) choices[id] = items;
      }
    }
    return CustomFieldValues(text: text, choices: choices);
  } catch (_) {
    return CustomFieldValues.empty;
  }
}
