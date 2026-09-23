/// Save is blocked only while a photo or the previous save is still running.
String? outfitSaveBlocker({required bool saving, required bool photoBusy}) {
  if (saving || photoBusy) return 'busy';
  return null;
}
