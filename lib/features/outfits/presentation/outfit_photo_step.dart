import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wardrobe/core/design_system/theme.dart';
import 'package:wardrobe/features/outfits/outfit_collage_board.dart';
import 'package:wardrobe/features/outfits/presentation/outfit_edit_controller.dart';
import 'package:wardrobe/features/outfits/providers.dart';
import 'package:wardrobe/widgets/common.dart';
import 'package:wardrobe/widgets/piece_collage.dart';

class OutfitPhotoStep extends ConsumerWidget {
  const OutfitPhotoStep({super.key, required this.editKey});

  final OutfitEditKey editKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(outfitEditControllerProvider(editKey));
    final controller = ref.read(outfitEditControllerProvider(editKey).notifier);
    ref.watch(clothingCutoutsProvider);
    final path = state.displayPath;
    final cutout = path != null && path.toLowerCase().endsWith('.png');
    final collage = controller.collage();
    final hasPhoto = path != null && path.isNotEmpty;
    final canCollage = collage.placements.isNotEmpty;
    final useCollage = outfitUsesCollage(
      imagePath: path,
      coverMode: state.coverMode,
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
                        selectedColor: AppPalette.of(context).primarySoft,
                        onSelected: (_) => controller.selectCoverPhoto(),
                      )
                    else
                      const Text(
                        '全身照，可以跳过',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _PhotoPanel(
                    editKey: editKey,
                    path: path,
                    cutout: cutout,
                    selected: hasPhoto && !useCollage,
                  ),
                ),
                if (path != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final mode in OutfitPhotoMode.values)
                        ChoiceChip(
                          label: Text(outfitPhotoModeLabel(mode)),
                          selected: state.mode == mode,
                          selectedColor: AppPalette.of(context).primarySoft,
                          onSelected: state.photoBusy
                              ? null
                              : (_) => controller.applyMode(mode),
                        ),
                    ],
                  ),
                ],
                if (state.photoError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.photoError!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _CollagePanel(editKey: editKey, selected: useCollage),
          ),
        ],
      ),
    );
  }
}

class _PhotoPanel extends ConsumerWidget {
  const _PhotoPanel({
    required this.editKey,
    required this.path,
    required this.cutout,
    required this.selected,
  });

  final OutfitEditKey editKey;
  final String? path;
  final bool cutout;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(outfitEditControllerProvider(editKey));
    final controller = ref.read(outfitEditControllerProvider(editKey).notifier);
    final frame = _coverFrame(
      selected: selected,
      accent: AppPalette.of(context).primary,
    );
    if (path == null) {
      return Material(
        color: AppColors.surface,
        shape: frame,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: state.photoBusy ? null : controller.pickImage,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 48,
                color: AppPalette.of(context).primary,
              ),
              const SizedBox(height: 12),
              const Text(
                '点击选择全身照',
                style: TextStyle(color: AppColors.textMuted),
              ),
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
              onPressed: state.photoBusy ? null : controller.pickImage,
            ),
          ),
          if (state.photoBusy)
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
}

class _CollagePanel extends ConsumerWidget {
  const _CollagePanel({required this.editKey, required this.selected});

  final OutfitEditKey editKey;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(outfitEditControllerProvider(editKey).notifier);
    ref.watch(clothingCutoutsProvider);
    ref.watch(outfitEditControllerProvider(editKey));
    final collage = controller.collage();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (collage.placements.isNotEmpty)
              ChoiceChip(
                label: const Text('拼图'),
                selected: selected,
                selectedColor: AppPalette.of(context).primarySoft,
                onSelected: (_) => controller.selectCoverCollage(),
              )
            else
              const Text('拼图', style: TextStyle(color: AppColors.textMuted)),
            if (collage.placements.isNotEmpty) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: controller.rearrange,
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
              shape: _coverFrame(
                selected: selected,
                accent: AppPalette.of(context).primary,
              ),
              clipBehavior: Clip.antiAlias,
              child: collage.placements.isEmpty
                  ? const Center(
                      child: Text(
                        '先关联有抠图的衣物',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : OutfitCollageBoard(
                      placements: collage.placements,
                      paths: collage.images,
                      onChanged: controller.setPlacements,
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
}

RoundedRectangleBorder _coverFrame({
  required bool selected,
  required Color accent,
}) {
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(24),
    side: BorderSide(
      color: selected ? accent : AppColors.border,
      width: selected ? 2 : 1,
    ),
  );
}
