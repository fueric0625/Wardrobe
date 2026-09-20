import 'package:flutter/material.dart';
import 'package:wardrobe/core/db/app_database.dart';
import 'package:wardrobe/core/theme.dart';
import 'package:wardrobe/core/vision/color_extract.dart';
import 'package:wardrobe/core/vision/erase_brush.dart';
import 'package:wardrobe/core/vision/garment_pipeline.dart';
import 'package:wardrobe/core/vision/image_ops.dart';
import 'package:wardrobe/core/vision/sam_click.dart';
import 'package:wardrobe/data/item_repository.dart';
import 'package:wardrobe/features/wardrobe/click_prompt_overlay.dart';
import 'package:wardrobe/features/wardrobe/erase_brush_overlay.dart';
import 'package:wardrobe/features/wardrobe/fill_box_overlay.dart';
import 'package:wardrobe/widgets/common.dart';
import 'package:wardrobe/widgets/zoom_viewport.dart';

class EditableItemPhoto {
  EditableItemPhoto({
    required this.id,
    required this.originalPath,
    this.processedPath,
    this.maskPath,
    this.isPrimary = false,
    this.colors = ColorAnalysis.empty,
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
      colors: ColorAnalysis.decode(row.colorJson),
      showProcessed: processed != null && processed.isNotEmpty,
    );
  }

  final String id;
  String originalPath;
  String? processedPath;
  String? maskPath;
  bool isPrimary;
  ColorAnalysis colors;
  bool showProcessed;
  bool busy;
  String? busyHint;
  String? error;
  int? originalWidth;
  int? originalHeight;
  String? refinePreviewPath;

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
      role: ItemPhotoRole.garment,
      isPrimary: isPrimary,
      colorJson: colors.toJson(),
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
    required this.fillWithBox,
    required this.onSelect,
    required this.onAdd,
    required this.onRemove,
    required this.onSetPrimary,
    required this.onToggleProcessed,
    required this.onReprocess,
    required this.onStartRefine,
    required this.onCancelRefine,
    required this.onUndoRefine,
    required this.canUndo,
    required this.onAddPoint,
    required this.onEraseStroke,
    required this.onRefineTool,
    required this.onEraseProtect,
    required this.onEraseRadius,
    required this.onFillWithBox,
    required this.onFillBox,
    required this.onFillBrush,
  });

  final List<EditableItemPhoto> photos;
  final int selectedIndex;
  final bool refining;
  final List<PromptPoint> refinePoints;
  final RefineTool refineTool;
  final bool eraseProtect;
  final int eraseRadius;
  final bool fillWithBox;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onSetPrimary;
  final VoidCallback onToggleProcessed;
  final VoidCallback onReprocess;
  final VoidCallback onStartRefine;
  final VoidCallback onCancelRefine;
  final VoidCallback onUndoRefine;
  final bool canUndo;
  final ValueChanged<PromptPoint> onAddPoint;
  final ValueChanged<List<EraseStamp>> onEraseStroke;
  final ValueChanged<RefineTool> onRefineTool;
  final ValueChanged<bool> onEraseProtect;
  final ValueChanged<int> onEraseRadius;
  final ValueChanged<bool> onFillWithBox;
  final ValueChanged<PixelRect> onFillBox;
  final ValueChanged<List<EraseStamp>> onFillBrush;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return _EmptyAdd(onAdd: onAdd);
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
            fillWithBox: fillWithBox,
            onAddPoint: onAddPoint,
            onEraseStroke: onEraseStroke,
            onFillBox: onFillBox,
            onFillBrush: onFillBrush,
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
            fillWithBox: fillWithBox,
            onTool: onRefineTool,
            onProtect: onEraseProtect,
            onRadius: onEraseRadius,
            onFillWithBox: onFillWithBox,
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
          ),
        const SizedBox(height: 12),
        _ThumbStrip(
          photos: photos,
          selectedIndex: selectedIndex,
          enabled: !refining && !selected.busy,
          onSelect: onSelect,
          onAdd: onAdd,
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
                const SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
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
                  photos.isEmpty ? '还没有图片，点这里添加' : '已选 ${photos.length} 张 · 点这里改图或点选',
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
  const ItemPhotoViewer({
    super.key,
    required this.images,
    this.fallbackPath,
  });

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
    return Column(
      children: [
        DetailHeroImage(path: path, checkerboard: true),
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
                return InkWell(
                  onTap: () => setState(() => _index = i),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: LocalCover(
                      path: itemImagePreviewPath(row),
                      fit: BoxFit.contain,
                      checkerboard: true,
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
  const _EmptyAdd({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAdd,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 56, color: AppColors.primary),
              SizedBox(height: 12),
              Text('点击添加图片，可多选', style: TextStyle(color: AppColors.textMuted)),
              SizedBox(height: 4),
              Text('添加后直接点衣服和衣架，不必等自动抠图', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
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
    required this.fillWithBox,
    required this.onAddPoint,
    required this.onEraseStroke,
    required this.onFillBox,
    required this.onFillBrush,
  });

  final EditableItemPhoto photo;
  final bool refining;
  final List<PromptPoint> points;
  final RefineTool tool;
  final int eraseRadius;
  final bool fillWithBox;
  final ValueChanged<PromptPoint> onAddPoint;
  final ValueChanged<List<EraseStamp>> onEraseStroke;
  final ValueChanged<PixelRect> onFillBox;
  final ValueChanged<List<EraseStamp>> onFillBrush;

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
                    child: Icon(Icons.image_outlined, size: 48, color: AppColors.textMuted),
                  ),
                ),
                if (refining && width != null && height != null && width > 0 && height > 0)
                  switch (tool) {
                    RefineTool.erase => EraseBrushOverlay(
                        imageWidth: width,
                        imageHeight: height,
                        radius: eraseRadius,
                        onStroke: onEraseStroke,
                      ),
                    RefineTool.fill => fillWithBox
                        ? FillBoxOverlay(
                            imageWidth: width,
                            imageHeight: height,
                            onBox: onFillBox,
                          )
                        : EraseBrushOverlay(
                            imageWidth: width,
                            imageHeight: height,
                            radius: eraseRadius,
                            accent: AppColors.primary,
                            onStroke: onFillBrush,
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
                    Text(photo.busyHint ?? (refining ? '正在更新抠图…' : '正在处理图片…')),
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
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
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
  });

  final EditableItemPhoto photo;
  final VoidCallback onRemove;
  final VoidCallback onSetPrimary;
  final VoidCallback onToggleProcessed;
  final VoidCallback onReprocess;
  final VoidCallback onStartRefine;

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
        if (!photo.isPrimary)
          TextButton(
            onPressed: photo.busy ? null : onSetPrimary,
            child: const Text('设为封面'),
          ),
        TextButton(
          onPressed: photo.busy ? null : onReprocess,
          child: const Text('自动抠图'),
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
    required this.fillWithBox,
    required this.onTool,
    required this.onProtect,
    required this.onRadius,
    required this.onFillWithBox,
    required this.onUndo,
    required this.onCancel,
  });

  final bool busy;
  final bool canUndo;
  final RefineTool tool;
  final bool eraseProtect;
  final int eraseRadius;
  final bool fillWithBox;
  final ValueChanged<RefineTool> onTool;
  final ValueChanged<bool> onProtect;
  final ValueChanged<int> onRadius;
  final ValueChanged<bool> onFillWithBox;
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
              onSelected: busy ? null : (_) => onTool(RefineTool.erase),
            ),
            FilterChip(
              label: const Text('填补'),
              selected: tool == RefineTool.fill,
              onSelected: busy ? null : (_) => onTool(RefineTool.fill),
            ),
            if (erasing)
              FilterChip(
                label: const Text('保护衣服色'),
                selected: eraseProtect,
                onSelected: busy ? null : onProtect,
              ),
            if (filling) ...[
              FilterChip(
                label: const Text('框选'),
                selected: fillWithBox,
                onSelected: busy ? null : (_) => onFillWithBox(true),
              ),
              FilterChip(
                label: const Text('笔选'),
                selected: !fillWithBox,
                onSelected: busy ? null : (_) => onFillWithBox(false),
              ),
            ],
            if (erasing || (filling && !fillWithBox))
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
            TextButton(onPressed: busy ? null : onCancel, child: const Text('完成精修')),
          ],
        ),
        Text(
          filling
              ? '框住或涂过带花纹的布料；空洞会按这块纹理补上，更深的衣架阴影会再清一轮。单击也能取样。滚轮放大，中键或空格拖动'
              : erasing
                  ? '拖动擦除杂色；填补后会再清一层更深的衣架阴影。滚轮放大，中键或空格拖动'
                  : '左键点衣服，右键点衣架；滚轮放大，中键或空格拖动',
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
  });

  final List<EditableItemPhoto> photos;
  final int selectedIndex;
  final bool enabled;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

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
            return OutlinedButton(
              onPressed: enabled ? onAdd : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(72, 72),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Icon(Icons.add, color: AppColors.primary),
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
                  color: selected ? AppColors.primary : AppColors.border,
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
