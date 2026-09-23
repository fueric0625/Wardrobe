import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:wardrobe/core/database/app_database.dart';

void main() {
  test('upgrade from schema 4 does not add ocr_json twice', () async {
    final raw = sqlite3.openInMemory();
    raw
      ..execute('''
        CREATE TABLE clothing_items (
          id TEXT NOT NULL PRIMARY KEY,
          category_id TEXT NOT NULL,
          image_path TEXT,
          type TEXT NOT NULL DEFAULT '',
          style TEXT NOT NULL DEFAULT '',
          color TEXT NOT NULL DEFAULT '',
          season TEXT NOT NULL DEFAULT '',
          fabric TEXT NOT NULL DEFAULT '',
          brand TEXT NOT NULL DEFAULT '',
          price REAL,
          measurements TEXT NOT NULL DEFAULT '{}',
          purchased_at INTEGER,
          purchase_info TEXT NOT NULL DEFAULT '',
          location TEXT NOT NULL DEFAULT '',
          tags TEXT NOT NULL DEFAULT '',
          note TEXT NOT NULL DEFAULT '',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''')
      ..execute('''
        CREATE TABLE outfits (
          id TEXT NOT NULL PRIMARY KEY,
          category_id TEXT NOT NULL,
          image_path TEXT,
          name TEXT NOT NULL DEFAULT '',
          season TEXT NOT NULL DEFAULT '',
          note TEXT NOT NULL DEFAULT '',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''')
      ..execute('PRAGMA user_version = 4');

    final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
    addTearDown(db.close);

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 9);

    final columns = await db
        .customSelect('PRAGMA table_info(clothing_item_images)')
        .get();
    final names = columns.map((row) => row.read<String>('name')).toList();
    expect(names.where((name) => name == 'ocr_json').length, 1);
    expect(
      (await db.customSelect('PRAGMA table_info(outfits)').get()).map(
        (row) => row.read<String>('name'),
      ),
      containsAll(['source_image_path', 'cover_mode', 'collage_layout']),
    );
  });

  test('a new database is created at schema 9 with category seeds', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 9);
    final categories = await db.select(db.categories).get();
    expect(categories, isNotEmpty);
  });

  test('upgrade keeps an existing ocr_json column', () async {
    final raw = sqlite3.openInMemory();
    raw
      ..execute('''
        CREATE TABLE outfits (
          id TEXT NOT NULL PRIMARY KEY,
          category_id TEXT NOT NULL,
          image_path TEXT,
          name TEXT NOT NULL DEFAULT '',
          season TEXT NOT NULL DEFAULT '',
          note TEXT NOT NULL DEFAULT '',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''')
      ..execute('''
        CREATE TABLE clothing_item_images (
          id TEXT NOT NULL PRIMARY KEY,
          item_id TEXT NOT NULL,
          sort_order INTEGER NOT NULL,
          role TEXT NOT NULL DEFAULT 'garment',
          original_path TEXT NOT NULL,
          processed_path TEXT,
          mask_path TEXT,
          color_json TEXT NOT NULL DEFAULT '',
          ocr_json TEXT NOT NULL DEFAULT '',
          is_primary INTEGER NOT NULL DEFAULT 0
        )
      ''')
      ..execute('PRAGMA user_version = 5');

    final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
    addTearDown(db.close);

    final columns = await db
        .customSelect('PRAGMA table_info(clothing_item_images)')
        .get();
    expect(
      columns
          .map((row) => row.read<String>('name'))
          .where((name) => name == 'ocr_json'),
      ['ocr_json'],
    );
  });

  test('upgrade keeps outfit links, day outfits, and image paths', () async {
    final raw = sqlite3.openInMemory();
    raw
      ..execute('''
        CREATE TABLE clothing_items (
          id TEXT NOT NULL PRIMARY KEY,
          category_id TEXT NOT NULL,
          image_path TEXT,
          type TEXT NOT NULL DEFAULT '',
          style TEXT NOT NULL DEFAULT '',
          color TEXT NOT NULL DEFAULT '',
          season TEXT NOT NULL DEFAULT '',
          fabric TEXT NOT NULL DEFAULT '',
          brand TEXT NOT NULL DEFAULT '',
          price REAL,
          measurements TEXT NOT NULL DEFAULT '{}',
          purchased_at INTEGER,
          purchase_info TEXT NOT NULL DEFAULT '',
          location TEXT NOT NULL DEFAULT '',
          tags TEXT NOT NULL DEFAULT '',
          note TEXT NOT NULL DEFAULT '',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''')
      ..execute('''
        CREATE TABLE outfits (
          id TEXT NOT NULL PRIMARY KEY,
          category_id TEXT NOT NULL,
          image_path TEXT,
          source_image_path TEXT,
          name TEXT NOT NULL DEFAULT '',
          season TEXT NOT NULL DEFAULT '',
          note TEXT NOT NULL DEFAULT '',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''')
      ..execute('''
        CREATE TABLE outfit_items (
          outfit_id TEXT NOT NULL,
          clothing_item_id TEXT NOT NULL,
          sort_order INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (outfit_id, clothing_item_id)
        )
      ''')
      ..execute('''
        CREATE TABLE day_outfits (
          day TEXT NOT NULL,
          outfit_id TEXT NOT NULL,
          sort_order INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (day, outfit_id)
        )
      ''')
      ..execute(
        "INSERT INTO clothing_items (id, category_id, image_path, created_at, updated_at) "
        "VALUES ('cloth', 'tops', 'C:/photos/shirt.jpg', 1, 1)",
      )
      ..execute(
        "INSERT INTO outfit_items (outfit_id, clothing_item_id) VALUES ('look', 'cloth')",
      )
      ..execute(
        "INSERT INTO day_outfits (day, outfit_id) VALUES ('2026-09-23', 'look')",
      )
      ..execute('PRAGMA user_version = 8');

    final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
    addTearDown(db.close);

    final item = await db
        .customSelect(
          'SELECT image_path FROM clothing_items WHERE id = ?',
          variables: [Variable<String>('cloth')],
        )
        .getSingle();
    expect(item.read<String>('image_path'), 'C:/photos/shirt.jpg');

    final links = await db.select(db.outfitItems).get();
    expect(links.single.clothingItemId, 'cloth');
    final days = await db.select(db.dayOutfits).get();
    expect(days.single.day, '2026-09-23');
  });

  test('adding cover columns is skipped when they already exist', () async {
    final raw = sqlite3.openInMemory();
    raw
      ..execute('''
        CREATE TABLE outfits (
          id TEXT NOT NULL PRIMARY KEY,
          category_id TEXT NOT NULL,
          image_path TEXT,
          source_image_path TEXT,
          cover_mode TEXT NOT NULL DEFAULT 'photo',
          collage_layout TEXT,
          name TEXT NOT NULL DEFAULT '',
          season TEXT NOT NULL DEFAULT '',
          note TEXT NOT NULL DEFAULT '',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''')
      ..execute('PRAGMA user_version = 8');

    final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
    addTearDown(db.close);
    final names = (await db.customSelect('PRAGMA table_info(outfits)').get())
        .map((row) => row.read<String>('name'));
    expect(names.where((name) => name == 'cover_mode'), ['cover_mode']);
  });
}
