import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:wardrobe/core/storage/app_paths.dart';

Future<File> materializeAssetModel({
  required String assetPath,
  required String fileName,
  int minBytes = 100000,
}) async {
  final dir = await AppPaths.ensureSupportDirectory();
  final dest = File(p.join(dir.path, 'models', fileName));
  if (await dest.exists() && await dest.length() > minBytes) {
    return dest;
  }
  final data = await rootBundle.load(assetPath);
  await dest.parent.create(recursive: true);
  await dest.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    flush: true,
  );
  return dest;
}
