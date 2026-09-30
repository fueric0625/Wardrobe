import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wardrobe/app/app.dart';
import 'package:wardrobe/app/providers.dart';
import 'package:wardrobe/core/design_system/app_appearance.dart';
import 'package:wardrobe/core/list_sort_store.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/storage/app_paths.dart';
import 'package:wardrobe/core/storage/image_store.dart';
import 'package:wardrobe/core/storage/wardrobe_backup.dart';
import 'package:wardrobe/features/wardrobe/detail_layout_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final support = await AppPaths.ensureSupportDirectory();
  try {
    await applyPendingWardrobeImport(support);
  } catch (_) {}

  final database = AppDatabase();
  final images = ImageStore();
  await images.init();
  await images.deleteUnreferenced(await database.referencedImagePaths());
  unawaited(deleteAbandonedRollbacks(support));
  final appearance = await AppAppearanceStore.read();
  final detailLayout = await DetailLayoutStore.read();
  final listSort = await ListSortStore.read();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) => database),
        imageStoreProvider.overrideWith((ref) => images),
        appAppearanceSeedProvider.overrideWith((ref) => appearance),
        detailLayoutSeedProvider.overrideWith((ref) => detailLayout),
        rememberedListSortSeedProvider.overrideWith((ref) => listSort),
      ],
      child: const WardrobeApp(),
    ),
  );
}
