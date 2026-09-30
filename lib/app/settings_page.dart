import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wardrobe/app/providers.dart';
import 'package:wardrobe/core/design_system/app_appearance.dart';
import 'package:wardrobe/core/design_system/app_font.dart';
import 'package:wardrobe/core/design_system/theme.dart';
import 'package:wardrobe/core/storage/app_paths.dart';
import 'package:wardrobe/core/storage/folder_picker.dart';
import 'package:wardrobe/core/storage/wardrobe_backup.dart';
import 'package:wardrobe/widgets/common.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appAppearanceProvider);
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(title: '设置'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
              children: [
                const _SectionTitle('外观'),
                const SizedBox(height: 12),
                _AppearanceCard(
                  appearance: appearance,
                  onFont: (family) => ref
                      .read(appAppearanceProvider.notifier)
                      .selectFont(family),
                  onTextSize: (id) => ref
                      .read(appAppearanceProvider.notifier)
                      .selectTextSize(id),
                  onColor: (id) =>
                      ref.read(appAppearanceProvider.notifier).selectColor(id),
                ),
                const SizedBox(height: 28),
                const _SectionTitle('备份'),
                const SizedBox(height: 12),
                const _BackupCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({
    required this.appearance,
    required this.onFont,
    required this.onTextSize,
    required this.onColor,
  });

  final AppAppearance appearance;
  final ValueChanged<String> onFont;
  final ValueChanged<String> onTextSize;
  final ValueChanged<String> onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RowLabel('字体'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final choice in appFontChoices)
                _ChoiceChip(
                  label: choice.label,
                  selected: appearance.fontFamily == choice.family,
                  fontFamily: choice.family,
                  onTap: () => onFont(choice.family),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const _RowLabel('文字大小'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final choice in appTextSizeChoices)
                _ChoiceChip(
                  label: choice.label,
                  selected: appearance.textSizeId == choice.id,
                  onTap: () => onTextSize(choice.id),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const _RowLabel('主体颜色'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final choice in appColorChoices)
                _ColorSwatch(
                  label: choice.label,
                  color: choice.primary,
                  selected: appearance.colorId == choice.id,
                  onTap: () => onColor(choice.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackupCard extends ConsumerStatefulWidget {
  const _BackupCard();

  @override
  ConsumerState<_BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends ConsumerState<_BackupCard> {
  var _busy = false;
  var _importing = false;
  var _copiedBytes = 0;
  var _totalBytes = 0;
  var _swapping = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final parent = await pickFolder(title: '选择备份放到哪里');
      if (parent == null || !mounted) return;
      final dest = await exportWardrobeBackup(
        source: AppPaths.supportDirectory(),
        destinationParent: Directory(parent),
        beforeCopy: () => ref
            .read(databaseProvider)
            .customStatement('PRAGMA wal_checkpoint(TRUNCATE)'),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('备份已导出'),
          content: Text(
            '放在：\n${dest.path}\n\n'
            '要恢复，在设置里点「导入备份」，选这个文件夹。',
          ),
          actions: [
            TextButton(
              onPressed: () => openFolder(dest.path),
              child: const Text('打开文件夹'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('好'),
            ),
          ],
        ),
      );
    } on StateError {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('没有找到衣橱数据，导出失败')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('导出失败')));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _importing = false;
        });
      }
    }
  }

  Future<void> _import() async {
    final picked = await pickFolder(title: '选择要导入的备份');
    if (picked == null || !mounted) return;
    if (!File(p.join(picked, 'wardrobe.sqlite')).existsSync()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('这个文件夹里没有衣橱备份')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入这份备份？'),
        content: const Text('现在的衣橱会被盖掉，衣物、图片、外观、布局和排序都会换成备份里的。无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _importing = true;
      _copiedBytes = 0;
      _totalBytes = 0;
      _swapping = false;
    });
    try {
      final data = AppPaths.supportDirectory();
      var lastPaint = DateTime.fromMillisecondsSinceEpoch(0);
      await stageWardrobeImport(
        backup: Directory(picked),
        destination: data,
        onProgress: (copied, total) {
          final now = DateTime.now();
          final due =
              copied == total ||
              now.difference(lastPaint) > const Duration(milliseconds: 80);
          if (!due || !mounted) return;
          lastPaint = now;
          setState(() {
            _copiedBytes = copied;
            _totalBytes = total;
          });
        },
      );
      if (!mounted) return;
      setState(() => _swapping = true);
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
      final reopened = await _reopenApp();
      if (!reopened && mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('请重新打开衣橱'),
            content: const Text('备份已经准备好，完全退出后再打开就会换上。'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('好'),
              ),
            ],
          ),
        );
      }
      return;
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('导入失败')));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _importing = false;
          _swapping = false;
          _copiedBytes = 0;
          _totalBytes = 0;
        });
      }
    }
  }

  Future<bool> _reopenApp() async {
    try {
      await Process.start(
        Platform.resolvedExecutable,
        const <String>[],
        mode: ProcessStartMode.detached,
      );
    } catch (_) {
      return false;
    }
    exit(0);
  }

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
          const Text('导出或导入一份本机备份。包含数据库、图片、外观、布局和排序。'),
          const SizedBox(height: 8),
          const Text(
            '不包含识别和抠图用的模型。应用打开时会自己准备。导入会盖掉现在的衣橱，然后重新打开。',
            style: TextStyle(color: AppColors.textMuted),
          ),
          if (_importing) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _totalBytes == 0
                  ? null
                  : (_copiedBytes / _totalBytes).clamp(0, 1).toDouble(),
              minHeight: 6,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 8),
            Text(
              _swapping
                  ? '正在换上备份…'
                  : _totalBytes == 0
                  ? '正在计算大小…'
                  : '${_byteLabel(_copiedBytes)} / ${_byteLabel(_totalBytes)}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: _busy ? null : _export,
                child: Text(_busy && !_importing ? '正在导出…' : '导出备份'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _import,
                child: Text(_busy && _importing ? '正在导入…' : '导入备份'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RowLabel extends StatelessWidget {
  const _RowLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(fontWeight: FontWeight.w600));
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.fontFamily,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: selected ? palette.primarySoft : AppColors.background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: fontFamily,
              color: selected ? palette.primary : AppColors.text,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.text : Colors.transparent,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

String _byteLabel(int bytes) {
  const kb = 1024;
  const mb = 1024 * 1024;
  const gb = 1024 * 1024 * 1024;
  if (bytes < kb) return '$bytes B';
  if (bytes < mb) return '${(bytes / kb).toStringAsFixed(0)} KB';
  if (bytes < gb) return '${(bytes / mb).toStringAsFixed(1)} MB';
  return '${(bytes / gb).toStringAsFixed(1)} GB';
}
