const outfitCoverPhoto = 'photo';
const outfitCoverCollage = 'collage';

/// Which cover remains after a photo or collage is added or removed.
///
/// When both exist, [coverMode] wins. When only one remains, that one is used.
/// When neither remains, [coverMode] is left unchanged.
String coverModeAfterChange({
  required bool hasPhoto,
  required bool hasCollage,
  required String coverMode,
}) {
  if (hasPhoto && hasCollage) {
    return coverMode == outfitCoverCollage
        ? outfitCoverCollage
        : outfitCoverPhoto;
  }
  if (hasPhoto) return outfitCoverPhoto;
  if (hasCollage) return outfitCoverCollage;
  return coverMode;
}

bool outfitUsesCollage({
  required String? imagePath,
  required String coverMode,
  required bool hasPieces,
}) {
  final hasPhoto = imagePath != null && imagePath.isNotEmpty;
  if (!hasPieces) return false;
  return coverModeAfterChange(
        hasPhoto: hasPhoto,
        hasCollage: true,
        coverMode: coverMode,
      ) ==
      outfitCoverCollage;
}
