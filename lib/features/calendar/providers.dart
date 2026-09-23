import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wardrobe/app/providers.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/features/calendar/data/calendar_repository.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return LocalCalendarRepository(ref.watch(databaseProvider));
});

final dayEventsProvider = StreamProvider<List<DayEvent>>((ref) {
  return ref.watch(calendarRepositoryProvider).watchEvents();
});

final dayOutfitLinksProvider = StreamProvider<List<DayOutfit>>((ref) {
  return ref.watch(calendarRepositoryProvider).watchOutfitLinks();
});
