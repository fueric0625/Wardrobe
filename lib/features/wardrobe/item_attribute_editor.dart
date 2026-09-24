import 'package:flutter/material.dart';
import 'package:wardrobe/core/design_system/theme.dart';
import 'package:wardrobe/features/wardrobe/item_attributes.dart';

IconData? careGroupIcon(String group) => _careIcons[group];

const _careIcons = <String, IconData>{
  '洗涤': Icons.water_drop_outlined,
  '漂白': Icons.change_history_outlined,
  '干燥': Icons.wb_sunny_outlined,
  '熨烫': Icons.checkroom_outlined,
  '专业护理': Icons.circle_outlined,
};

class StyleEditor extends StatelessWidget {
  const StyleEditor({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final extras = selected.where((item) => !styleOptions.contains(item));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '款式',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          '点一下加入，再点取消。可以同时选多个。',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        for (final group in styleGroups) ...[
          _ChoiceCard(
            title: group.label,
            children: [
              for (final label in group.options)
                _ChoicePill(
                  label: label,
                  selected: selected.contains(label),
                  onTap: () {
                    final next = {...selected};
                    if (!next.add(label)) next.remove(label);
                    onChanged(next);
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (extras.isNotEmpty)
          _ChoiceCard(
            title: '已有',
            children: [
              for (final label in extras)
                _ChoicePill(
                  label: label,
                  selected: true,
                  onTap: () => onChanged({...selected}..remove(label)),
                ),
            ],
          ),
      ],
    );
  }
}

class CareEditor extends StatelessWidget {
  const CareEditor({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '洗涤维护',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          '点一下加入，再点取消。每一组通常只留一个。',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        for (final group in careGroups) ...[
          _ChoiceCard(
            title: group.label,
            icon: _careIcons[group.label],
            children: [
              for (final option in group.options)
                _ChoicePill(
                  label: option.label,
                  icon: _careIcons[group.label],
                  selected: selected.contains(option.id),
                  onTap: () =>
                      onChanged(toggleCare(selected, group, option.id)),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class SelectedLabels extends StatelessWidget {
  const SelectedLabels({
    required this.labels,
    this.icons = const [],
    super.key,
  });

  final List<String> labels;
  final List<IconData?> icons;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return const Text(
        '未填写',
        style: TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < labels.length; i++)
          _ChoicePill(
            label: labels[i],
            icon: i < icons.length ? icons[i] : null,
            selected: true,
          ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.title, required this.children, this.icon});

  final String title;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppPalette.of(context).primary),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    this.icon,
    this.onTap,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppPalette.of(context).primary;
    return Material(
      color: selected ? AppPalette.of(context).primarySoft : AppColors.surface,
      shape: StadiumBorder(
        side: selected
            ? BorderSide.none
            : const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? accent : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: AppColors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String itemCardTitle({required String productName, required String type}) {
  final name = productName.trim();
  if (name.isNotEmpty) return name;
  final legacy = type.trim();
  if (legacy.isNotEmpty) return legacy;
  return '未命名';
}
