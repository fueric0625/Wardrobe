import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

Future<String?> pickImagePath() async {
  final fileBuffer = wsalloc(MAX_PATH);
  final filter = _doubleNullTerminated(['图片', '*.jpg;*.jpeg;*.png;*.webp;*.gif;*.bmp']);
  final title = wsalloc(32)..setString('选择图片');
  final ofn = calloc<OPENFILENAME>();

  try {
    ofn.ref
      ..lStructSize = sizeOf<OPENFILENAME>()
      ..lpstrFile = fileBuffer
      ..nMaxFile = MAX_PATH
      ..lpstrFilter = filter
      ..nFilterIndex = 1
      ..lpstrTitle = title
      ..Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_EXPLORER | OFN_HIDEREADONLY;

    if (GetOpenFileName(ofn)) {
      return fileBuffer.toDartString();
    }
    return null;
  } finally {
    calloc.free(ofn);
    free(fileBuffer);
    free(filter);
    free(title);
  }
}

PWSTR _doubleNullTerminated(List<String> pairs) {
  final units = <int>[];
  for (final part in pairs) {
    units.addAll(part.codeUnits);
    units.add(0);
  }
  units.add(0);
  final buffer = wsalloc(units.length);
  buffer.cast<Uint16>().asTypedList(units.length).setAll(0, units);
  return buffer;
}
