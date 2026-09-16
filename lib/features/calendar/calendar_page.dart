import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lunar/lunar.dart';
import 'package:wardrobe/core/theme.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _visibleMonth;
  late DateTime _selected;

  static const _weekdays = ['日', '一', '二', '三', '四', '五', '六'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _visibleMonth = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _selected = DateTime(now.year, now.month, now.day);
      _visibleMonth = DateTime(now.year, now.month);
    });
  }

  List<DateTime> _daysInGrid() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final leading = first.weekday % 7;
    final start = first.subtract(Duration(days: leading));
    return List.generate(42, (i) => DateTime(start.year, start.month, start.day + i));
  }

  String _lunarLabel(DateTime date) {
    final lunar = Lunar.fromDate(date);
    if (lunar.getDay() == 1) {
      return '${lunar.getMonthInChinese()}月';
    }
    return lunar.getDayInChinese();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = _daysInGrid();

    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 24, 36, 28),
      child: Column(
        children: [
          Row(
            children: [
              _CircleButton(label: '今', onTap: _goToday),
              const Spacer(),
              IconButton(
                onPressed: () => _shiftMonth(-1),
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(backgroundColor: AppColors.primarySoft),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  DateFormat('yyyy-MM').format(_visibleMonth),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => _shiftMonth(1),
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(backgroundColor: AppColors.primarySoft),
              ),
              const Spacer(),
              IconButton(
                tooltip: '筛选（后续开放）',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('筛选后续开放')),
                  );
                },
                icon: const Icon(Icons.tune, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    for (final day in _weekdays)
                      Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Column(
                    children: [
                      for (var week = 0; week < 6; week++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                for (var weekday = 0; weekday < 7; weekday++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: _DayCell(
                                        date: days[week * 7 + weekday],
                                        lunar: _lunarLabel(days[week * 7 + weekday]),
                                        inMonth: days[week * 7 + weekday].month ==
                                            _visibleMonth.month,
                                        selected: _sameDay(
                                          days[week * 7 + weekday],
                                          _selected,
                                        ),
                                        isToday: _sameDay(days[week * 7 + weekday], today),
                                        onTap: () => setState(
                                          () => _selected = days[week * 7 + weekday],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              DateFormat('yyyy-MM-dd').format(_selected),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('添加穿着记录后续开放')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('点击添加记录'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(220, 48),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.lunar,
    required this.inMonth,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final String lunar;
  final bool inMonth;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primarySoft : AppColors.surface;
    final solarColor = !inMonth
        ? AppColors.textMuted.withValues(alpha: 0.45)
        : AppColors.text;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: isToday
                    ? const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)
                    : null,
                child: Text(
                  date.day.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isToday ? Colors.white : solarColor,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                lunar,
                style: TextStyle(
                  fontSize: 11,
                  color: inMonth ? AppColors.textMuted : AppColors.textMuted.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
