import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/core/catalog/catalogs.dart';
import 'package:wardrobe/core/catalog/category_repository.dart';
import 'package:wardrobe/core/catalog/category_tree.dart';
import 'package:wardrobe/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  late LocalCategoryRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalCategoryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('reorder writes sibling sort order and leaves other branches', () async {
    final outer = await repo.add(kind: CategoryKind.clothing, label: '外套');
    final hoodie = await repo.add(
      kind: CategoryKind.clothing,
      parentId: outer,
      label: '卫衣',
    );
    final shirt = await repo.add(
      kind: CategoryKind.clothing,
      parentId: outer,
      label: '衬衫',
    );

    await repo.reorderSiblings(CategoryKind.clothing, outer, [shirt, hoodie]);
    final beforeRoots = childrenOf(
      await repo.get(CategoryKind.clothing),
      null,
    ).map((c) => c.id).toList();
    await repo.reorderSiblings(CategoryKind.clothing, null, [
      outer,
      ...beforeRoots.where((id) => id != outer),
    ]);

    final all = await repo.get(CategoryKind.clothing);
    expect(childrenOf(all, outer).map((c) => c.id).toList(), [shirt, hoodie]);
    expect(childrenOf(all, null).first.id, outer);
  });
}
