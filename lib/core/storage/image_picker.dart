import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

Future<String?> pickImagePath() async {
  final paths = await pickImagePaths(allowMultiple: false);
  return paths.isEmpty ? null : paths.first;
}

Future<List<String>> pickImagePaths({bool allowMultiple = true}) async {
  const nMaxFile = 32768;
  final fileBuffer = wsalloc(nMaxFile);
  final filter = _doubleNullTerminated(['图片', '*.jpg;*.jpeg;*.png;*.webp;*.gif;*.bmp']);
  final title = wsalloc(32)..setString(allowMultiple ? '选择图片（可多选）' : '选择图片');
  final ofn = calloc<OPENFILENAME>();

  try {
    var flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_EXPLORER | OFN_HIDEREADONLY;
    if (allowMultiple) {
      flags |= OFN_ALLOWMULTISELECT;
    }

    ofn.ref
      ..lStructSize = sizeOf<OPENFILENAME>()
      ..lpstrFile = fileBuffer
      ..nMaxFile = nMaxFile
      ..lpstrFilter = filter
      ..nFilterIndex = 1
      ..lpstrTitle = title
      ..Flags = flags;

    if (!GetOpenFileName(ofn)) {
      return const [];
    }
    return parseWindowsMultiSelect(fileBuffer.cast<Uint16>().asTypedList(nMaxFile));
  } finally {
    calloc.free(ofn);
    free(fileBuffer);
    free(filter);
    free(title);
  }
}

/// Parses the Win32 `OFN_ALLOWMULTISELECT` buffer.
/// Single select: one full path. Multi: directory then file names.
List<String> parseWindowsMultiSelect(Uint16List units) {
  final parts = <String>[];
  var start = 0;
  for (var i = 0; i < units.length; i++) {
    if (units[i] != 0) continue;
    if (i == start) break;
    parts.add(String.fromCharCodes(units.sublist(start, i)));
    start = i + 1;
  }
  if (parts.isEmpty) return const [];
  if (parts.length == 1) return parts;
  final dir = parts.first;
  final sep = dir.contains('/') ? '/' : '\\';
  final prefix = dir.endsWith(sep) ? dir : '$dir$sep';
  return [for (final name in parts.skip(1)) '$prefix$name'];
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
