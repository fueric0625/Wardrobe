import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';
import 'package:wardrobe/core/catalog/catalogs.dart';
import 'package:wardrobe/core/storage/app_paths.dart';

part 'app_database.g.dart';

class ClothingItems extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get type => text().withDefault(const Constant(''))();
  TextColumn get style => text().withDefault(const Constant(''))();
  TextColumn get color => text().withDefault(const Constant(''))();
  TextColumn get season => text().withDefault(const Constant(''))();
  TextColumn get fabric => text().withDefault(const Constant(''))();
  TextColumn get brand => text().withDefault(const Constant(''))();
  RealColumn get price => real().nullable()();
  TextColumn get measurements => text().withDefault(const Constant('{}'))();
  DateTimeColumn get purchasedAt => dateTime().nullable()();
  TextColumn get purchaseInfo => text().withDefault(const Constant(''))();
  TextColumn get location => text().withDefault(const Constant(''))();
  TextColumn get tags => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Outfits extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get sourceImagePath => text().nullable()();

  /// `photo` uses the full-body image. `collage` uses the arranged clothes.
  TextColumn get coverMode => text().withDefault(const Constant('photo'))();

  /// JSON placements for a manual collage. Empty means an automatic layout.
  TextColumn get collageLayout => text().nullable()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get season => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CategoryCovers extends Table {
  TextColumn get kind => text()();
  TextColumn get categoryId => text()();
  TextColumn get coverItemId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {kind, categoryId};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get label => text()();
  IntColumn get sortOrder => integer()();
  TextColumn get sizeFields => text().withDefault(const Constant('[]'))();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {kind, id};
}

class ClothingItemImages extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text()();
  IntColumn get sortOrder => integer()();
  TextColumn get role => text().withDefault(const Constant('garment'))();
  TextColumn get originalPath => text()();
  TextColumn get processedPath => text().nullable()();
  TextColumn get maskPath => text().nullable()();
  TextColumn get colorJson => text().withDefault(const Constant(''))();
  TextColumn get ocrJson => text().withDefault(const Constant(''))();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Clothes from the wardrobe that belong to one outfit. One clothing item once.
class OutfitItems extends Table {
  TextColumn get outfitId => text()();
  TextColumn get clothingItemId => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {outfitId, clothingItemId};
}

/// A plan note on one calendar day, such as 外出 or 会议.
class DayEvents extends Table {
  TextColumn get id => text()();
  TextColumn get day => text()();
  TextColumn get title => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Outfits planned for a calendar day. One outfit appears once per day.
class DayOutfits extends Table {
  TextColumn get day => text()();
  TextColumn get outfitId => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {day, outfitId};
}

@DriftDatabase(
  tables: [
    ClothingItems,
    Outfits,
    CategoryCovers,
    Categories,
    ClothingItemImages,
    OutfitItems,
    DayEvents,
    DayOutfits,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  AppDatabase.forTesting(QueryExecutor executor) : this(executor);

  /// Snapshots in `drift_schemas/app_database/` start at this version.
  /// Versions below it keep the idempotent upgrades already shipped.
  /// Bump [schemaVersion] on the next change; leave this baseline at 9.
  static const schemaSnapshotBaseline = 9;

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedClothingCategories();
      await seedOutfitCategories();
    },
    onUpgrade: (m, from, to) async {
      if (from < schemaSnapshotBaseline) {
        await _upgradeThroughSchema9(m, from);
      }
      if (to > schemaSnapshotBaseline) {
        await _upgradeFromSchemaSnapshots(
          m,
          from < schemaSnapshotBaseline ? schemaSnapshotBaseline : from,
          to,
        );
      }
    },
  );

  /// Hand-written upgrades for databases created before schema snapshots.
  /// Do not rewrite these into generated steps: `createTable` would use today's
  /// columns and repeat an `addColumn` that those databases already applied.
  Future<void> _upgradeThroughSchema9(Migrator m, int from) async {
    if (from < 2) {
      await _createTableIfMissing(m, categoryCovers);
    }
    if (from < 3) {
      await _createTableIfMissing(m, categories);
      await seedClothingCategories();
    }
    if (from < 4) {
      await seedOutfitCategories();
    }
    if (from < 5) {
      final created = await _createTableIfMissing(m, clothingItemImages);
      if (created) await _backfillItemImages();
    }
    // createTable above uses the current table, which already has ocr_json.
    if (from < 6) {
      await _addColumnIfMissing(
        m,
        clothingItemImages,
        clothingItemImages.ocrJson,
      );
    }
    if (from < 7) {
      await _addColumnIfMissing(m, outfits, outfits.sourceImagePath);
      await _createTableIfMissing(m, outfitItems);
    }
    if (from < 8) {
      await _createTableIfMissing(m, dayEvents);
      await _createTableIfMissing(m, dayOutfits);
    }
    if (from < 9) {
      await _addColumnIfMissing(m, outfits, outfits.coverMode);
      await _addColumnIfMissing(m, outfits, outfits.collageLayout);
    }
  }

  /// Filled after the next schema bump. `dart run drift_dev make-migrations`
  /// writes `app_database.steps.dart`; implement only the newest callback,
  /// for example `from9To10`, and call `stepByStep(...)(m, from, to)` here.
  Future<void> _upgradeFromSchemaSnapshots(Migrator m, int from, int to) {
    throw StateError(
      'Schema $to has no step-by-step migration from $from '
      '(${m.database.schemaVersion}). '
      'Run `dart run drift_dev make-migrations` and fill the newest step.',
    );
  }

  Future<void> seedClothingCategories() {
    return _seedKind(CategoryKind.clothing, clothingCategorySeeds);
  }

  Future<void> seedOutfitCategories() {
    return _seedKind(CategoryKind.outfit, outfitCategorySeeds);
  }

  /// Returns whether the table was created on this call.
  Future<bool> _createTableIfMissing(Migrator m, TableInfo table) async {
    if (await _tableExists(table.actualTableName)) return false;
    await m.createTable(table);
    return true;
  }

  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    if (await _columnExists(table.actualTableName, column.name)) return;
    await m.addColumn(table, column);
  }

  Future<bool> _tableExists(String table) async {
    final rows = await customSelect(
      "SELECT 1 AS ok FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1",
      variables: [Variable<String>(table)],
    ).get();
    return rows.isNotEmpty;
  }

  Future<bool> _columnExists(String table, String column) async {
    final rows = await customSelect('PRAGMA table_info(${_sqlQuote(table)})')
        .get();
    return rows.any((row) => row.read<String>('name') == column);
  }

  String _sqlQuote(String name) => "'${name.replaceAll("'", "''")}'";

  Future<void> _backfillItemImages() async {
    final rows = await select(clothingItems).get();
    for (final row in rows) {
      final path = row.imagePath;
      if (path == null || path.isEmpty) continue;
      await into(clothingItemImages).insert(
        ClothingItemImagesCompanion.insert(
          id: const Uuid().v4(),
          itemId: row.id,
          sortOrder: 0,
          originalPath: path,
          isPrimary: const Value(true),
        ),
      );
    }
  }

  Future<void> _seedKind(
    CategoryKind kind,
    List<ClothingCategorySeed> seeds,
  ) async {
    final existing = await (select(
      categories,
    )..where((t) => t.kind.equals(kind.name))).get();
    if (existing.isNotEmpty) return;
    for (final seed in seeds) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          id: seed.id,
          kind: kind.name,
          label: seed.label,
          sortOrder: seed.sortOrder,
          sizeFields: Value(encodeSizeFields(seed.sizeFields)),
          isSystem: Value(seed.isSystem),
        ),
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await AppPaths.ensureSupportDirectory();
    final file = File(p.join(dir.path, 'wardrobe.sqlite'));
    sqlite3.tempDirectory = AppPaths.tempDirectory().path;
    return NativeDatabase.createInBackground(file);
  });
}
