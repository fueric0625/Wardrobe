class StyleGroup {
  const StyleGroup({required this.label, required this.options});

  final String label;
  final List<String> options;
}

const styleGroups = <StyleGroup>[
  StyleGroup(label: '版型', options: ['修身', '直身', '宽松', '落肩']),
  StyleGroup(label: '袖长', options: ['无袖', '短袖', '五分袖', '长袖']),
  StyleGroup(label: '领型', options: ['圆领', 'V领', '翻领', '连帽', '高领']),
  StyleGroup(label: '结构', options: ['假两件', '开衫', '套头']),
];

final styleOptions = {for (final group in styleGroups) ...group.options};

Set<String> decodeStyle(String raw) {
  return {
    for (final part in raw.split(RegExp(r'[,，、]')))
      if (part.trim().isNotEmpty) part.trim(),
  };
}

List<String> orderedStyle(Set<String> selected) {
  return [
    for (final option in styleOptions)
      if (selected.contains(option)) option,
    for (final extra in selected)
      if (!styleOptions.contains(extra)) extra,
  ];
}

String encodeStyle(Set<String> selected) => orderedStyle(selected).join(',');

class CareOption {
  const CareOption({required this.id, required this.label});

  final String id;
  final String label;
}

class CareGroup {
  const CareGroup({required this.label, required this.options});

  final String label;
  final List<CareOption> options;

  Set<String> get ids => {for (final option in options) option.id};
}

const careGroups = <CareGroup>[
  CareGroup(
    label: '洗涤',
    options: [
      CareOption(id: 'wash-95', label: '95℃'),
      CareOption(id: 'wash-70', label: '70℃'),
      CareOption(id: 'wash-60', label: '60℃'),
      CareOption(id: 'wash-60-mild', label: '60℃ 缓和'),
      CareOption(id: 'wash-50', label: '50℃'),
      CareOption(id: 'wash-50-mild', label: '50℃ 缓和'),
      CareOption(id: 'wash-40', label: '40℃'),
      CareOption(id: 'wash-40-mild', label: '40℃ 缓和'),
      CareOption(id: 'wash-40-gentle', label: '40℃ 非常缓和'),
      CareOption(id: 'wash-30', label: '30℃'),
      CareOption(id: 'wash-30-mild', label: '30℃ 缓和'),
      CareOption(id: 'wash-30-gentle', label: '30℃ 非常缓和'),
      CareOption(id: 'wash-hand', label: '手洗'),
      CareOption(id: 'wash-none', label: '不可水洗'),
    ],
  ),
  CareGroup(
    label: '漂白',
    options: [
      CareOption(id: 'bleach-any', label: '可漂白'),
      CareOption(id: 'bleach-non-chlorine', label: '仅非氯漂'),
      CareOption(id: 'bleach-none', label: '不可漂白'),
    ],
  ),
  CareGroup(
    label: '干燥',
    options: [
      CareOption(id: 'dry-tumble', label: '滚筒普通'),
      CareOption(id: 'dry-tumble-mild', label: '滚筒缓和'),
      CareOption(id: 'dry-tumble-none', label: '不可滚筒'),
      CareOption(id: 'dry-line', label: '悬挂晾干'),
      CareOption(id: 'dry-drip', label: '滴干'),
      CareOption(id: 'dry-flat', label: '平摊'),
      CareOption(id: 'dry-line-shade', label: '悬挂阴干'),
      CareOption(id: 'dry-drip-shade', label: '滴干阴干'),
      CareOption(id: 'dry-flat-shade', label: '平摊阴干'),
    ],
  ),
  CareGroup(
    label: '熨烫',
    options: [
      CareOption(id: 'iron-low', label: '低温'),
      CareOption(id: 'iron-medium', label: '中温'),
      CareOption(id: 'iron-high', label: '高温'),
      CareOption(id: 'iron-none', label: '不可熨烫'),
    ],
  ),
  CareGroup(
    label: '专业护理',
    options: [
      CareOption(id: 'clean-p', label: '干洗'),
      CareOption(id: 'clean-p-mild', label: '干洗缓和'),
      CareOption(id: 'clean-p-gentle', label: '干洗非常缓和'),
      CareOption(id: 'clean-p-none', label: '不可干洗'),
      CareOption(id: 'clean-f', label: '石油溶剂'),
      CareOption(id: 'clean-f-mild', label: '石油溶剂缓和'),
      CareOption(id: 'clean-w', label: '湿洗'),
      CareOption(id: 'clean-w-mild', label: '湿洗缓和'),
      CareOption(id: 'clean-w-gentle', label: '湿洗非常缓和'),
      CareOption(id: 'clean-w-none', label: '不可湿洗'),
    ],
  ),
];

final careOptions = {
  for (final group in careGroups)
    for (final option in group.options) option.id: option,
};

Set<String> decodeCare(String raw) {
  return {
    for (final part in raw.split(','))
      if (careOptions.containsKey(part.trim())) part.trim(),
  };
}

String encodeCare(Set<String> selected) {
  return [
    for (final group in careGroups)
      for (final option in group.options)
        if (selected.contains(option.id)) option.id,
  ].join(',');
}

Set<String> toggleCare(Set<String> selected, CareGroup group, String id) {
  final next = {...selected};
  if (next.contains(id)) {
    next.remove(id);
    return next;
  }
  next.removeAll(group.ids);
  next.add(id);
  return next;
}
