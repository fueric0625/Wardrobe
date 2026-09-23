import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wardrobe/features/outfits/outfit_clothes_picker.dart';
import 'package:wardrobe/features/outfits/presentation/outfit_detail_step.dart';
import 'package:wardrobe/features/outfits/presentation/outfit_edit_controller.dart';
import 'package:wardrobe/features/outfits/presentation/outfit_edit_dialogs.dart';
import 'package:wardrobe/features/outfits/presentation/outfit_edit_header.dart';
import 'package:wardrobe/features/outfits/presentation/outfit_photo_step.dart';

class OutfitEditPage extends ConsumerWidget {
  const OutfitEditPage({super.key, this.outfitId, this.categoryId});

  final String? outfitId;
  final String? categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editKey = (outfitId: outfitId, categoryId: categoryId);
    final state = ref.watch(outfitEditControllerProvider(editKey));
    final controller = ref.read(outfitEditControllerProvider(editKey).notifier);
    ref.listen(outfitEditControllerProvider(editKey), (previous, next) {
      if (next.missing && previous?.missing != true) {
        context.go('/outfits');
      }
    });
    if (!state.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          OutfitEditHeader(
            editKey: editKey,
            onBack: () {
              if (controller.leavePage) {
                context.pop();
                return;
              }
              controller.back();
            },
            onSkipPhoto: controller.skipPhoto,
            onDelete: () async {
              final ok = await confirmOutfitAction(
                context,
                title: '删除这套穿搭？',
                message: '删除后无法恢复。',
              );
              if (!ok || !context.mounted) return;
              await controller.delete();
              if (context.mounted) context.go('/outfits');
            },
            onSave: () async {
              final id = await controller.save();
              if (id != null && context.mounted) {
                context.go('/outfits/item/$id');
              }
            },
          ),
          Expanded(
            child: switch (state.step) {
              0 => OutfitClothesPicker(
                selectedIds: state.clothingIds,
                onToggle: controller.toggleClothing,
                rootId: state.rootId,
                filterId: state.filterId,
                onOpenRoot: controller.openRoot,
                onBackToRoots: controller.backToRoots,
                onFilter: controller.filterCategory,
              ),
              1 => OutfitPhotoStep(editKey: editKey),
              _ => OutfitDetailStep(
                editKey: editKey,
                onDeletePhoto: () async {
                  final ok = await confirmOutfitAction(
                    context,
                    title: '删除这张全身照？',
                  );
                  if (ok) await controller.deleteDetailPhoto();
                },
                onDeleteCollage: () async {
                  final ok = await confirmOutfitAction(
                    context,
                    title: '删除这张拼图？',
                  );
                  if (ok) controller.deleteDetailCollage();
                },
              ),
            },
          ),
        ],
      ),
    );
  }
}
