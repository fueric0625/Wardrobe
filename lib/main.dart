import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wardrobe/app/app.dart';
import 'package:wardrobe/app/providers.dart';
import 'package:wardrobe/core/design_system/app_appearance.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/storage/image_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final images = ImageStore();
  await images.init();
  final appearance = await AppAppearanceStore.read();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) => database),
        imageStoreProvider.overrideWith((ref) => images),
        appAppearanceSeedProvider.overrideWith((ref) => appearance),
      ],
      child: const WardrobeApp(),
    ),
  );
}
