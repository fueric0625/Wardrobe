import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wardrobe/core/db/app_database.dart';
import 'package:wardrobe/core/storage/image_store.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  throw StateError('databaseProvider must be overridden in main()');
});

final imageStoreProvider = Provider<ImageStore>((ref) {
  throw StateError('imageStoreProvider must be overridden in main()');
});
