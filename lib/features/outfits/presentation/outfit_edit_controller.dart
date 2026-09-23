import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import 'package:wardrobe/app/providers.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/catalog/catalogs.dart';
import 'package:wardrobe/core/catalog/category_tree.dart';
import 'package:wardrobe/core/catalog/providers.dart';
import 'package:wardrobe/core/storage/image_picker.dart';
import 'package:wardrobe/core/storage/image_store.dart';
import 'package:wardrobe/core/vision/cutout/background_blur.dart';
import 'package:wardrobe/core/vision/providers.dart';
import 'package:wardrobe/features/outfits/domain/outfit_cover_policy.dart';
import 'package:wardrobe/features/outfits/domain/outfit_draft.dart';
import 'package:wardrobe/features/outfits/domain/outfit_selection_policy.dart';
import 'package:wardrobe/features/outfits/domain/outfit_validation.dart';
import 'package:wardrobe/features/outfits/providers.dart';
import 'package:wardrobe/widgets/piece_collage.dart';

enum OutfitPhotoMode { original, cutout, blur }

typedef OutfitEditKey = ({String? outfitId, String? categoryId});

class OutfitEditState {
  const OutfitEditState({
    required this.loaded,
    required this.saving,
    required this.photoBusy,
    required this.step,
    required this.categoryId,
    required this.coverMode,
    required this.clothingIds,
    required this.placements,
    required this.seasons,
    required this.collageRemoved,
    required this.mode,
    this.sourcePath,
    this.displayPath,
    this.photoError,
    this.rootId,
    this.filterId,
    this.createdAt,
    this.missing = false,
  });

  factory OutfitEditState.fresh({required String categoryId}) {
    return OutfitEditState(
      loaded: true,
      saving: false,
      photoBusy: false,
      step: 0,
      categoryId: categoryId,
      coverMode: outfitCoverPhoto,
      clothingIds: const [],
      placements: const [],
      seasons: const {},
      collageRemoved: false,
      mode: OutfitPhotoMode.original,
    );
  }

  factory OutfitEditState.editing({required String categoryId}) {
    return OutfitEditState(
      loaded: false,
      saving: false,
      photoBusy: false,
      step: 2,
      categoryId: categoryId,
      coverMode: outfitCoverPhoto,
      clothingIds: const [],
      placements: const [],
      seasons: const {},
      collageRemoved: false,
      mode: OutfitPhotoMode.original,
    );
  }

  final bool loaded;
  final bool saving;
  final bool photoBusy;
  final int step;
  final String categoryId;
  final String? sourcePath;
  final String? displayPath;
  final OutfitPhotoMode mode;
  final String? photoError;
  final String? rootId;
  final String? filterId;
  final List<String> clothingIds;
  final String coverMode;
  final List<CollagePlacement> placements;
  final bool collageRemoved;
  final Set<String> seasons;
  final DateTime? createdAt;
  final bool missing;

  OutfitEditState copyWith({
    bool? loaded,
    bool? saving,
    bool? photoBusy,
    int? step,
    String? categoryId,
    String? sourcePath,
    String? displayPath,
    bool clearPhoto = false,
    OutfitPhotoMode? mode,
    String? photoError,
    bool clearPhotoError = false,
    String? rootId,
    bool clearRoot = false,
    String? filterId,
    bool clearFilter = false,
    List<String>? clothingIds,
    String? coverMode,
    List<CollagePlacement>? placements,
    bool? collageRemoved,
    Set<String>? seasons,
    DateTime? createdAt,
    bool? missing,
  }) {
    return OutfitEditState(
      loaded: loaded ?? this.loaded,
      saving: saving ?? this.saving,
      photoBusy: photoBusy ?? this.photoBusy,
      step: step ?? this.step,
      categoryId: categoryId ?? this.categoryId,
      sourcePath: clearPhoto ? null : sourcePath ?? this.sourcePath,
      displayPath: clearPhoto ? null : displayPath ?? this.displayPath,
      mode: mode ?? this.mode,
      photoError: clearPhotoError ? null : photoError ?? this.photoError,
      rootId: clearRoot ? null : rootId ?? this.rootId,
      filterId: clearFilter ? null : filterId ?? this.filterId,
      clothingIds: clothingIds ?? this.clothingIds,
      coverMode: coverMode ?? this.coverMode,
      placements: placements ?? this.placements,
      collageRemoved: collageRemoved ?? this.collageRemoved,
      seasons: seasons ?? this.seasons,
      createdAt: createdAt ?? this.createdAt,
      missing: missing ?? this.missing,
    );
  }
}

final outfitEditControllerProvider = NotifierProvider.autoDispose
    .family<OutfitEditController, OutfitEditState, OutfitEditKey>(
      OutfitEditController.new,
    );

class OutfitEditController extends Notifier<OutfitEditState> {
  OutfitEditController(this.key);

  final OutfitEditKey key;
  final name = TextEditingController();
  final note = TextEditingController();
  final Set<String> _createdPaths = {};
  final List<ImageImport> _pending = [];
  String? _loadedSource;
  String? _loadedDisplay;
  bool _saved = false;

  bool get isEditing => key.outfitId != null;

  @override
  OutfitEditState build() {
    final images = ref.read(imageStoreProvider);
    ref.onDispose(() {
      name.dispose();
      note.dispose();
      if (_saved) return;
      final pendingTemps = {for (final op in _pending) op.tempPath};
      for (final op in _pending) {
        op.rollback();
      }
      for (final path in _createdPaths) {
        if (path == _loadedSource || path == _loadedDisplay) continue;
        if (pendingTemps.contains(path)) continue;
        images.deleteIfOwned(path);
      }
    });
    final categoryId = key.categoryId ?? 'uncategorized';
    if (isEditing) {
      Future.microtask(_load);
      return OutfitEditState.editing(categoryId: categoryId);
    }
    return OutfitEditState.fresh(categoryId: categoryId);
  }

  Future<void> _load() async {
    final item = await ref
        .read(outfitRepositoryProvider)
        .getById(key.outfitId!);
    if (!ref.mounted) return;
    if (item == null) {
      state = state.copyWith(missing: true, loaded: true);
      return;
    }
    final ids = await ref
        .read(outfitRepositoryProvider)
        .watchClothingItemIds(item.id)
        .first;
    if (!ref.mounted) return;
    name.text = item.name;
    note.text = item.note;
    final display = item.imagePath;
    final source = item.sourceImagePath ?? item.imagePath;
    _loadedDisplay = display;
    _loadedSource = source;
    final removed = isCollageRemoved(item.collageLayout);
    state = OutfitEditState(
      loaded: true,
      saving: false,
      photoBusy: false,
      step: state.step,
      categoryId: item.categoryId,
      sourcePath: source,
      displayPath: display,
      mode: _modeOf(source, display),
      coverMode: item.coverMode,
      collageRemoved: removed,
      placements: removed ? const [] : decodeCollageLayout(item.collageLayout),
      createdAt: item.createdAt,
      clothingIds: ids,
      seasons: item.season
          .split(RegExp(r'[,，\s]+'))
          .where((s) => s.isNotEmpty)
          .toSet(),
      rootId: state.rootId,
      filterId: state.filterId,
    );
  }

  OutfitPhotoMode _modeOf(String? source, String? display) {
    if (display == null || source == null || display == source) {
      return OutfitPhotoMode.original;
    }
    if (display.toLowerCase().endsWith('.png')) return OutfitPhotoMode.cutout;
    return OutfitPhotoMode.blur;
  }

  void goToStep(int step) {
    if (state.photoBusy || step == state.step) return;
    state = state.copyWith(step: step);
  }

  void back() {
    if (state.step == 0 && state.rootId != null) {
      state = state.copyWith(clearRoot: true, clearFilter: true);
      return;
    }
    if (state.step > 0) {
      state = state.copyWith(step: state.step - 1);
    }
  }

  bool get leavePage => state.step == 0 && state.rootId == null;

  void toggleClothing(String id) {
    state = state.copyWith(
      clothingIds: toggleOutfitClothing(state.clothingIds, id),
    );
  }

  void skipClothes() {
    state = state.copyWith(
      clothingIds: clearOutfitClothing(),
      placements: const [],
      coverMode: coverModeAfterChange(
        hasPhoto: state.displayPath != null && state.displayPath!.isNotEmpty,
        hasCollage: false,
        coverMode: state.coverMode,
      ),
      step: 1,
    );
  }

  void nextFromClothes() => state = state.copyWith(step: 1);

  void openRoot(String id) =>
      state = state.copyWith(rootId: id, clearFilter: true);

  void backToRoots() =>
      state = state.copyWith(clearRoot: true, clearFilter: true);

  void filterCategory(String? id) {
    if (id == null) {
      state = state.copyWith(clearFilter: true);
      return;
    }
    state = state.copyWith(filterId: id);
  }

  void selectCoverPhoto() =>
      state = state.copyWith(coverMode: outfitCoverPhoto);

  void selectCoverCollage() {
    state = state.copyWith(
      coverMode: outfitCoverCollage,
      collageRemoved: false,
    );
  }

  void rearrange() {
    final images = ref.read(clothingCutoutsProvider);
    state = state.copyWith(
      placements: autoPlacements([
        for (final id in state.clothingIds)
          if (images.containsKey(id)) id,
      ]),
      collageRemoved: false,
      coverMode: outfitCoverCollage,
    );
  }

  void setPlacements(List<CollagePlacement> next) {
    state = state.copyWith(
      placements: next,
      collageRemoved: false,
      coverMode: outfitCoverCollage,
    );
  }

  void setCategory(String id) => state = state.copyWith(categoryId: id);

  void toggleSeason(String season, {required bool on}) {
    final next = {...state.seasons};
    if (on) {
      next.add(season);
    } else {
      next.remove(season);
    }
    state = state.copyWith(seasons: next);
  }

  void openDetails() {
    final hasPhoto = state.displayPath != null && state.displayPath!.isNotEmpty;
    state = state.copyWith(
      coverMode: coverModeAfterChange(
        hasPhoto: hasPhoto,
        hasCollage: state.clothingIds.isNotEmpty && !state.collageRemoved,
        coverMode: state.coverMode,
      ),
      step: 2,
    );
  }

  ({Map<String, String> images, List<CollagePlacement> placements}) collage({
    bool honorRemoval = false,
  }) {
    final images = ref.read(clothingCutoutsProvider);
    final ids = [
      for (final id in state.clothingIds)
        if (images.containsKey(id)) id,
    ];
    if (honorRemoval && state.collageRemoved) {
      return (images: images, placements: const <CollagePlacement>[]);
    }
    return (
      images: images,
      placements: mergeCollageLayout(state.placements, ids),
    );
  }

  List<CollagePlacement> _effectivePlacements() {
    final images = ref.read(clothingCutoutsProvider);
    final ids = [
      for (final id in state.clothingIds)
        if (images.containsKey(id)) id,
    ];
    return mergeCollageLayout(state.placements, ids);
  }

  Future<void> _forget(String? path) async {
    if (path == null) return;
    if (path == state.sourcePath || path == state.displayPath) return;
    if (path == _loadedSource || path == _loadedDisplay) return;
    if (!_createdPaths.remove(path)) return;
    await ref.read(imageStoreProvider).deleteIfOwned(path);
  }

  Future<void> clearPhoto() async {
    final source = state.sourcePath;
    final display = state.displayPath;
    state = state.copyWith(
      clearPhoto: true,
      mode: OutfitPhotoMode.original,
      clearPhotoError: true,
    );
    await _forget(source);
    await _forget(display);
  }

  Future<void> skipPhoto() async {
    await clearPhoto();
    if (!ref.mounted) return;
    openDetails();
  }

  Future<void> deleteDetailPhoto() async {
    await clearPhoto();
    if (!ref.mounted) return;
    state = state.copyWith(
      coverMode: coverModeAfterChange(
        hasPhoto: false,
        hasCollage: !state.collageRemoved && state.clothingIds.isNotEmpty,
        coverMode: state.coverMode,
      ),
    );
  }

  void deleteDetailCollage() {
    state = state.copyWith(
      collageRemoved: true,
      placements: const [],
      coverMode: coverModeAfterChange(
        hasPhoto: state.displayPath != null && state.displayPath!.isNotEmpty,
        hasCollage: false,
        coverMode: state.coverMode,
      ),
    );
  }

  Future<void> pickImage() async {
    final path = await pickImagePath();
    if (path == null || !ref.mounted) return;
    state = state.copyWith(photoBusy: true, clearPhotoError: true);
    try {
      final bytes = await File(path).readAsBytes();
      final ingested = await ref
          .read(garmentPipelineProvider)
          .ingestBytes(bytes);
      await stagePhotoBytes(ingested.originalBytes);
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(photoBusy: false, photoError: '这张图片无法使用');
    }
  }

  Future<void> applyMode(OutfitPhotoMode mode) async {
    final source = state.sourcePath;
    if (source == null || state.photoBusy) return;
    if (mode == state.mode && state.displayPath != null) return;
    state = state.copyWith(photoBusy: true, clearPhotoError: true);
    try {
      if (mode == OutfitPhotoMode.original) {
        final previous = state.displayPath;
        if (!ref.mounted) return;
        state = state.copyWith(
          displayPath: source,
          mode: mode,
          photoBusy: false,
        );
        await _forget(previous);
        return;
      }
      final bytes = await File(source).readAsBytes();
      final result = await ref
          .read(garmentPipelineProvider)
          .processBytes(bytes);
      if (!ref.mounted) return;
      final maskBytes = result.maskPng;
      if (maskBytes == null || result.error != null) {
        state = state.copyWith(
          displayPath: source,
          mode: OutfitPhotoMode.original,
          photoError: result.error ?? '抠图失败，已保留原图',
          photoBusy: false,
        );
        return;
      }
      final images = ref.read(imageStoreProvider);
      final String stored;
      if (mode == OutfitPhotoMode.cutout) {
        final png = result.fullCutoutPng;
        if (png == null) {
          state = state.copyWith(
            displayPath: source,
            mode: OutfitPhotoMode.original,
            photoError: '抠图失败，已保留原图',
            photoBusy: false,
          );
          return;
        }
        final staged = await images.beginBytes(png, '.png');
        _pending.add(staged);
        stored = staged.tempPath;
      } else {
        final rgb = img.decodeImage(result.originalBytes);
        final mask = img.decodeImage(maskBytes);
        if (rgb == null || mask == null) {
          state = state.copyWith(
            displayPath: source,
            mode: OutfitPhotoMode.original,
            photoError: '抠图失败，已保留原图',
            photoBusy: false,
          );
          return;
        }
        final blurred = blurBackground(rgb, mask);
        final staged = await images.beginBytes(
          Uint8List.fromList(img.encodeJpg(blurred, quality: 90)),
          '.jpg',
        );
        _pending.add(staged);
        stored = staged.tempPath;
      }
      final previous = state.displayPath;
      _createdPaths.add(stored);
      if (!ref.mounted) return;
      state = state.copyWith(displayPath: stored, mode: mode, photoBusy: false);
      await _forget(previous);
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        displayPath: state.sourcePath,
        mode: OutfitPhotoMode.original,
        photoError: '处理失败，已保留原图',
        photoBusy: false,
      );
    }
  }

  String? _plannedPath(String? path) {
    if (path == null) return null;
    for (final op in _pending) {
      if (op.tempPath == path) return op.finalPath;
    }
    return path;
  }

  /// Returns the saved id, or null when save did not run.
  Future<String?> save() async {
    if (outfitSaveBlocker(saving: state.saving, photoBusy: state.photoBusy) !=
        null) {
      return null;
    }
    state = state.copyWith(saving: true);
    try {
      final now = DateTime.now();
      final id = key.outfitId ?? const Uuid().v4();
      final categories = ref.read(outfitCategoryRowsProvider);
      final selectedId =
          categoryById(categories, state.categoryId)?.id ??
          uncategorizedClothingId;
      final displayPath = _plannedPath(state.displayPath);
      final sourcePath = _plannedPath(state.sourcePath);
      final draft = OutfitDraft(
        categoryId: selectedId,
        clothingIds: List<String>.of(state.clothingIds),
        displayPath: displayPath,
        sourcePath: sourcePath,
        coverMode: state.coverMode,
        collageLayout: state.collageRemoved
            ? collageRemovedLayout
            : encodeCollageLayout(_effectivePlacements()),
        name: name.text.trim(),
        season: state.seasons.join(','),
        note: note.text.trim(),
        createdAt: state.createdAt ?? now,
      );
      await ref
          .read(outfitRepositoryProvider)
          .save(
            OutfitsCompanion(
              id: Value(id),
              categoryId: Value(draft.categoryId),
              imagePath: Value(draft.displayPath),
              sourceImagePath: Value(draft.sourcePath),
              coverMode: Value(draft.coverMode),
              collageLayout: Value(draft.collageLayout),
              name: Value(draft.name),
              season: Value(draft.season),
              note: Value(draft.note),
              createdAt: Value(draft.createdAt!),
              updatedAt: Value(now),
            ),
            draft.clothingIds,
          );
      try {
        for (final op in _pending) {
          if (op.tempPath != state.displayPath &&
              op.tempPath != state.sourcePath) {
            continue;
          }
          await op.commit();
        }
      } catch (error) {
        await ref
            .read(outfitRepositoryProvider)
            .save(
              OutfitsCompanion(
                id: Value(id),
                categoryId: Value(draft.categoryId),
                imagePath: Value(state.displayPath),
                sourceImagePath: Value(state.sourcePath),
                coverMode: Value(draft.coverMode),
                collageLayout: Value(draft.collageLayout),
                name: Value(draft.name),
                season: Value(draft.season),
                note: Value(draft.note),
                createdAt: Value(draft.createdAt!),
                updatedAt: Value(now),
              ),
              draft.clothingIds,
            );
        rethrow;
      }
      final images = ref.read(imageStoreProvider);
      for (final old in {_loadedDisplay, _loadedSource}) {
        if (old == null ||
            old == state.displayPath ||
            old == state.sourcePath) {
          continue;
        }
        await images.deleteIfOwned(old);
      }
      for (final path in List<String>.of(_createdPaths)) {
        if (path == state.displayPath || path == state.sourcePath) continue;
        await images.deleteIfOwned(path);
      }
      _saved = true;
      return id;
    } finally {
      if (ref.mounted) state = state.copyWith(saving: false);
    }
  }

  /// Stages a new photo without committing it. [delete] rolls this back when
  /// the outfit row is removed.
  Future<void> stagePhotoBytes(
    Uint8List bytes, {
    String extension = '.jpg',
  }) async {
    final staged = await ref
        .read(imageStoreProvider)
        .beginBytes(bytes, extension);
    _pending.add(staged);
    final previous = state.sourcePath;
    _createdPaths.add(staged.tempPath);
    if (!ref.mounted) return;
    state = state.copyWith(
      sourcePath: staged.tempPath,
      displayPath: staged.tempPath,
      mode: OutfitPhotoMode.original,
      photoBusy: false,
    );
    await _forget(previous);
  }

  Future<void> delete() async {
    final id = key.outfitId;
    if (id == null) return;
    await ref.read(outfitRepositoryProvider).delete(id);
    for (final op in _pending) {
      await op.rollback();
    }
    _saved = true;
  }
}

String outfitPhotoModeLabel(OutfitPhotoMode mode) {
  switch (mode) {
    case OutfitPhotoMode.original:
      return '原图';
    case OutfitPhotoMode.cutout:
      return '抠出人物';
    case OutfitPhotoMode.blur:
      return '背景模糊';
  }
}
