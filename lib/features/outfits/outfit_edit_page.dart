import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import 'package:wardrobe/app/providers.dart';
import 'package:wardrobe/core/catalog/catalogs.dart';
import 'package:wardrobe/core/catalog/category_tree.dart';
import 'package:wardrobe/core/catalog/providers.dart';
import 'package:wardrobe/core/db/app_database.dart';
import 'package:wardrobe/core/storage/image_picker.dart';
import 'package:wardrobe/core/storage/image_store.dart';
import 'package:wardrobe/core/theme.dart';
import 'package:wardrobe/core/vision/cutout/background_blur.dart';
import 'package:wardrobe/core/vision/providers.dart';
import 'package:wardrobe/features/outfits/outfit_clothes_picker.dart';
import 'package:wardrobe/features/outfits/outfit_collage_board.dart';
import 'package:wardrobe/features/outfits/providers.dart';
import 'package:wardrobe/widgets/common.dart';
import 'package:wardrobe/widgets/piece_collage.dart';

enum OutfitPhotoMode { original, cutout, blur }

class OutfitEditPage extends ConsumerStatefulWidget {
  const OutfitEditPage({super.key, this.outfitId, this.categoryId});

  final String? outfitId;
  final String? categoryId;

  @override
  ConsumerState<OutfitEditPage> createState() => _OutfitEditPageState();
}

class _OutfitEditPageState extends ConsumerState<OutfitEditPage> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  String _categoryId = 'uncategorized';
  String? _sourcePath;
  String? _displayPath;
  String? _loadedSource;
  String? _loadedDisplay;
  OutfitPhotoMode _mode = OutfitPhotoMode.original;
  String? _photoError;
  bool _photoBusy = false;
  int _step = 0;
  String? _rootId;
  String? _filterId;
  final List<String> _clothingIds = [];
  String _coverMode = outfitCoverPhoto;
  List<CollagePlacement> _placements = [];
  bool _collageRemoved = false;
  final Set<String> _createdPaths = {};
  DateTime? _createdAt;
  final Set<String> _seasons = {};
  bool _loaded = false;
  bool _saving = false;
  bool _saved = false;
  ImageStore? _images;

  bool get _isEditing => widget.outfitId != null;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.categoryId ?? 'uncategorized';
    if (_isEditing) {
      _step = 2;
      _load();
    } else {
      _loaded = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _images = ref.read(imageStoreProvider);
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    if (!_saved) {
      final images = _images;
      if (images != null) {
        for (final path in _createdPaths) {
          if (path == _loadedSource || path == _loadedDisplay) continue;
          images.deleteIfOwned(path);
        }
      }
    }
    super.dispose();
  }

  Future<void> _load() async {
    final item = await ref.read(outfitRepositoryProvider).getById(widget.outfitId!);
    if (!mounted) return;
    if (item == null) {
      context.go('/outfits');
      return;
    }
    final ids = await ref
        .read(outfitRepositoryProvider)
        .watchClothingItemIds(item.id)
        .first;
    if (!mounted) return;
    _name.text = item.name;
    _note.text = item.note;
    _categoryId = item.categoryId;
    _displayPath = item.imagePath;
    _sourcePath = item.sourceImagePath ?? item.imagePath;
    _loadedDisplay = _displayPath;
    _loadedSource = _sourcePath;
    _mode = _modeOf(_sourcePath, _displayPath);
    _coverMode = item.coverMode;
    _collageRemoved = isCollageRemoved(item.collageLayout);
    _placements = _collageRemoved ? [] : decodeCollageLayout(item.collageLayout);
    _createdAt = item.createdAt;
    _clothingIds
      ..clear()
      ..addAll(ids);
    _seasons
      ..clear()
      ..addAll(item.season.split(RegExp(r'[,，\s]+')).where((s) => s.isNotEmpty));
    setState(() => _loaded = true);
  }

  OutfitPhotoMode _modeOf(String? source, String? display) {
    if (display == null || source == null || display == source) {
      return OutfitPhotoMode.original;
    }
    if (display.toLowerCase().endsWith('.png')) return OutfitPhotoMode.cutout;
    return OutfitPhotoMode.blur;
  }

  Future<void> _pickImage() async {
    final path = await pickImagePath();
    if (path == null || !mounted) return;
    setState(() {
      _photoBusy = true;
      _photoError = null;
    });
    try {
      final bytes = await File(path).readAsBytes();
      final ingested = await ref.read(garmentPipelineProvider).ingestBytes(bytes);
      final stored = await ref.read(imageStoreProvider).writeBytes(
            ingested.originalBytes,
            '.jpg',
          );
      final previous = _sourcePath;
      _createdPaths.add(stored);
      if (!mounted) return;
      setState(() {
        _sourcePath = stored;
        _displayPath = stored;
        _mode = OutfitPhotoMode.original;
        _photoBusy = false;
      });
      await _forget(previous);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _photoBusy = false;
        _photoError = '这张图片无法使用';
      });
    }
  }

  Future<void> _applyMode(OutfitPhotoMode mode) async {
    final source = _sourcePath;
    if (source == null || _photoBusy) return;
    if (mode == _mode && _displayPath != null) return;
    setState(() {
      _photoBusy = true;
      _photoError = null;
    });
    try {
      if (mode == OutfitPhotoMode.original) {
        final previous = _displayPath;
        if (!mounted) return;
        setState(() {
          _displayPath = source;
          _mode = mode;
          _photoBusy = false;
        });
        await _forget(previous);
        return;
      }
      final bytes = await File(source).readAsBytes();
      final result = await ref.read(garmentPipelineProvider).processBytes(bytes);
      if (!mounted) return;
      final maskBytes = result.maskPng;
      if (maskBytes == null || result.error != null) {
        setState(() {
          _displayPath = source;
          _mode = OutfitPhotoMode.original;
          _photoError = result.error ?? '抠图失败，已保留原图';
          _photoBusy = false;
        });
        return;
      }
      final images = ref.read(imageStoreProvider);
      final String stored;
      if (mode == OutfitPhotoMode.cutout) {
        final png = result.fullCutoutPng;
        if (png == null) {
          setState(() {
            _displayPath = source;
            _mode = OutfitPhotoMode.original;
            _photoError = '抠图失败，已保留原图';
            _photoBusy = false;
          });
          return;
        }
        stored = await images.writeBytes(png, '.png');
      } else {
        final rgb = img.decodeImage(result.originalBytes);
        final mask = img.decodeImage(maskBytes);
        if (rgb == null || mask == null) {
          setState(() {
            _displayPath = source;
            _mode = OutfitPhotoMode.original;
            _photoError = '抠图失败，已保留原图';
            _photoBusy = false;
          });
          return;
        }
        final blurred = blurBackground(rgb, mask);
        stored = await images.writeBytes(
          Uint8List.fromList(img.encodeJpg(blurred, quality: 90)),
          '.jpg',
        );
      }
      final previous = _displayPath;
      _createdPaths.add(stored);
      if (!mounted) return;
      setState(() {
        _displayPath = stored;
        _mode = mode;
        _photoBusy = false;
      });
      await _forget(previous);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _displayPath = _sourcePath;
        _mode = OutfitPhotoMode.original;
        _photoError = '处理失败，已保留原图';
        _photoBusy = false;
      });
    }
  }

  Future<void> _forget(String? path) async {
    if (path == null) return;
    if (path == _sourcePath || path == _displayPath) return;
    if (path == _loadedSource || path == _loadedDisplay) return;
    if (!_createdPaths.remove(path)) return;
    await _images?.deleteIfOwned(path);
  }

  Future<void> _clearPhoto() async {
    final source = _sourcePath;
    final display = _displayPath;
    setState(() {
      _sourcePath = null;
      _displayPath = null;
      _mode = OutfitPhotoMode.original;
      _photoError = null;
    });
    await _forget(source);
    await _forget(display);
  }

  void _toggleClothing(String id) {
    setState(() {
      if (_clothingIds.contains(id)) {
        _clothingIds.remove(id);
      } else {
        _clothingIds.add(id);
      }
    });
  }

  Map<String, String> _clothingImages() => ref.read(clothingCutoutsProvider);

  ({Map<String, String> images, List<CollagePlacement> placements}) _watchedCollage({
    bool honorRemoval = false,
  }) {
    final images = ref.watch(clothingCutoutsProvider);
    final ids = [for (final id in _clothingIds) if (images.containsKey(id)) id];
    if (honorRemoval && _collageRemoved) {
      return (images: images, placements: const <CollagePlacement>[]);
    }
    return (images: images, placements: mergeCollageLayout(_placements, ids));
  }

  List<CollagePlacement> _effectivePlacements() {
    final images = _clothingImages();
    final ids = [for (final id in _clothingIds) if (images.containsKey(id)) id];
    return mergeCollageLayout(_placements, ids);
  }

  Future<bool> _confirmRemove(String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _deleteDetailPhoto() async {
    if (!await _confirmRemove('删除这张全身照？')) return;
    await _clearPhoto();
    if (!mounted) return;
    if (!_collageRemoved && _clothingIds.isNotEmpty) {
      setState(() => _coverMode = outfitCoverCollage);
    }
  }

  Future<void> _deleteDetailCollage() async {
    if (!await _confirmRemove('删除这张拼图？')) return;
    setState(() {
      _collageRemoved = true;
      _placements = [];
      if (_displayPath != null && _displayPath!.isNotEmpty) {
        _coverMode = outfitCoverPhoto;
      }
    });
  }

  void _openDetails() {
    setState(() {
      final hasPhoto = _displayPath != null && _displayPath!.isNotEmpty;
      if (!hasPhoto && _clothingIds.isNotEmpty) _coverMode = outfitCoverCollage;
      _step = 2;
    });
  }

  void _back() {
    if (_step == 0 && _rootId != null) {
      setState(() {
        _rootId = null;
        _filterId = null;
      });
      return;
    }
    if (_step > 0) {
      setState(() => _step -= 1);
      return;
    }
    context.pop();
  }

  Future<void> _save() async {
    if (_saving || _photoBusy) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final id = widget.outfitId ?? const Uuid().v4();
      final categories = ref.read(outfitCategoryRowsProvider);
      final selectedId = categoryById(categories, _categoryId)?.id ??
          uncategorizedClothingId;
      await ref.read(outfitRepositoryProvider).save(
            OutfitsCompanion(
              id: Value(id),
              categoryId: Value(selectedId),
              imagePath: Value(_displayPath),
              sourceImagePath: Value(_sourcePath),
              coverMode: Value(_coverMode),
              collageLayout: Value(
                _collageRemoved ? collageRemovedLayout : encodeCollageLayout(_effectivePlacements()),
              ),
              name: Value(_name.text.trim()),
              season: Value(_seasons.join(',')),
              note: Value(_note.text.trim()),
              createdAt: Value(_createdAt ?? now),
              updatedAt: Value(now),
            ),
            List<String>.of(_clothingIds),
          );
      final images = ref.read(imageStoreProvider);
      for (final old in {_loadedDisplay, _loadedSource}) {
        if (old == null || old == _displayPath || old == _sourcePath) continue;
        await images.deleteIfOwned(old);
      }
      for (final path in List<String>.of(_createdPaths)) {
        if (path == _displayPath || path == _sourcePath) continue;
        await images.deleteIfOwned(path);
      }
      _saved = true;
      if (mounted) context.go('/outfits/item/$id');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这套穿搭？'),
        content: const Text('删除后无法恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _saved = true;
    await ref.read(outfitRepositoryProvider).delete(widget.outfitId!);
    if (mounted) context.go('/outfits');
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 28, 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _photoBusy ? null : _back,
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                  label: const Text('返回'),
                ),
                Expanded(child: _stepTitle()),
                ..._headerActions(),
              ],
            ),
          ),
          Expanded(child: _stepBody()),
        ],
      ),
    );
  }

  void _goToStep(int step) {
    if (_photoBusy || step == _step) return;
    setState(() => _step = step);
  }

  Widget _stepTitle() {
    const labels = ['关联衣物', 'OOTD', '详情'];
    final family = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          TextButton(
            onPressed: _photoBusy ? null : () => _goToStep(i),
            style: TextButton.styleFrom(
              foregroundColor: i == _step ? AppColors.text : AppColors.textMuted,
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                fontFamily: family,
                fontSize: i == _step ? 18 : 15,
                height: 1.2,
                letterSpacing: 0,
                fontWeight: i == _step ? FontWeight.w600 : FontWeight.w400,
                color: i == _step ? AppColors.text : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _headerActions() {
    if (_step == 0) {
      return [
        TextButton(
          onPressed: () => setState(() {
            _clothingIds.clear();
            _placements = [];
            if (_displayPath != null) _coverMode = outfitCoverPhoto;
            _step = 1;
          }),
          child: const Text('跳过'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => setState(() => _step = 1),
          child: const Text('下一步'),
        ),
      ];
    }
    if (_step == 1) {
      return [
        if (_displayPath != null)
          TextButton(
            onPressed: _photoBusy
                ? null
                : () async {
                    await _clearPhoto();
                    if (mounted) _openDetails();
                  },
            child: const Text('跳过'),
          ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _photoBusy ? null : _openDetails,
          child: const Text('下一步'),
        ),
      ];
    }
    return [
      if (_isEditing)
        TextButton(
          onPressed: _saving ? null : _delete,
          child: const Text('删除', style: TextStyle(color: Colors.redAccent)),
        ),
      const SizedBox(width: 8),
      FilledButton(
        onPressed: _saving || _photoBusy ? null : _save,
        child: Text(_saving ? '保存中' : '确定'),
      ),
    ];
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return OutfitClothesPicker(
          selectedIds: _clothingIds,
          onToggle: _toggleClothing,
          rootId: _rootId,
          filterId: _filterId,
          onOpenRoot: (id) => setState(() {
            _rootId = id;
            _filterId = null;
          }),
          onBackToRoots: () => setState(() {
            _rootId = null;
            _filterId = null;
          }),
          onFilter: (id) => setState(() => _filterId = id),
        );
      case 1:
        return _photoStep();
      default:
        return _detailStep();
    }
  }

  Widget _photoStep() {
    final path = _displayPath;
    final cutout = path != null && path.toLowerCase().endsWith('.png');
    final collage = _watchedCollage();
    final hasPhoto = path != null && path.isNotEmpty;
    final canCollage = collage.placements.isNotEmpty;
    final useCollage = outfitUsesCollage(
      imagePath: path,
      coverMode: _coverMode,
      hasPieces: canCollage,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (hasPhoto)
                      ChoiceChip(
                        label: const Text('全身照'),
                        selected: !useCollage,
                        selectedColor: AppColors.primarySoft,
                        onSelected: (_) => setState(() => _coverMode = outfitCoverPhoto),
                      )
                    else
                      const Text('全身照，可以跳过', style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(child: _photoPanel(path, cutout, selected: hasPhoto && !useCollage)),
                if (path != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final mode in OutfitPhotoMode.values)
                        ChoiceChip(
                          label: Text(_modeLabel(mode)),
                          selected: _mode == mode,
                          selectedColor: AppColors.primarySoft,
                          onSelected: _photoBusy ? null : (_) => _applyMode(mode),
                        ),
                    ],
                  ),
                ],
                if (_photoError != null) ...[
                  const SizedBox(height: 8),
                  Text(_photoError!, style: const TextStyle(color: Colors.redAccent)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(child: _collagePanel(collage, selected: useCollage)),
        ],
      ),
    );
  }

  Widget _photoPanel(String? path, bool cutout, {required bool selected}) {
    final frame = _coverFrame(selected: selected);
    if (path == null) {
      return Material(
        color: AppColors.surface,
        shape: frame,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _photoBusy ? null : _pickImage,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.primary),
              SizedBox(height: 12),
              Text('点击选择全身照', style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }
    return Material(
      color: AppColors.surface,
      shape: frame,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          LocalCover(path: path, fit: BoxFit.contain, checkerboard: cutout),
          Positioned(
            right: 12,
            bottom: 12,
            child: ActionChip(
              label: const Text('更换图片'),
              onPressed: _photoBusy ? null : _pickImage,
            ),
          ),
          if (_photoBusy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66FFFFFF),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _collagePanel(
    ({Map<String, String> images, List<CollagePlacement> placements}) collage, {
    required bool selected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (collage.placements.isNotEmpty)
              ChoiceChip(
                label: const Text('拼图'),
                selected: selected,
                selectedColor: AppColors.primarySoft,
                onSelected: (_) => setState(() => _coverMode = outfitCoverCollage),
              )
            else
              const Text('拼图', style: TextStyle(color: AppColors.textMuted)),
            if (collage.placements.isNotEmpty) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() {
                  _placements = autoPlacements(
                    [for (final id in _clothingIds) if (collage.images.containsKey(id)) id],
                  );
                  _collageRemoved = false;
                  _coverMode = outfitCoverCollage;
                }),
                child: const Text('重新排列'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: CollageCoverBox(
            child: Material(
              color: AppColors.surface,
              shape: _coverFrame(selected: selected),
              clipBehavior: Clip.antiAlias,
              child: collage.placements.isEmpty
                  ? const Center(
                      child: Text('先关联有抠图的衣物', style: TextStyle(color: AppColors.textMuted)),
                    )
                  : OutfitCollageBoard(
                      placements: collage.placements,
                      paths: collage.images,
                    onChanged: (next) => setState(() {
                      _placements = next;
                      _collageRemoved = false;
                      _coverMode = outfitCoverCollage;
                    }),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '拖动抠图摆放，滚轮调整大小',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  RoundedRectangleBorder _coverFrame({required bool selected}) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
        width: selected ? 2 : 1,
      ),
    );
  }

  String _modeLabel(OutfitPhotoMode mode) {
    switch (mode) {
      case OutfitPhotoMode.original:
        return '原图';
      case OutfitPhotoMode.cutout:
        return '抠出人物';
      case OutfitPhotoMode.blur:
        return '背景模糊';
    }
  }

  Widget _detailStep() {
    final categories = ref.watch(outfitCategoryRowsProvider);
    final selectedId = categoryById(categories, _categoryId)?.id ??
        (categories.isEmpty ? _categoryId : uncategorizedClothingId);
    final collage = _watchedCollage(honorRemoval: true);
    final hasPhoto = _displayPath != null && _displayPath!.isNotEmpty;
    final showCollage = collage.placements.isNotEmpty;
    final cutout = hasPhoto && _displayPath!.toLowerCase().endsWith('.png');
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            SizedBox(
              width: 280,
              child: SingleChildScrollView(
              child: Column(
                children: [
                  if (!hasPhoto && !showCollage)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Text('还没有封面', style: TextStyle(color: AppColors.textMuted)),
                    ),
                  if (hasPhoto)
                    LabeledCoverCard(
                      label: '全身照',
                      onDelete: _deleteDetailPhoto,
                      child: LocalCover(
                        path: _displayPath,
                        fit: BoxFit.contain,
                        checkerboard: cutout,
                      ),
                    ),
                  if (hasPhoto && showCollage) const SizedBox(height: 16),
                  if (showCollage)
                    LabeledCoverCard(
                      label: '拼图',
                      onDelete: _deleteDetailCollage,
                      child: OutfitPieceCollage(
                        pieces: [
                          for (final placement in collage.placements)
                            if (collage.images[placement.clothingItemId] != null)
                              CollagePiece(
                                path: collage.images[placement.clothingItemId]!,
                                placement: placement,
                              ),
                        ],
                      ),
                    ),
                ],
              ),
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('分类', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 6),
                    if (categories.isEmpty)
                      const Text('暂无分类', style: TextStyle(color: AppColors.textMuted))
                    else
                      DropdownButtonFormField<String>(
                        key: ValueKey(selectedId),
                        initialValue: selectedId,
                        items: [
                          for (final c in flattenPreorder(categories))
                            DropdownMenuItem(
                              value: c.id,
                              child: Text(categoryPath(categories, c.id)),
                            ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _categoryId = v);
                        },
                      ),
                    const SizedBox(height: 12),
                    const Text('名称', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(hintText: '给这套穿搭起个名字'),
                    ),
                    const SizedBox(height: 12),
                    const Text('季节', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final season in seasons)
                          FilterChip(
                            label: Text(season),
                            selected: _seasons.contains(season),
                            selectedColor: AppColors.primarySoft,
                            checkmarkColor: AppColors.primary,
                            onSelected: (on) {
                              setState(() {
                                if (on) {
                                  _seasons.add(season);
                                } else {
                                  _seasons.remove(season);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('备注', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _note,
                      maxLines: 5,
                      decoration: const InputDecoration(hintText: '输入备注信息'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _clothingIds.isEmpty ? '未关联衣物' : '已关联 ${_clothingIds.length} 件衣物',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              ),
            ),
          ],
      ),
    );
  }
}
