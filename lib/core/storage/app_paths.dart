import 'dart:io';

import 'package:path/path.dart' as p;

class AppPaths {
  static Directory supportDirectory() {
    final appData = Platform.environment['APPDATA'];
    if (appData == null || appData.isEmpty) {
      throw StateError('APPDATA is not set');
    }
    return Directory(p.join(appData, 'wardrobe'));
  }

  static Directory tempDirectory() => Directory.systemTemp;

  static Future<Directory> ensureSupportDirectory() async {
    final dir = supportDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
