// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v9.dart' as v9;
import 'generated/schema_v10.dart' as v10;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // The following template shows how to write tests ensuring your migrations
  // preserve existing data.
  // Testing this can be useful for migrations that change existing columns
  // (e.g. by alterating their type or constraints). Migrations that only add
  // tables or columns typically don't need these advanced tests. For more
  // information, see https://drift.simonbinder.eu/migrations/tests/#verifying-data-integrity
  // TODO: This generated template shows how these tests could be written. Adopt
  // it to your own needs when testing migrations with data integrity.
  test('migration from v9 to v10 does not corrupt data', () async {
    // Add data to insert into the old database, and the expected rows after the
    // migration.
    // TODO: Fill these lists
    final oldClothingItemsData = <v9.ClothingItemsData>[];
    final expectedNewClothingItemsData = <v10.ClothingItemsData>[];

    final oldOutfitsData = <v9.OutfitsData>[];
    final expectedNewOutfitsData = <v10.OutfitsData>[];

    final oldCategoryCoversData = <v9.CategoryCoversData>[];
    final expectedNewCategoryCoversData = <v10.CategoryCoversData>[];

    final oldCategoriesData = <v9.CategoriesData>[];
    final expectedNewCategoriesData = <v10.CategoriesData>[];

    final oldClothingItemImagesData = <v9.ClothingItemImagesData>[];
    final expectedNewClothingItemImagesData = <v10.ClothingItemImagesData>[];

    final oldOutfitItemsData = <v9.OutfitItemsData>[];
    final expectedNewOutfitItemsData = <v10.OutfitItemsData>[];

    final oldDayEventsData = <v9.DayEventsData>[];
    final expectedNewDayEventsData = <v10.DayEventsData>[];

    final oldDayOutfitsData = <v9.DayOutfitsData>[];
    final expectedNewDayOutfitsData = <v10.DayOutfitsData>[];

    await verifier.testWithDataIntegrity(
      oldVersion: 9,
      newVersion: 10,
      createOld: v9.DatabaseAtV9.new,
      createNew: v10.DatabaseAtV10.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.clothingItems, oldClothingItemsData);
        batch.insertAll(oldDb.outfits, oldOutfitsData);
        batch.insertAll(oldDb.categoryCovers, oldCategoryCoversData);
        batch.insertAll(oldDb.categories, oldCategoriesData);
        batch.insertAll(oldDb.clothingItemImages, oldClothingItemImagesData);
        batch.insertAll(oldDb.outfitItems, oldOutfitItemsData);
        batch.insertAll(oldDb.dayEvents, oldDayEventsData);
        batch.insertAll(oldDb.dayOutfits, oldDayOutfitsData);
      },
      validateItems: (newDb) async {
        expect(
          expectedNewClothingItemsData,
          await newDb.select(newDb.clothingItems).get(),
        );
        expect(expectedNewOutfitsData, await newDb.select(newDb.outfits).get());
        expect(
          expectedNewCategoryCoversData,
          await newDb.select(newDb.categoryCovers).get(),
        );
        expect(
          expectedNewCategoriesData,
          await newDb.select(newDb.categories).get(),
        );
        expect(
          expectedNewClothingItemImagesData,
          await newDb.select(newDb.clothingItemImages).get(),
        );
        expect(
          expectedNewOutfitItemsData,
          await newDb.select(newDb.outfitItems).get(),
        );
        expect(
          expectedNewDayEventsData,
          await newDb.select(newDb.dayEvents).get(),
        );
        expect(
          expectedNewDayOutfitsData,
          await newDb.select(newDb.dayOutfits).get(),
        );
      },
    );
  });
}
