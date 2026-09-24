import 'package:flutter/material.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/design_system/theme.dart';
import 'package:wardrobe/core/vision/cutout/color_extract.dart';
import 'package:wardrobe/core/vision/cutout/erase_brush.dart';
import 'package:wardrobe/core/vision/cutout/sam_click.dart';
import 'package:wardrobe/features/wardrobe/photo_role.dart';
import 'package:wardrobe/core/vision/ocr/tag_ocr.dart';
import 'package:wardrobe/features/wardrobe/data/item_repository.dart';
import 'package:wardrobe/features/wardrobe/click_prompt_overlay.dart';
import 'package:wardrobe/features/wardrobe/erase_brush_overlay.dart';
import 'package:wardrobe/widgets/common.dart';
import 'package:wardrobe/widgets/zoom_viewport.dart';

class EditableItemPhoto {
  EditableItemPhoto({
    required this.id,
    required this.originalPath,
    this.processedPath,
    this.maskPath,
    this.isPrimary = false,
    this.role = ItemPhotoRole.garment,
    this.colors = ColorAnalysis.empty,
    this.ocr = const TagOcrResult(),
    this.showProcessed = true,
    this.busy = false,
    this.busyHint,
    this.error,
    this.originalWidth,
    this.originalHeight,
    this.refinePreviewPath,
  });

  factory EditableItemPhoto.fromRow(ClothingItemImage row) {
    final processed = row.processedPath;
    return EditableItemPhoto(
      id: row.id,
      originalPath: row.originalPath,
      processedPath: processed,
      maskPath: row.maskPath,
      isPrimary: row.isPrimary,
      role: ItemPhotoRole.parse(row.role),
      colors: ColorAnalysis.decode(row.colorJson),
      ocr: TagOcrResult.decode(row.ocrJson),
      showProcessed: processed != null && processed.isNotEmpty,
    );
  }

  final String id;
  String originalPath;
  String? processedPath;
  String? maskPath;
  bool isPrimary;
  ItemPhotoRole role;
  ColorAnalysis colors;
  TagOcrResult ocr;
  bool showProcessed;
  bool busy;
  String? busyHint;
  String? error;
  int? originalWidth;
  int? originalHeight;
  String? refinePreviewPath;

  bool get isTag => role == ItemPhotoRole.tag;

  String get previewPath {
    if (showProcessed && processedPath != null && processedPath!.isNotEmpty) {
      return processedPath!;
    }
    return originalPath;
  }

  ItemImageDraft toDraft() {
    return ItemImageDraft(
      id: id,
      originalPath: originalPath,
      processedPath: processedPath,
      maskPath: maskPath,
      role: role,
      isPrimary: isPrimary && role == ItemPhotoRole.garment,
      colorJson: colors.toJson(),
      ocrJson: ocr.encode(),
    );
  }
}

String itemImagePreviewPath(ClothingItemImage image) {
  final processed = image.processedPath;
  if (processed != null && processed.isNotEmpty) return processed;
  return image.originalPath;
}

enum RefineTool { click, erase, fill }

class ItemPhotoStudio extends StatelessWidget {
  const ItemPhotoStudio({
    super.key,
    required this.photos,
    required this.selectedIndex,
    required this.refining,
    required this.refinePoints,
    required this.refineTool,
    required this.eraseProtect,
    required this.eraseRadius,
    required this.fillSampling,
    required this.hasFillSample,
    required this.hasClickOutline,
    required this.onSelect,
    required this.onAdd,
    this.onAddTag,
    required this.onRemove,
    required this.onSetPrimary,
    required this.onToggleProcessed,
    required this.onReprocess,
    required this.onStartRefine,
    this.onRecognize,
    required this.onCancelRefine,
    required this.onUndoRefine,
    required this.canUndo,
    required this.onAddPoint,
    required this.onEraseStroke,
    required this.onRefineTool,
    required this.onEraseProtect,
    required this.onEraseRadius,
    required this.onFillSampling,
    required this.onFillSample,
    required this.onFillPaint,
  });

  final List<EditableItemPhoto> photos;
  final int selectedIndex;
  final bool refining;
  final List<PromptPoint> refinePoints;
  final RefineTool refineTool;
  final bool eraseProtect;
  final int eraseRadius;
  final bool fillSampling;
  final bool hasFillSample;
  final bool hasClickOutline;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final VoidCallback? onAddTag;
  final VoidCallback onRemove;
  final VoidCallback onSetPrimary;
  final VoidCallback onToggleProcessed;
  final VoidCallback onReprocess;
  final VoidCallback onStartRefine;
  final VoidCallback? onRecognize;
  final VoidCallback onCancelRefine;
  final VoidCallback onUndoRefine;
  final bool canUndo;
  final ValueChanged<PromptPoint> onAddPoint;
  final ValueChanged<List<EraseStamp>> onEraseStroke;
  final ValueChanged<RefineTool> onRefineTool;
  final ValueChanged<bool> onEraseProtect;
  final ValueChanged<int> onEraseRadius;
  final ValueChanged<bool> onFillSampling;
  final ValueChanged<List<EraseStamp>> onFillSample;
  final ValueChanged<List<EraseStamp>> onFillPaint;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return _EmptyAdd(onAdd: onAdd, onAddTag: onAddTag);
    }
    final selected = photos[selectedIndex.clamp(0, photos.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _PreviewCard(
            photo: selected,
            refining: refining,
            points: refinePoints,
            tool: refineTool,
            eraseRadius: eraseRadius,
            fillSampling: fillSampling,
            onAddPoint: onAddPoint,
            onEraseStroke: onEraseStroke,
            onFillSample: onFillSample,
            onFillPaint: onFillPaint,
          ),
        ),
        const SizedBox(height: 12),
        if (refining)
          _RefineActions(
            busy: selected.busy,
            canUndo: canUndo,
            tool: refineTool,
            eraseProtect: eraseProtect,
            eraseRadius: eraseRadius,
            fillSampling: fillSampling,
            hasFillSample: hasFillSample,
            hasClickOutline: hasClickOutline,
            allowFill: !selected.isTag,
            onTool: onRefineTool,
            onProtect: onEraseProtect,
            onRadius: onEraseRadius,
            onFillSampling: onFillSampling,
            onUndo: onUndoRefine,
            onCancel: onCancelRefine,
          )
        else
          _PhotoActions(
            photo: selected,
            onRemove: onRemove,
            onSetPrimary: onSetPrimary,
            onToggleProcessed: onToggleProcessed,
            onReprocess: onReprocess,
            onStartRefine: onStartRefine,
            onRecognize: onRecognize,
          ),
        const SizedBox(height: 12),
        _ThumbStrip(
          photos: photos,
          selectedIndex: selectedIndex,
          enabled: !refining && !selected.busy,
          onSelect: onSelect,
          onAdd: onAdd,
          onAddTag: onAddTag,
        ),
      ],
    );
  }
}

class ItemPhotoStrip extends StatelessWidget {
  const ItemPhotoStrip({
    super.key,
    required this.photos,
    required this.onOpenStudio,
  });

  final List<EditableItemPhoto> photos;
  final VoidCallback onOpenStudio;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenStudio,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          child: Row(
            children: [
              if (photos.isEmpty)
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppPalette.of(context).primary,
                  ),
                )
              else
                Flexible(
                  child: SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: LocalCover(
                              path: photos[i].previewPath,
                              fit: BoxFit.contain,
                              checkerboard: true,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  photos.isEmpty
                      ? '还没有图片，点这里添加'
                      : '已选 ${photos.length} 张 · 点这里改图或点选',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class ItemPhotoViewer extends StatefulWidget {
  const ItemPhotoViewer({super.key, required this.images, this.fallbackPath});

  final List<ClothingItemImage> images;
  final String? fallbackPath;

  @override
  State<ItemPhotoViewer> createState() => _ItemPhotoViewerState();
}

class _ItemPhotoViewerState extends State<ItemPhotoViewer> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant ItemPhotoViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.images.length) {
      _index = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return DetailHeroImage(path: widget.fallbackPath, checkerboard: true);
    }
    final image = widget.images[_index.clamp(0, widget.images.length - 1)];
    final path = itemImagePreviewPath(image);
    final isTag = ItemPhotoRole.parse(image.role) == ItemPhotoRole.tag;
    return Column(
      children: [
        Stack(
          children: [
            DetailHeroImage(path: path, checkerboard: true),
            if (isTag)
              const Positioned(
                left: 12,
                top: 12,
                child: Chip(
                  label: Text('吊牌'),
                  backgroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        if (widget.images.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final row = widget.images[i];
                final selected = i == _index;
                final tag = ItemPhotoRole.parse(row.role) == ItemPhotoRole.tag;
                return InkWell(
                  onTap: () => setState(() => _index = i),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppPalette.of(context).primary
                            : AppColors.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        LocalCover(
                          path: itemImagePreviewPath(row),
                          fit: BoxFit.contain,
                          checkerboard: true,
                        ),
                        if (tag)
                          const Align(
                            alignment: Alignment.bottomCenter,
                            child: ColoredBox(
                              color: Color(0xAAFFFFFF),
                              child: Text(
                                '吊牌',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyAdd extends StatelessWidget {
  const _EmptyAdd({required this.onAdd, this.onAddTag});

  final VoidCallback onAdd;
  final VoidCallback? onAddTag;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 56,
              color: AppPalette.of(context).primary,
            ),
            const SizedBox(height: 12),
            const Text(
              '添加衣物图，可多选',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            const Text(
              '添加后直接点衣服和衣架；吊牌可另加',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.checkroom_outlined, size: 18),
                  label: const Text('衣物图'),
                ),
                if (onAddTag != null)
                  OutlinedButton.icon(
                    onPressed: onAddTag,
                    icon: const Icon(Icons.style_outlined, size: 18),
                    label: const Text('吊牌'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.photo,
    required this.refining,
    required this.points,
    required this.tool,
    required this.eraseRadius,
    required this.fillSampling,
    required this.onAddPoint,
    required this.onEraseStroke,
    required this.onFillSample,
    required this.onFillPaint,
  });

  final EditableItemPhoto photo;
  final bool refining;
  final List<PromptPoint> points;
  final RefineTool tool;
  final int eraseRadius;
  final bool fillSampling;
  final ValueChanged<PromptPoint> onAddPoint;
  final ValueChanged<List<EraseStamp>> onEraseStroke;
  final ValueChanged<List<EraseStamp>> onFillSample;
  final ValueChanged<List<EraseStamp>> onFillPaint;

  @override
  Widget build(BuildContext context) {
    final path = refining
        ? (photo.refinePreviewPath ?? photo.processedPath ?? photo.originalPath)
        : photo.previewPath;
    final width = photo.originalWidth;
    final height = photo.originalHeight;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ZoomViewport(
            resetKey: photo.id,
            panWithSecondary: !refining,
            child: Stack(
              fit: StackFit.expand,
              children: [
                LocalCover(
                  path: path,
                  fit: BoxFit.contain,
                  checkerboard: true,
                  placeholder: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                if (refining &&
                    width != null &&
                    height != null &&
                    width > 0 &&
                    height > 0)
                  switch (tool) {
                    RefineTool.erase => EraseBrushOverlay(
                      imageWidth: width,
                      imageHeight: height,
                      radius: eraseRadius,
                      onStroke: onEraseStroke,
                    ),
                    RefineTool.fill => EraseBrushOverlay(
                      imageWidth: width,
                      imageHeight: height,
                      radius: eraseRadius,
                      accent: fillSampling
                          ? AppPalette.of(context).primary
                          : const Color(0xFF3D8B6E),
                      onStroke: fillSampling ? onFillSample : onFillPaint,
                    ),
                    RefineTool.click => ClickPromptOverlay(
                      imageWidth: width,
                      imageHeight: height,
                      points: points,
                      onAdd: onAddPoint,
                    ),
                  },
              ],
            ),
          ),
          if (photo.busy)
            ExcludeSemantics(
              child: ColoredBox(
                color: const Color(0x88FFFFFF),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        photo.busyHint ?? (refining ? '正在更新抠图…' : '正在处理图片…'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (photo.isPrimary && !refining)
            const Positioned(
              left: 12,
              top: 12,
              child: Chip(
                label: Text('封面'),
                backgroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
            ),
          if (photo.isTag && !refining)
            const Positioned(
              left: 12,
              top: 12,
              child: Chip(
                label: Text('吊牌'),
                backgroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
            ),
          if (photo.error != null && !refining)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Material(
                color: const Color(0xEEFFFFFF),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    photo.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoActions extends StatelessWidget {
  const _PhotoActions({
    required this.photo,
    required this.onRemove,
    required this.onSetPrimary,
    required this.onToggleProcessed,
    required this.onReprocess,
    required this.onStartRefine,
    this.onRecognize,
  });

  final EditableItemPhoto photo;
  final VoidCallback onRemove;
  final VoidCallback onSetPrimary;
  final VoidCallback onToggleProcessed;
  final VoidCallback onReprocess;
  final VoidCallback onStartRefine;
  final VoidCallback? onRecognize;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (photo.processedPath != null)
          TextButton(
            onPressed: photo.busy ? null : onToggleProcessed,
            child: Text(photo.showProcessed ? '查看原图' : '查看抠图'),
          ),
        TextButton(
          onPressed: photo.busy ? null : onStartRefine,
          child: const Text('精修'),
        ),
        if (!photo.isPrimary && !photo.isTag)
          TextButton(
            onPressed: photo.busy ? null : onSetPrimary,
            child: const Text('设为封面'),
          ),
        if (!photo.isTag)
          TextButton(
            onPressed: photo.busy ? null : onReprocess,
            child: const Text('自动抠图'),
          ),
        if (photo.isTag && onRecognize != null)
          TextButton(
            onPressed: photo.busy ? null : onRecognize,
            child: const Text('识别文字'),
          ),
        TextButton(
          onPressed: photo.busy ? null : onRemove,
          child: const Text('删除这张', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }
}

class _RefineActions extends StatelessWidget {
  const _RefineActions({
    required this.busy,
    required this.canUndo,
    required this.tool,
    required this.eraseProtect,
    required this.eraseRadius,
    required this.fillSampling,
    required this.hasFillSample,
    required this.hasClickOutline,
    this.allowFill = true,
    required this.onTool,
    required this.onProtect,
    required this.onRadius,
    required this.onFillSampling,
    required this.onUndo,
    required this.onCancel,
  });

  final bool busy;
  final bool canUndo;
  final RefineTool tool;
  final bool eraseProtect;
  final int eraseRadius;
  final bool fillSampling;
  final bool hasFillSample;
  final bool hasClickOutline;
  final bool allowFill;
  final ValueChanged<RefineTool> onTool;
  final ValueChanged<bool> onProtect;
  final ValueChanged<int> onRadius;
  final ValueChanged<bool> onFillSampling;
  final VoidCallback onUndo;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final erasing = tool == RefineTool.erase;
    final filling = tool == RefineTool.fill;
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                label: const Text('点选'),
                selected: tool == RefineTool.click,
                onSelected: busy ? null : (_) => onTool(RefineTool.click),
              ),
              FilterChip(
                label: const Text('擦除'),
                selected: tool == RefineTool.erase,
                onSelected: busy || !hasClickOutline
                    ? null
                    : (_) => onTool(RefineTool.erase),
              ),
              if (allowFill)
                FilterChip(
                  label: const Text('填补'),
                  selected: tool == RefineTool.fill,
                  onSelected: busy || !hasClickOutline
                      ? null
                      : (_) => onTool(RefineTool.fill),
                ),
              if (erasing)
                FilterChip(
                  label: const Text('保护衣服色'),
                  selected: eraseProtect,
                  onSelected: busy ? null : onProtect,
                ),
              if (filling) ...[
                FilterChip(
                  label: const Text('取样'),
                  selected: fillSampling,
                  onSelected: busy ? null : (_) => onFillSampling(true),
                ),
                FilterChip(
                  label: Text(hasFillSample ? '涂抹' : '涂抹（先取样）'),
                  selected: !fillSampling,
                  onSelected: busy || !hasFillSample
                      ? null
                      : (_) => onFillSampling(false),
                ),
              ],
              if (erasing || filling)
                SizedBox(
                  width: 140,
                  child: Slider(
                    min: 6,
                    max: 36,
                    divisions: 15,
                    value: eraseRadius.toDouble().clamp(6, 36),
                    label: '$eraseRadius',
                    onChanged: busy ? null : (v) => onRadius(v.round()),
                  ),
                ),
              TextButton(
                onPressed: busy || !canUndo ? null : onUndo,
                child: const Text('撤回'),
              ),
              TextButton(
                onPressed: busy ? null : onCancel,
                child: const Text('完成精修'),
              ),
            ],
          ),
          Text(
            filling
                ? (fillSampling
                      ? '先涂一块带花纹的布取样，再点「涂抹」画要补的位置。笔触盖住的像素都会改掉。滚轮放大，中键或空格拖动'
                      : '在要补的位置涂抹，按刚才取的纹理填上。滚轮放大，中键或空格拖动')
                : erasing
                ? (allowFill
                      ? '拖动擦除杂色；默认跳过衣服色，可关掉保护后硬擦。滚轮放大，中键或空格拖动'
                      : '拖动擦掉吊牌外的杂物。滚轮放大，中键或空格拖动')
                : hasClickOutline
                ? (allowFill
                      ? '左键点衣服，右键点衣架；点好轮廓后再擦除或填补。滚轮放大，中键或空格拖动'
                      : '左键点吊牌，右键点背景；点好后再识别文字。滚轮放大，中键或空格拖动')
                : (allowFill
                      ? '左键点衣服，右键点衣架，先选出大体轮廓。滚轮放大，中键或空格拖动'
                      : '左键点吊牌，右键点背景，先抠掉不是吊牌的部分。滚轮放大，中键或空格拖动'),
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ThumbStrip extends StatelessWidget {
  const _ThumbStrip({
    required this.photos,
    required this.selectedIndex,
    required this.enabled,
    required this.onSelect,
    required this.onAdd,
    this.onAddTag,
  });

  final List<EditableItemPhoto> photos;
  final int selectedIndex;
  final bool enabled;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final VoidCallback? onAddTag;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == photos.length) {
            return PopupMenuButton<String>(
              enabled: enabled,
              tooltip: '添加图片',
              onSelected: (v) {
                if (v == 'tag') {
                  onAddTag?.call();
                } else {
                  onAdd();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'garment', child: Text('衣物图')),
                if (onAddTag != null)
                  const PopupMenuItem(value: 'tag', child: Text('吊牌')),
              ],
              child: OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(72, 72),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Icon(Icons.add, color: AppPalette.of(context).primary),
              ),
            );
          }
          final photo = photos[i];
          final selected = i == selectedIndex;
          return InkWell(
            onTap: enabled ? () => onSelect(i) : null,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? AppPalette.of(context).primary
                      : AppColors.border,
                  width: selected ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LocalCover(
                    path: photo.previewPath,
                    fit: BoxFit.contain,
                    checkerboard: true,
                  ),
                  if (photo.isTag)
                    const Align(
                      alignment: Alignment.bottomCenter,
                      child: ColoredBox(
                        color: Color(0xAAFFFFFF),
                        child: Text(
                          '吊牌',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  if (photo.busy)
                    const ColoredBox(
                      color: Color(0x66FFFFFF),
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class HangtagOcrBlock extends StatelessWidget {
  const HangtagOcrBlock({
    super.key,
    required this.text,
    this.imagePaths = const [],
  });

  final String text;
  final List<String> imagePaths;

  @override
  Widget build(BuildContext context) {
    final body = text.trim();
    if (body.isEmpty && imagePaths.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '吊牌识别原文',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagePaths.isNotEmpty) ...[
              SizedBox(
                width: 132,
                height: 200,
                child: imagePaths.length == 1
                    ? _thumb(imagePaths.first)
                    : ListView.separated(
                        itemCount: imagePaths.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          return SizedBox(
                            height: 120,
                            child: _thumb(imagePaths[i]),
                          );
                        },
                      ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                body.isEmpty ? '未识别到文字' : body,
                style: TextStyle(
                  color: body.isEmpty ? AppColors.textMuted : AppColors.text,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _thumb(String path) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: LocalCover(
          path: path,
          fit: BoxFit.contain,
          checkerboard: true,
          borderRadius: 12,
        ),
      ),
    );
  }
}
