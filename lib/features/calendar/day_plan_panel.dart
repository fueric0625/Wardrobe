import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/design_system/theme.dart';
import 'package:wardrobe/features/calendar/providers.dart';
import 'package:wardrobe/features/calendar/virtual_weather.dart';
import 'package:wardrobe/features/outfits/providers.dart';
import 'package:wardrobe/widgets/common.dart';
import 'package:wardrobe/widgets/piece_collage.dart';

const schedulePresets = ['外出', '会议', '通勤', '约会', '运动', '居家'];

class DayPlanPanel extends ConsumerStatefulWidget {
  const DayPlanPanel({super.key, required this.date});

  final DateTime date;

  @override
  ConsumerState<DayPlanPanel> createState() => _DayPlanPanelState();
}

class _DayPlanPanelState extends ConsumerState<DayPlanPanel> {
  String get _day => calendarDayKey(widget.date);

  Future<void> _add(String title) async {
    await ref.read(calendarRepositoryProvider).addEvent(_day, title);
  }

  Future<void> _promptSchedule() async {
    final title = await showDialog<String>(
      context: context,
      builder: (context) => const _AddScheduleDialog(),
    );
    if (title == null || !mounted) return;
    await _add(title);
  }

  Future<void> _pickOutfits(List<String> current) async {
    final outfits = ref
        .read(outfitsProvider)
        .maybeWhen(data: (rows) => rows, orElse: () => const <Outfit>[]);
    if (!mounted) return;
    final picked = await showDialog<List<String>>(
      context: context,
      builder: (context) =>
          _OutfitPickDialog(outfits: outfits, selected: current),
    );
    if (picked == null || !mounted) return;
    await ref.read(calendarRepositoryProvider).setOutfits(_day, picked);
  }

  @override
  Widget build(BuildContext context) {
    final events = ref
        .watch(dayEventsProvider)
        .maybeWhen(
          data: (rows) => rows.where((row) => row.day == _day).toList(),
          orElse: () => const <DayEvent>[],
        );
    final links = ref
        .watch(dayOutfitLinksProvider)
        .maybeWhen(
          data: (rows) => rows.where((row) => row.day == _day).toList(),
          orElse: () => const <DayOutfit>[],
        );
    final outfits = ref
        .watch(outfitsProvider)
        .maybeWhen(data: (rows) => rows, orElse: () => const <Outfit>[]);
    final coversById = ref.watch(outfitCoversProvider);
    final byId = {for (final outfit in outfits) outfit.id: outfit};
    final linked = [
      for (final link in links)
        if (byId[link.outfitId] != null) byId[link.outfitId]!,
    ];
    final weather = virtualWeatherFor(widget.date);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListView(
        children: [
          Text(
            calendarDayKey(widget.date),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(weather.icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                weather.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              const Text(
                '虚拟',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            weather.hint,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            '天气以后接入实况',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '日程',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: '添加日程',
                onPressed: _promptSchedule,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (events.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final event in events)
                  InputChip(
                    label: Text(event.title),
                    backgroundColor: AppColors.primarySoft,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onDeleted: () => ref
                        .read(calendarRepositoryProvider)
                        .deleteEvent(event.id),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '穿搭',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () =>
                    _pickOutfits([for (final outfit in linked) outfit.id]),
                child: const Text('选择穿搭'),
              ),
            ],
          ),
          if (linked.isEmpty)
            const Text(
              '这一天还没有穿搭，可以选多套',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: linked.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final outfit = linked[index];
                  final title = outfit.name.trim().isEmpty
                      ? '未命名穿搭'
                      : outfit.name.trim();
                  return SizedBox(
                    width: 120,
                    child: ItemTile(
                      coverPath: outfit.imagePath,
                      cover: outfitCoverArt(coversById[outfit.id]),
                      title: title,
                      subtitle: '',
                      onTap: () => context.push('/outfits/item/${outfit.id}'),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AddScheduleDialog extends StatefulWidget {
  const _AddScheduleDialog();

  @override
  State<_AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<_AddScheduleDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    Navigator.pop(context, trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加日程'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: '例如客户拜访'),
              onSubmitted: _submit,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in schedulePresets)
                  ActionChip(
                    label: Text(preset),
                    onPressed: () => _submit(preset),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => _submit(_controller.text),
          child: const Text('添加'),
        ),
      ],
    );
  }
}

class _OutfitPickDialog extends StatefulWidget {
  const _OutfitPickDialog({required this.outfits, required this.selected});

  final List<Outfit> outfits;
  final List<String> selected;

  @override
  State<_OutfitPickDialog> createState() => _OutfitPickDialogState();
}

class _OutfitPickDialogState extends State<_OutfitPickDialog> {
  late final List<String> _ids = List<String>.of(widget.selected);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('这一天的穿搭'),
      content: SizedBox(
        width: 420,
        height: 360,
        child: widget.outfits.isEmpty
            ? const Center(child: Text('还没有穿搭，先去穿搭里添加'))
            : ListView(
                children: [
                  for (final outfit in widget.outfits)
                    CheckboxListTile(
                      value: _ids.contains(outfit.id),
                      title: Text(
                        outfit.name.trim().isEmpty
                            ? '未命名穿搭'
                            : outfit.name.trim(),
                      ),
                      onChanged: (on) {
                        setState(() {
                          if (on == true) {
                            _ids.add(outfit.id);
                          } else {
                            _ids.remove(outfit.id);
                          }
                        });
                      },
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: widget.outfits.isEmpty
              ? null
              : () => Navigator.pop(context, _ids),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
