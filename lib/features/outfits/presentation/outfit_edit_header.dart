import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wardrobe/core/design_system/theme.dart';
import 'package:wardrobe/features/outfits/presentation/outfit_edit_controller.dart';

class OutfitEditHeader extends ConsumerWidget {
  const OutfitEditHeader({
    super.key,
    required this.editKey,
    required this.onBack,
    required this.onSkipPhoto,
    required this.onDelete,
    required this.onSave,
  });

  final OutfitEditKey editKey;
  final VoidCallback onBack;
  final VoidCallback onSkipPhoto;
  final VoidCallback onDelete;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(outfitEditControllerProvider(editKey));
    final controller = ref.read(outfitEditControllerProvider(editKey).notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 28, 8),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: state.photoBusy ? null : onBack,
            icon: const Icon(Icons.arrow_back_ios_new, size: 16),
            label: const Text('返回'),
          ),
          Expanded(child: _StepTitle(editKey: editKey)),
          ..._actions(state, controller),
        ],
      ),
    );
  }

  List<Widget> _actions(
    OutfitEditState state,
    OutfitEditController controller,
  ) {
    if (state.step == 0) {
      return [
        TextButton(onPressed: controller.skipClothes, child: const Text('跳过')),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: controller.nextFromClothes,
          child: const Text('下一步'),
        ),
      ];
    }
    if (state.step == 1) {
      return [
        if (state.displayPath != null)
          TextButton(
            onPressed: state.photoBusy ? null : onSkipPhoto,
            child: const Text('跳过'),
          ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: state.photoBusy ? null : controller.openDetails,
          child: const Text('下一步'),
        ),
      ];
    }
    return [
      if (controller.isEditing)
        TextButton(
          onPressed: state.saving ? null : onDelete,
          child: const Text('删除', style: TextStyle(color: Colors.redAccent)),
        ),
      const SizedBox(width: 8),
      FilledButton(
        onPressed: state.saving || state.photoBusy ? null : onSave,
        child: Text(state.saving ? '保存中' : '确定'),
      ),
    ];
  }
}

class _StepTitle extends ConsumerWidget {
  const _StepTitle({required this.editKey});

  final OutfitEditKey editKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(outfitEditControllerProvider(editKey));
    final controller = ref.read(outfitEditControllerProvider(editKey).notifier);
    const labels = ['关联衣物', 'OOTD', '详情'];
    final family = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          TextButton(
            onPressed: state.photoBusy ? null : () => controller.goToStep(i),
            style: TextButton.styleFrom(
              foregroundColor: i == state.step
                  ? AppColors.text
                  : AppColors.textMuted,
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                fontFamily: family,
                fontSize: i == state.step ? 18 : 15,
                height: 1.2,
                letterSpacing: 0,
                fontWeight: i == state.step ? FontWeight.w600 : FontWeight.w400,
                color: i == state.step ? AppColors.text : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
