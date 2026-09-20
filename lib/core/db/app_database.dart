import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:wardrobe/core/catalogs.dart';
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

@DriftDatabase(tables: [ClothingItems, Outfits, CategoryCovers, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seedClothingCategories();
          await seedOutfitCategories();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(categoryCovers);
          }
          if (from < 3) {
            await m.createTable(categories);
            await seedClothingCategories();
          }
          if (from < 4) {
            await seedOutfitCategories();
          }
        },
      );

  Future<void> seedClothingCategories() {
    return _seedKind(CategoryKind.clothing, clothingCategorySeeds);
  }

  Future<void> seedOutfitCategories() {
    return _seedKind(CategoryKind.outfit, outfitCategorySeeds);
  }

  Future<void> _seedKind(
    CategoryKind kind,
    List<ClothingCategorySeed> seeds,
  ) async {
    final existing = await (select(categories)
          ..where((t) => t.kind.equals(kind.name)))
        .get();
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
