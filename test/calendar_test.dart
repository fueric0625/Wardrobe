import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/features/calendar/virtual_weather.dart';

void main() {
  test('calendar day key is yyyy-MM-dd', () {
    expect(calendarDayKey(DateTime(2026, 9, 3)), '2026-09-03');
  });

  test('virtual weather stays the same for a date', () {
    final day = DateTime(2026, 9, 22);
    final first = virtualWeatherFor(day);
    final again = virtualWeatherFor(day);
    expect(again.label, first.label);
    expect(again.hint, isNotEmpty);
  });
}
