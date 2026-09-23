class OutfitDraft {
  const OutfitDraft({
    required this.categoryId,
    required this.clothingIds,
    required this.coverMode,
    required this.name,
    required this.season,
    required this.note,
    this.displayPath,
    this.sourcePath,
    this.collageLayout,
    this.createdAt,
  });

  final String categoryId;
  final List<String> clothingIds;
  final String? displayPath;
  final String? sourcePath;
  final String coverMode;
  final String? collageLayout;
  final String name;
  final String season;
  final String note;
  final DateTime? createdAt;
}
