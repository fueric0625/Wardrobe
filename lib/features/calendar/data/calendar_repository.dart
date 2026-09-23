import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:wardrobe/core/database/app_database.dart';

abstract class CalendarRepository {
  Stream<List<DayEvent>> watchEvents();
  Stream<List<DayOutfit>> watchOutfitLinks();
  Future<void> addEvent(String day, String title);
  Future<void> deleteEvent(String id);
  Future<void> setOutfits(String day, List<String> outfitIds);
}

class LocalCalendarRepository implements CalendarRepository {
  LocalCalendarRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<DayEvent>> watchEvents() {
    return (_db.select(_db.dayEvents)..orderBy([
          (t) => OrderingTerm.asc(t.day),
          (t) => OrderingTerm.asc(t.sortOrder),
        ]))
        .watch();
  }

  @override
  Stream<List<DayOutfit>> watchOutfitLinks() {
    return (_db.select(_db.dayOutfits)..orderBy([
          (t) => OrderingTerm.asc(t.day),
          (t) => OrderingTerm.asc(t.sortOrder),
        ]))
        .watch();
  }

  @override
  Future<void> addEvent(String day, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    final existing = await (_db.select(
      _db.dayEvents,
    )..where((t) => t.day.equals(day))).get();
    await _db
        .into(_db.dayEvents)
        .insert(
          DayEventsCompanion.insert(
            id: const Uuid().v4(),
            day: day,
            title: trimmed,
            sortOrder: Value(existing.length),
          ),
        );
  }

  @override
  Future<void> deleteEvent(String id) async {
    await (_db.delete(_db.dayEvents)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> setOutfits(String day, List<String> outfitIds) async {
    await _db.transaction(() async {
      await (_db.delete(_db.dayOutfits)..where((t) => t.day.equals(day))).go();
      final seen = <String>{};
      var order = 0;
      for (final id in outfitIds) {
        if (!seen.add(id)) continue;
        await _db
            .into(_db.dayOutfits)
            .insert(
              DayOutfitsCompanion.insert(
                day: day,
                outfitId: id,
                sortOrder: Value(order),
              ),
            );
        order++;
      }
    });
  }
}
