import 'package:flutter/material.dart';

class VirtualWeather {
  const VirtualWeather({
    required this.label,
    required this.icon,
    required this.hint,
  });

  final String label;
  final IconData icon;
  final String hint;
}

const virtualWeathers = <VirtualWeather>[
  VirtualWeather(label: '晴', icon: Icons.wb_sunny_outlined, hint: '适合轻便单品'),
  VirtualWeather(label: '多云', icon: Icons.cloud_outlined, hint: '可以加一件薄外套'),
  VirtualWeather(label: '阴', icon: Icons.cloud_queue, hint: '颜色可以亮一点'),
  VirtualWeather(label: '小雨', icon: Icons.water_drop_outlined, hint: '考虑防水面料'),
];

/// Stand-in until a weather service is connected. Stable for the same date.
VirtualWeather virtualWeatherFor(DateTime day) {
  final index = (day.year + day.month * 31 + day.day) % virtualWeathers.length;
  return virtualWeathers[index];
}

String calendarDayKey(DateTime day) {
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$date';
}
