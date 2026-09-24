import 'dart:io';

import 'package:wardrobe/core/storage/image_picker.dart';
import 'package:wardrobe/core/storage/image_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:wardrobe/app/providers.dart';
import 'package:wardrobe/core/catalog/providers.dart';
import 'package:wardrobe/core/vision/providers.dart';
import 'package:wardrobe/features/wardrobe/providers.dart';
import 'package:wardrobe/core/catalog/catalogs.dart';
import 'package:wardrobe/core/catalog/category_tree.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/design_system/theme.dart';
import 'package:wardrobe/core/vision/coordinates/image_edit_session.dart';
import 'package:wardrobe/features/wardrobe/domain/item_photo_policy.dart';
import 'package:wardrobe/features/wardrobe/item_edit_controller.dart';
import 'package:wardrobe/core/vision/cutout/color_extract.dart';
import 'package:wardrobe/core/vision/cutout/erase_brush.dart';
import 'package:wardrobe/core/vision/cutout/fill_patch.dart';
import 'package:wardrobe/core/vision/cutout/garment_pipeline.dart';
import 'package:wardrobe/core/vision/cutout/sam_click.dart';
import 'package:wardrobe/features/wardrobe/photo_role.dart';
import 'package:wardrobe/core/vision/ocr/tag_ocr.dart';
import 'package:wardrobe/features/wardrobe/category_cascade.dart';
import 'package:wardrobe/features/wardrobe/item_photos.dart';
import 'package:image/image.dart' as img;

class ItemEditPage extends ConsumerStatefulWidget {
  const ItemEditPage({super.key, this.itemId, this.categoryId});

  final String? itemId;
  final String? categoryId;

  @override
  ConsumerState<ItemEditPage> createState() => _ItemEditPageState();
}

class _ItemEditPageState extends ConsumerState<ItemEditPage> {
  final _type = TextEditingController();
  final _style = TextEditingController();
  final _color = TextEditingController();
  final _fabric = TextEditingController();
  final _brand = TextEditingController();
  final _price = TextEditingController();
  final _purchaseInfo = TextEditingController();
  final _location = TextEditingController();
  final _tags = TextEditingController();
  final _note = TextEditingController();
  final _measureControllers = <String, TextEditingController>{};

  String _categoryId = 'uncategorized';
  DateTime? _purchasedAt;
  DateTime? _createdAt;
  final Set<String> _seasons = {};
  bool _loaded = false;
  bool _saving = false;
  bool _saved = false;
  var _stage = _EditStage.photos;
  bool _refining = false;
  var _refineTool = RefineTool.click;
  var _eraseProtect = true;
  var _eraseRadius = 16;
  var _fillSampling = true;
  FillPatch? _fillSample;
  final _session = ImageEditSession();
  List<RgbSwatch> _refinePalette = const [];
  _RefineSnapshot? _refineBase;
  final _photos = <EditableItemPhoto>[];
  int _selectedPhoto = 0;
  final _sessionFiles = <String>{};
  late final ImageStore _imageStore;

  bool get _isEditing => widget.itemId != null;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.categoryId ?? 'uncategorized';
    _ensureMeasureControllers();
    _imageStore = ref.read(imageStoreProvider);
    _stage = _isEditing ? _EditStage.form : _EditStage.photos;
    if (_isEditing) {
      _load();
    } else {
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _type.dispose();
    _style.dispose();
    _color.dispose();
    _fabric.dispose();
    _brand.dispose();
    _price.dispose();
    _purchaseInfo.dispose();
    _location.dispose();
    _tags.dispose();
    _note.dispose();
    for (final c in _measureControllers.values) {
      c.dispose();
    }
    if (!_saved) {
      for (final path in _sessionFiles) {
        _imageStore.deleteIfOwned(path);
      }
    }
    super.dispose();
  }

  void _ensureMeasureControllers([List<Category> categories = const []]) {
    for (final field in allSizeFieldNames()) {
      _measureControllers.putIfAbsent(field, TextEditingController.new);
    }
    for (final category in categories) {
      for (final field in decodeSizeFields(category.sizeFields)) {
        _measureControllers.putIfAbsent(field, TextEditingController.new);
      }
    }
  }

  Future<void> _load() async {
    final item = await ref.read(itemRepositoryProvider).getById(widget.itemId!);
    if (!mounted) return;
    if (item == null) {
      context.go('/wardrobe');
      return;
    }
    _type.text = item.type;
    _style.text = item.style;
    _color.text = item.color;
    _fabric.text = item.fabric;
    _brand.text = item.brand;
    _price.text = item.price == null ? '' : _trimNumber(item.price!);
    _purchaseInfo.text = item.purchaseInfo;
    _location.text = item.location;
    _tags.text = item.tags;
    _note.text = item.note;
    _categoryId = item.categoryId;
    _purchasedAt = item.purchasedAt;
    _createdAt = item.createdAt;
    _seasons
      ..clear()
      ..addAll(
        item.season.split(RegExp(r'[,，\s]+')).where((s) => s.isNotEmpty),
      );
    final measures = decodeMeasurements(item.measurements);
    for (final entry in measures.entries) {
      _measureControllers
              .putIfAbsent(entry.key, TextEditingController.new)
              .text =
          entry.value;
    }
    final images = await ref.read(itemRepositoryProvider).getImages(item.id);
    _photos
      ..clear()
      ..addAll([
        if (images.isNotEmpty)
          for (final row in images) EditableItemPhoto.fromRow(row)
        else if (item.imagePath != null && item.imagePath!.isNotEmpty)
          EditableItemPhoto(
            id: const Uuid().v4(),
            originalPath: item.imagePath!,
            isPrimary: true,
          ),
      ]);
    _selectedPhoto = 0;
    setState(() => _loaded = true);
  }

  String _trimNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  Future<void> _addPhotos({bool tag = false}) async {
    final paths = await pickImagePaths();
    if (paths.isEmpty) return;
    for (var i = 0; i < paths.length; i++) {
      await _ingest(paths[i], keepBusy: i == paths.length - 1, tag: tag);
    }
    if (mounted) await _startRefine();
  }

  Future<void> _ingest(
    String path, {
    required bool keepBusy,
    bool tag = false,
  }) async {
    final hasGarment = _photos.any((p) => !p.isTag);
    final photo = EditableItemPhoto(
      id: const Uuid().v4(),
      originalPath: path,
      isPrimary: !tag && !hasGarment,
      role: tag ? ItemPhotoRole.tag : ItemPhotoRole.garment,
      busy: true,
      busyHint: '正在打开图片…',
    );
    setState(() {
      _photos.add(photo);
      _selectedPhoto = _photos.length - 1;
    });
    try {
      final bytes = await File(path).readAsBytes();
      final result = await ref.read(garmentPipelineProvider).ingestBytes(bytes);
      await _applyResult(
        photo,
        result,
        replaceOriginal: true,
        keepBusy: keepBusy,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        photo.busy = false;
        photo.busyHint = null;
        photo.error = '打开失败，可稍后重试或直接保存原图';
      });
    }
  }

  Future<void> _process(
    EditableItemPhoto photo, {
    String? readFrom,
    bool replaceOriginal = true,
  }) async {
    setState(() {
      photo.busy = true;
      photo.busyHint = null;
      photo.error = null;
    });
    try {
      final source = readFrom ?? photo.originalPath;
      final bytes = await File(source).readAsBytes();
      final result = await ref
          .read(garmentPipelineProvider)
          .processBytes(bytes);
      _session.clear();
      _fillSample = null;
      _refineBase = null;
      _refinePalette = const [];
      await _applyResult(photo, result, replaceOriginal: replaceOriginal);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        photo.busy = false;
        photo.busyHint = null;
        photo.error = '处理失败，可稍后重试或直接保存原图';
      });
    }
  }

  Future<void> _applyResult(
    EditableItemPhoto photo,
    GarmentProcessResult result, {
    required bool replaceOriginal,
    bool keepBusy = false,
  }) async {
    if (replaceOriginal) {
      final original = await _imageStore.writeBytes(
        result.originalBytes,
        result.originalExtension,
      );
      _sessionFiles.add(original);
      photo.originalPath = original;
    }
    photo.originalWidth = result.originalWidth;
    photo.originalHeight = result.originalHeight;
    String? processed;
    String? mask;
    if (result.cutoutPng != null) {
      processed = await _imageStore.writeBytes(result.cutoutPng!, '.png');
      _sessionFiles.add(processed);
    }
    if (result.maskPng != null) {
      mask = await _imageStore.writeBytes(result.maskPng!, '.png');
      _sessionFiles.add(mask);
    }
    if (result.fullCutoutPng != null) {
      final preview = await _imageStore.writeBytes(
        result.fullCutoutPng!,
        '.png',
      );
      _sessionFiles.add(preview);
      photo.refinePreviewPath = preview;
    }
    if (!mounted) return;
    setState(() {
      photo.processedPath = processed ?? photo.processedPath;
      photo.maskPath = mask ?? photo.maskPath;
      photo.colors = result.colors;
      photo.showProcessed = photo.processedPath != null;
      if (!keepBusy) {
        photo.busy = false;
        photo.busyHint = null;
      }
      photo.error = result.error;
    });
    _maybeFillColor(photo);
  }

  void _maybeFillColor(EditableItemPhoto photo) {
    if (!photoCanBeCover(photo.role) || !photo.isPrimary) return;
    final next = fillEmptyField(_color.text, photo.colors.label);
    if (next == _color.text) return;
    _color.text = next;
  }

  void _applyDetectedColor() {
    if (_photos.isEmpty) return;
    final photo = _photos[_selectedPhoto.clamp(0, _photos.length - 1)];
    final colors = photo.colors.isEmpty
        ? _photos
              .where((p) => p.isPrimary)
              .map((p) => p.colors)
              .firstWhere((c) => !c.isEmpty, orElse: () => photo.colors)
        : photo.colors;
    if (colors.isEmpty) return;
    setState(() => _color.text = colors.label);
  }

  void _removeSelectedPhoto() {
    if (_photos.isEmpty) return;
    final index = _selectedPhoto.clamp(0, _photos.length - 1);
    final photo = _photos.removeAt(index);
    if (photo.isPrimary && _photos.isNotEmpty) {
      final next = _photos.cast<EditableItemPhoto?>().firstWhere(
        (p) => p != null && !p.isTag,
        orElse: () => null,
      );
      if (next != null) next.isPrimary = true;
    }
    _selectedPhoto = _photos.isEmpty ? 0 : index.clamp(0, _photos.length - 1);
    _clearRefineSession();
    setState(() {});
  }

  void _setPrimary() {
    if (_photos.isEmpty) return;
    final index = _selectedPhoto.clamp(0, _photos.length - 1);
    if (!photoCanBeCover(_photos[index].role)) return;
    for (var i = 0; i < _photos.length; i++) {
      _photos[i].isPrimary = i == index;
    }
    _maybeFillColor(_photos[index]);
    setState(() {});
  }

  void _clearRefineSession() {
    _refining = false;
    _refineTool = RefineTool.click;
    _eraseProtect = true;
    _fillSampling = true;
    _fillSample = null;
    _session.clear();
    _refinePalette = const [];
    _refineBase = null;
  }

  Future<void> _startRefine() async {
    if (_photos.isEmpty || _refining) return;
    final photo = _photos[_selectedPhoto.clamp(0, _photos.length - 1)];
    if (photo.error != null && photo.originalWidth == null) return;
    await _ensureOriginalSize(photo);
    if (!mounted) return;
    if (photo.originalWidth == null || photo.originalHeight == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('无法读取原图尺寸')));
      return;
    }
    setState(() {
      photo.busy = true;
      photo.busyHint = '正在准备点选…';
      photo.error = null;
    });
    try {
      final originalBytes = await File(photo.originalPath).readAsBytes();
      Uint8List? maskBytes;
      if (photo.maskPath != null) {
        maskBytes = await File(photo.maskPath!).readAsBytes();
      }
      final preview = ref
          .read(garmentPipelineProvider)
          .refinePreviewPng(
            originalBytes,
            maskBytes,
            palette: photo.colors.palette,
          );
      final path = await _imageStore.writeBytes(preview, '.png');
      _sessionFiles.add(path);
      photo.refinePreviewPath = path;
      final decoded = img.decodeImage(preview);
      if (decoded != null) {
        photo.originalWidth = decoded.width;
        photo.originalHeight = decoded.height;
      }
      await ref.read(garmentPipelineProvider).prepareRefine(originalBytes);
      if (!mounted) return;
      setState(() {
        photo.busy = false;
        photo.busyHint = null;
        photo.showProcessed = true;
        photo.error = null;
        _session.clear();
        _fillSample = null;
        _refineTool = RefineTool.click;
        _eraseProtect = true;
        _fillSampling = true;
        _refinePalette = List<RgbSwatch>.of(photo.colors.palette);
        _refineBase = _RefineSnapshot(
          maskPath: photo.maskPath,
          processedPath: photo.processedPath,
          refinePreviewPath: photo.refinePreviewPath,
          colors: photo.colors,
        );
        _refining = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        photo.busy = false;
        photo.busyHint = null;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('无法分析这张图，可稍后重试')));
    }
  }

  Future<void> _ensureOriginalSize(EditableItemPhoto photo) async {
    if (photo.originalWidth != null && photo.originalHeight != null) return;
    final decoded = img.decodeImage(
      await File(photo.originalPath).readAsBytes(),
    );
    if (decoded == null) return;
    photo.originalWidth = decoded.width;
    photo.originalHeight = decoded.height;
  }

  bool get _hasClickOutline => _session.points.any((point) => point.positive);

  void _setRefineTool(RefineTool tool) {
    if (tool == RefineTool.fill &&
        _photos.isNotEmpty &&
        _photos[_selectedPhoto.clamp(0, _photos.length - 1)].isTag) {
      return;
    }
    if (tool != RefineTool.click && !_hasClickOutline) {
      final isTag =
          _photos.isNotEmpty &&
          _photos[_selectedPhoto.clamp(0, _photos.length - 1)].isTag;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isTag ? '先点选吊牌轮廓，再擦除' : '先点选衣服轮廓，再擦除或填补')),
      );
      return;
    }
    setState(() => _refineTool = tool);
  }

  void _addRefinePoint(PromptPoint point) {
    if (!_refining || _photos.isEmpty) return;
    final photo = _photos[_selectedPhoto.clamp(0, _photos.length - 1)];
    if (photo.busy) return;
    _session.addClick(point);
    _rebuildRefine();
  }

  void _addEraseStroke(List<EraseStamp> stamps) {
    if (!_refining || _photos.isEmpty || stamps.isEmpty) return;
    if (!_hasClickOutline) return;
    final photo = _photos[_selectedPhoto.clamp(0, _photos.length - 1)];
    if (photo.busy) return;
    _session.addErase(EraseStroke(stamps: stamps, protectColor: _eraseProtect));
    _rebuildRefine();
  }

  void _addFillSample(List<EraseStamp> stamps) {
    if (!_refining || stamps.isEmpty || !_hasClickOutline) return;
    if (_photos.isNotEmpty &&
        _photos[_selectedPhoto.clamp(0, _photos.length - 1)].isTag) {
      return;
    }
    setState(() {
      _fillSample = FillPatch.brush(stamps);
      _fillSampling = false;
    });
  }

  void _addFillPaint(List<EraseStamp> stamps) {
    if (!_refining || _photos.isEmpty || stamps.isEmpty) return;
    if (!_hasClickOutline) return;
    if (_photos[_selectedPhoto.clamp(0, _photos.length - 1)].isTag) return;
    final sample = _fillSample;
    if (sample == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('先涂一块花纹取样')));
      return;
    }
    final photo = _photos[_selectedPhoto.clamp(0, _photos.length - 1)];
    if (photo.busy) return;
    _session.addFill(FillStroke(sample: sample, paint: stamps));
    _rebuildRefine();
  }

  Future<void> _rebuildRefine() async {
    if (_photos.isEmpty) return;
    final photo = _photos[_selectedPhoto.clamp(0, _photos.length - 1)];
    if (_session.points.isEmpty &&
        _session.eraseStrokes.isEmpty &&
        _session.fillStrokes.isEmpty) {
      _restoreRefineBase(photo);
      return;
    }
    setState(() {
      photo.busy = true;
      photo.busyHint = '正在更新抠图…';
      photo.error = null;
    });
    try {
      final originalBytes = await File(photo.originalPath).readAsBytes();
      Uint8List? maskBytes;
      final baseMask = _refineBase?.maskPath ?? photo.maskPath;
      if (baseMask != null) {
        maskBytes = await File(baseMask).readAsBytes();
      }
      final result = await ref
          .read(garmentPipelineProvider)
          .refineEdits(
            originalBytes: originalBytes,
            maskBytes: maskBytes,
            points: List<PromptPoint>.of(_session.points),
            strokes: List<EraseStroke>.of(_session.eraseStrokes),
            fills: photo.isTag
                ? const []
                : List<FillStroke>.of(_session.fillStrokes),
            palette: _refinePalette,
          );
      await _applyResult(photo, result, replaceOriginal: false);
      if (!mounted) return;
      if (photo.isTag) {
        await _runTagOcr(photo);
      }
      if (!mounted) return;
      if (!photo.isTag &&
          _session.fillStrokes.isNotEmpty &&
          result.filledCount == 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('没有补上。先取样，再涂要改的位置')));
      }
      setState(() => _refining = true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        photo.busy = false;
        photo.busyHint = null;
        photo.error = '精修失败，可再试一次';
      });
    }
  }

  void _restoreRefineBase(EditableItemPhoto photo) {
    final snap = _refineBase;
    if (snap == null) {
      setState(() {});
      return;
    }
    setState(() {
      photo.maskPath = snap.maskPath;
      photo.processedPath = snap.processedPath;
      photo.refinePreviewPath = snap.refinePreviewPath;
      photo.colors = snap.colors;
      photo.showProcessed = true;
      photo.error = null;
      photo.busy = false;
      photo.busyHint = null;
    });
  }

  Future<void> _runTagOcr(EditableItemPhoto photo) async {
    if (!photo.isTag) return;
    setState(() {
      photo.busy = true;
      photo.busyHint = '正在识别吊牌文字…';
    });
    try {
      final path = photo.processedPath ?? photo.originalPath;
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        if (!mounted) return;
        setState(() {
          photo.busy = false;
          photo.busyHint = null;
          photo.error = '无法读取这张图';
        });
        return;
      }
      final result = await ref.read(tagOcrProvider).recognize(decoded);
      if (!mounted) return;
      setState(() {
        photo.ocr = result;
        photo.busy = false;
        photo.busyHint = null;
        if (result.isEmpty) {
          photo.error = '没有识别到文字，可再点选吊牌后重试';
        }
      });
      _maybeFillTagFields();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        photo.busy = false;
        photo.busyHint = null;
        photo.error = '识别失败，可稍后重试';
      });
    }
  }

  TagOcrResult get _mergedTagOcr {
    final lines = <String>[];
    String? brand;
    String? fabric;
    String? sizeLabel;
    final measurements = <String, String>{};
    for (final photo in _photos) {
      if (!photo.isTag || photo.ocr.isEmpty) continue;
      lines.addAll(photo.ocr.lines);
      brand ??= photo.ocr.brand;
      fabric ??= photo.ocr.fabric;
      sizeLabel ??= photo.ocr.sizeLabel;
      for (final entry in photo.ocr.measurements.entries) {
        measurements.putIfAbsent(entry.key, () => entry.value);
      }
    }
    if (lines.isEmpty && brand == null && fabric == null && sizeLabel == null) {
      return const TagOcrResult();
    }
    return TagOcrResult(
      lines: lines,
      brand: brand,
      fabric: fabric,
      sizeLabel: sizeLabel,
      measurements: measurements,
    );
  }

  void _maybeFillTagFields() {
    final ocr = _mergedTagOcr;
    if (ocr.isEmpty) return;
    final fabric = fillEmptyField(_fabric.text, ocr.fabric);
    if (fabric != _fabric.text) _fabric.text = fabric;
    final brand = fillEmptyField(_brand.text, ocr.brand);
    if (brand != _brand.text) _brand.text = brand;
    _applySizeOcr(allSizeFieldNames());
  }

  Future<void> _ocrPendingTags() async {
    for (final photo in List<EditableItemPhoto>.of(_photos)) {
      if (!photo.isTag) continue;
      if (photo.ocr.text.isNotEmpty) continue;
      await _runTagOcr(photo);
    }
  }

  void _undoRefine() {
    if (!_refining || _photos.isEmpty || _session.isEmpty) return;
    final photo = _photos[_selectedPhoto.clamp(0, _photos.length - 1)];
    if (photo.busy) return;
    _session.undo();
    _rebuildRefine();
  }

  Future<void> _cancelRefine() async {
    if (_photos.isEmpty) {
      setState(_clearRefineSession);
      return;
    }
    final photo = _photos[_selectedPhoto.clamp(0, _photos.length - 1)];
    setState(_clearRefineSession);
    if (photo.isTag && photo.ocr.isEmpty) {
      await _runTagOcr(photo);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_photos.any((p) => p.busy)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('图片还在处理，请稍候再保存')));
      return;
    }
    setState(() => _saving = true);
    try {
      final categories = ref.read(clothingCategoryRowsProvider);
      final selectedId =
          categoryById(categories, _categoryId)?.id ?? uncategorizedClothingId;
      final node = categoryById(categories, selectedId);
      final fields = node == null
          ? <String>[]
          : inheritedSizeFields(categories, node);
      final measures = <String, String>{};
      for (final field in fields) {
        final value = _measureControllers[field]?.text.trim() ?? '';
        if (value.isNotEmpty) measures[field] = value;
      }

      final now = DateTime.now();
      final id = widget.itemId ?? const Uuid().v4();
      final draft = ItemEditDraft(
        id: id,
        categoryId: selectedId,
        type: _type.text,
        style: _style.text,
        color: _color.text,
        season: _seasons.join(','),
        fabric: _fabric.text,
        brand: _brand.text,
        priceText: _price.text,
        measurements: measures,
        purchasedAt: _purchasedAt,
        purchaseInfo: _purchaseInfo.text,
        location: _location.text,
        tags: _tags.text,
        note: _note.text,
        createdAt: _createdAt,
        now: now,
      );
      await ref
          .read(itemRepositoryProvider)
          .upsert(
            draft.toCompanion(),
            images: [for (final photo in _photos) photo.toDraft()],
          );
      _saved = true;
      if (mounted) context.go('/wardrobe/item/$id');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这件衣物？'),
        content: const Text('删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(itemRepositoryProvider).delete(widget.itemId!);
    if (mounted) context.go('/wardrobe');
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchasedAt ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _purchasedAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_stage == _EditStage.photos) {
      return _buildPhotoStudio();
    }
    return _buildForm();
  }

  Widget _buildPhotoStudio() {
    final busy = _photos.any((p) => p.busy);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 28, 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: busy
                      ? null
                      : () {
                          if (_isEditing) {
                            setState(() {
                              _clearRefineSession();
                              _stage = _EditStage.form;
                            });
                          } else {
                            context.pop();
                          }
                        },
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                  label: Text(_isEditing ? '返回信息' : '返回'),
                ),
                const Expanded(
                  child: Text(
                    '处理图片',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          _clearRefineSession();
                          await _ocrPendingTags();
                          if (!mounted) return;
                          setState(() => _stage = _EditStage.form);
                        },
                  child: Text(_isEditing ? '完成' : '下一步'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: ItemPhotoStudio(
                photos: _photos,
                selectedIndex: _selectedPhoto,
                refining: _refining,
                refinePoints: _session.points,
                onSelect: (i) {
                  setState(() {
                    _selectedPhoto = i;
                    _clearRefineSession();
                    if (_photos[i].isTag && _refineTool == RefineTool.fill) {
                      _refineTool = RefineTool.click;
                    }
                  });
                  final photo = _photos[i];
                  if (photo.processedPath == null && photo.maskPath == null) {
                    _startRefine();
                  }
                },
                onAdd: () => _addPhotos(),
                onAddTag: () => _addPhotos(tag: true),
                onRemove: _removeSelectedPhoto,
                onSetPrimary: _setPrimary,
                onToggleProcessed: () {
                  if (_photos.isEmpty) return;
                  final photo =
                      _photos[_selectedPhoto.clamp(0, _photos.length - 1)];
                  setState(() => photo.showProcessed = !photo.showProcessed);
                },
                onReprocess: () {
                  if (_photos.isEmpty) return;
                  final photo =
                      _photos[_selectedPhoto.clamp(0, _photos.length - 1)];
                  _process(
                    photo,
                    readFrom: photo.originalPath,
                    replaceOriginal: false,
                  );
                },
                onStartRefine: _startRefine,
                onRecognize: () {
                  if (_photos.isEmpty) return;
                  _runTagOcr(
                    _photos[_selectedPhoto.clamp(0, _photos.length - 1)],
                  );
                },
                onCancelRefine: _cancelRefine,
                onUndoRefine: _undoRefine,
                canUndo: !_session.isEmpty,
                hasClickOutline: _hasClickOutline,
                onAddPoint: _addRefinePoint,
                onEraseStroke: _addEraseStroke,
                refineTool: _refineTool,
                eraseProtect: _eraseProtect,
                eraseRadius: _eraseRadius,
                fillSampling: _fillSampling,
                hasFillSample: _fillSample != null,
                onRefineTool: _setRefineTool,
                onEraseProtect: (v) => setState(() => _eraseProtect = v),
                onEraseRadius: (v) => setState(() => _eraseRadius = v),
                onFillSampling: (v) => setState(() => _fillSampling = v),
                onFillSample: _addFillSample,
                onFillPaint: _addFillPaint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final categories = ref.watch(clothingCategoryRowsProvider);
    _ensureMeasureControllers(categories);
    final selectedId =
        categoryById(categories, _categoryId)?.id ??
        (categories.isEmpty ? _categoryId : uncategorizedClothingId);
    final node = categoryById(categories, selectedId);
    final sizeFields = node == null
        ? <String>[]
        : inheritedSizeFields(categories, node);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 28, 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    if (_isEditing) {
                      context.pop();
                    } else {
                      setState(() => _stage = _EditStage.photos);
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                  label: Text(_isEditing ? '返回' : '返回改图'),
                ),
                const Expanded(
                  child: Text(
                    '编辑单品信息',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                if (_isEditing)
                  TextButton(
                    onPressed: _delete,
                    child: const Text(
                      '删除',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? '保存中' : '确定'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
              children: [
                ItemPhotoStrip(
                  photos: _photos,
                  onOpenStudio: () => setState(() {
                    _refining = false;
                    _stage = _EditStage.photos;
                  }),
                ),
                const SizedBox(height: 16),
                _FormCard(
                  children: [
                    CategoryCascadePicker(
                      categories: categories,
                      value: selectedId,
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                    _split(
                      _LabeledField(
                        label: '类别',
                        hint: '如衬衫、长裤',
                        controller: _type,
                      ),
                      _LabeledField(
                        label: '款式',
                        hint: '如阔腿裤、直筒裤',
                        controller: _style,
                      ),
                    ),
                    _split(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LabeledField(
                            label: '颜色',
                            hint: '手填或用识别结果',
                            controller: _color,
                          ),
                          if (_detectedColorHint != null) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '识别：$_detectedColorHint',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _applyDetectedColor,
                                  child: const Text('填入'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      _SeasonPicker(
                        selected: _seasons,
                        onChanged: (next) => setState(() {
                          _seasons
                            ..clear()
                            ..addAll(next);
                        }),
                      ),
                    ),
                    _split(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LabeledField(
                            label: '面料',
                            hint: '手填面料',
                            controller: _fabric,
                          ),
                          _ocrFillHint(
                            value: _mergedTagOcr.fabric,
                            onApply: () => setState(
                              () => _fabric.text = _mergedTagOcr.fabric ?? '',
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LabeledField(
                            label: '品牌',
                            hint: '手填品牌',
                            controller: _brand,
                          ),
                          _ocrFillHint(
                            value: _mergedTagOcr.brand,
                            onApply: () => setState(
                              () => _brand.text = _mergedTagOcr.brand ?? '',
                            ),
                          ),
                        ],
                      ),
                    ),
                    _split(
                      _LabeledField(
                        label: '价格',
                        hint: '元',
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                      ),
                      _DateRow(
                        label: '购入时间',
                        value: _purchasedAt,
                        onTap: _pickDate,
                        onClear: () => setState(() => _purchasedAt = null),
                      ),
                    ),
                    if (sizeFields.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          '尺码',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final field in sizeFields)
                            SizedBox(
                              width: 160,
                              child: _LabeledField(
                                label: field,
                                hint: field,
                                controller: _measureControllers[field]!,
                              ),
                            ),
                        ],
                      ),
                      _ocrFillHint(
                        value: _sizeOcrHint(sizeFields),
                        onApply: () => _applySizeOcr(sizeFields),
                      ),
                    ],
                    _LabeledField(
                      label: '购买信息',
                      hint: '商场专柜、淘宝、闲鱼等',
                      controller: _purchaseInfo,
                    ),
                    _LabeledField(
                      label: '存放位置',
                      hint: '输入存放位置',
                      controller: _location,
                    ),
                    _LabeledField(
                      label: '标签',
                      hint: '用逗号分隔',
                      controller: _tags,
                    ),
                    _LabeledField(
                      label: '备注',
                      hint: '输入备注信息',
                      controller: _note,
                      maxLines: 4,
                    ),
                    if (_mergedTagOcr.text.isNotEmpty ||
                        _tagPreviewPaths.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: HangtagOcrBlock(
                          text: _mergedTagOcr.text,
                          imagePaths: _tagPreviewPaths,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> get _tagPreviewPaths => [
    for (final photo in _photos)
      if (photo.isTag) photo.processedPath ?? photo.previewPath,
  ];

  String? get _detectedColorHint {
    if (_photos.isEmpty) return null;
    final selected = _photos[_selectedPhoto.clamp(0, _photos.length - 1)];
    if (!selected.isTag && !selected.colors.isEmpty) {
      return selected.colors.detail;
    }
    for (final photo in _photos) {
      if (photo.isPrimary && !photo.colors.isEmpty) return photo.colors.detail;
    }
    return null;
  }

  String? _sizeOcrHint(List<String> sizeFields) {
    final ocr = _mergedTagOcr;
    final parts = <String>[
      if (ocr.sizeLabel != null && ocr.sizeLabel!.isNotEmpty) ocr.sizeLabel!,
      for (final field in sizeFields)
        if (ocr.measurements[field] != null)
          '$field ${ocr.measurements[field]}',
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  void _applySizeOcr(List<String> sizeFields) {
    final ocr = _mergedTagOcr;
    setState(() {
      for (final field in sizeFields) {
        final value = ocr.measurements[field];
        if (value == null || value.isEmpty) continue;
        final controller = _measureControllers[field];
        if (controller != null && controller.text.trim().isEmpty) {
          controller.text = value;
        }
      }
      if (ocr.sizeLabel != null && ocr.sizeLabel!.isNotEmpty) {
        for (final field in sizeFields) {
          if (field != '尺寸') continue;
          final controller = _measureControllers[field];
          if (controller != null && controller.text.trim().isEmpty) {
            controller.text = ocr.sizeLabel!;
          }
        }
      }
    });
  }

  Widget _ocrFillHint({required String? value, required VoidCallback onApply}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '识别：$text',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          TextButton(onPressed: onApply, child: const Text('填入')),
        ],
      ),
    );
  }

  Widget _split(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

enum _EditStage { photos, form }

class _RefineSnapshot {
  const _RefineSnapshot({
    required this.maskPath,
    required this.processedPath,
    required this.refinePreviewPath,
    required this.colors,
  });

  final String? maskPath;
  final String? processedPath;
  final String? refinePreviewPath;
  final ColorAnalysis colors;
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _SeasonPicker extends StatelessWidget {
  const _SeasonPicker({required this.selected, required this.onChanged});

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '季节',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (final season in seasons)
              FilterChip(
                label: Text(season),
                selected: selected.contains(season),
                selectedColor: AppPalette.of(context).primarySoft,
                checkmarkColor: AppPalette.of(context).primary,
                onSelected: (on) {
                  final next = {...selected};
                  if (on) {
                    next.add(season);
                  } else {
                    next.remove(season);
                  }
                  onChanged(next);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null
                        ? '选择日期'
                        : DateFormat('yyyy-MM-dd').format(value!),
                    style: TextStyle(
                      color: value == null
                          ? AppColors.textMuted
                          : AppColors.text,
                    ),
                  ),
                ),
                if (value != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onClear,
                    icon: const Icon(Icons.close, size: 16),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
