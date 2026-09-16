import 'package:drift/drift.dart';
import 'package:wardrobe/core/catalogs.dart';
import 'package:wardrobe/core/db/app_database.dart';

abstract class CategoryCoverRepository {
  Stream<List<CategoryCover>> watchAll();
  Future<void> setCover({
    required CategoryKind kind,
    required String categoryId,
    String? itemId,
  });
}

String? coverItemIdOf(
  Iterable<CategoryCover> rows,
  CategoryKind kind,
  String categoryId,
) {
  for (final row in rows) {
    if (row.kind == kind.name && row.categoryId == categoryId) {
      return row.coverItemId;
    }
  }
  return null;
}

class LocalCategoryCoverRepository implements CategoryCoverRepository {
  LocalCategoryCoverRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<CategoryCover>> watchAll() {
    return _db.select(_db.categoryCovers).watch();
  }

  @override
  Future<void> setCover({
    required CategoryKind kind,
    required String categoryId,
    String? itemId,
  }) async {
    if (itemId == null) {
      await (_db.delete(_db.categoryCovers)
            ..where(
              (t) => t.kind.equals(kind.name) & t.categoryId.equals(categoryId),
            ))
          .go();
      return;
    }
    await _db.into(_db.categoryCovers).insertOnConflictUpdate(
          CategoryCoversCompanion(
            kind: Value(kind.name),
            categoryId: Value(categoryId),
            coverItemId: Value(itemId),
          ),
        );
  }
}
