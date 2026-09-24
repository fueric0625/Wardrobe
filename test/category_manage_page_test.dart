import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/app/providers.dart';
import 'package:wardrobe/core/catalog/catalogs.dart';
import 'package:wardrobe/core/catalog/category_manage_page.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/design_system/app_appearance.dart';
import 'package:wardrobe/core/design_system/theme.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'adding a subcategory keeps the name field alive while it closes',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: buildAppTheme(AppAppearance.fallback),
            home: const CategoryManagePage(kind: CategoryKind.clothing),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('添加子分类').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '测试子类');
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      expect(find.text('测试子类'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
