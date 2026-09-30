import 'package:win32/win32.dart';

/// Returns the chosen folder, or null if the user cancels.
Future<String?> pickFolder({required String title}) async {
  final dialog = createInstance<IFileOpenDialog>(FileOpenDialog);
  final titlePtr = title.toPcwstr();
  try {
    final options = dialog.getOptions();
    dialog.setOptions(
      options | FOS_PICKFOLDERS | FOS_FORCEFILESYSTEM | FOS_PATHMUSTEXIST,
    );
    dialog.setTitle(titlePtr);
    try {
      dialog.show(null);
    } on WindowsException catch (error) {
      if (error.hr == 0x800704C7) return null;
      rethrow;
    }
    final item = dialog.getResult();
    if (item == null) return null;
    final name = item.getDisplayName(SIGDN_FILESYSPATH);
    try {
      return name.toDartString();
    } finally {
      CoTaskMemFree(name.cast());
      item.release();
    }
  } finally {
    free(titlePtr);
    dialog.release();
  }
}

void openFolder(String path) {
  final operation = 'open'.toPcwstr();
  final target = path.toPcwstr();
  try {
    ShellExecute(null, operation, target, null, null, SW_SHOWNORMAL);
  } finally {
    free(operation);
    free(target);
  }
}
