import 'package:flutter/material.dart';
import 'package:wardrobe/core/design_system/theme.dart';
import 'package:wardrobe/core/vision/ocr/tag_ocr.dart';
import 'package:wardrobe/features/wardrobe/item_photos.dart';
import 'package:wardrobe/widgets/common.dart';

/// Full page for comparing one hangtag photo with its OCR lines.
///
/// Edits stay on the in-memory [EditableItemPhoto] until the item form saves.
class HangtagTextPage extends StatefulWidget {
  const HangtagTextPage({
    super.key,
    required this.photos,
    required this.onRecognize,
  });

  final List<EditableItemPhoto> photos;
  final Future<void> Function(EditableItemPhoto photo) onRecognize;

  @override
  State<HangtagTextPage> createState() => _HangtagTextPageState();
}

class _HangtagTextPageState extends State<HangtagTextPage> {
  int _index = 0;
  bool _recognizing = false;

  Future<void> _recognize(EditableItemPhoto photo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重新识别这张吊牌？'),
        content: const Text('这张吊牌上改过的原文会被盖掉。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('重新识别'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _recognizing = true);
    try {
      await widget.onRecognize(photo);
    } finally {
      if (mounted) setState(() => _recognizing = false);
    }
    if (!mounted) return;
    final error = photo.error;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final index = _index.clamp(0, photos.length - 1);
    final photo = photos[index];
    final imagePath = photo.previewPath;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 28, 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                  label: const Text('返回'),
                ),
                const Expanded(
                  child: Text(
                    '修改吊牌原文',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: _recognizing ? null : () => _recognize(photo),
                  child: Text(_recognizing ? '识别中…' : '重新识别'),
                ),
              ],
            ),
          ),
          if (photos.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 8),
              child: Row(
                children: [
                  for (var i = 0; i < photos.length; i++)
                    TextButton(
                      onPressed: () => setState(() => _index = i),
                      child: Text(
                        '第 ${i + 1} 张',
                        style: TextStyle(
                          fontWeight: i == index
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _tagImage(imagePath)),
                  const SizedBox(width: 24),
                  Expanded(
                    child: HangtagLineEditor(
                      key: ValueKey(photo.id),
                      ocr: photo.ocr,
                      onChanged: (ocr) => setState(() => photo.ocr = ocr),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagImage(String path) {
    if (path.isEmpty) {
      return const Center(
        child: Text('没有吊牌图', style: TextStyle(color: AppColors.textMuted)),
      );
    }
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

/// Lines for one tag photo. Editing does not re-parse brand, fabric, or size.
class HangtagLineEditor extends StatefulWidget {
  const HangtagLineEditor({
    super.key,
    required this.ocr,
    required this.onChanged,
  });

  final TagOcrResult ocr;
  final ValueChanged<TagOcrResult> onChanged;

  @override
  State<HangtagLineEditor> createState() => _HangtagLineEditorState();
}

class _HangtagLineEditorState extends State<HangtagLineEditor> {
  late List<TextEditingController> _lines;
  late List<FocusNode> _foci;
  int? _focusIndex;
  int _focusCaret = 0;

  @override
  void initState() {
    super.initState();
    _setLines(widget.ocr.lines);
  }

  @override
  void didUpdateWidget(HangtagLineEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.ocr.lines;
    final current = [for (final controller in _lines) controller.text];
    if (!_same(next, current)) {
      final previousLines = _lines;
      final previousFoci = _foci;
      _setLines(next);
      final focusIndex = _focusIndex;
      final focusCaret = _focusCaret;
      _focusIndex = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final controller in previousLines) {
          controller.dispose();
        }
        for (final node in previousFoci) {
          node.dispose();
        }
        if (!mounted || focusIndex == null || focusIndex >= _foci.length) {
          return;
        }
        _foci[focusIndex].requestFocus();
        final text = _lines[focusIndex].text;
        final caret = focusCaret.clamp(0, text.length);
        _lines[focusIndex].selection = TextSelection.collapsed(offset: caret);
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _lines) {
      controller.dispose();
    }
    for (final node in _foci) {
      node.dispose();
    }
    super.dispose();
  }

  void _setLines(List<String> lines) {
    _lines = [for (final line in lines) TextEditingController(text: line)];
    _foci = [for (final _ in lines) FocusNode()];
  }

  void _emit(List<String> lines, {bool keepEmpty = false}) {
    widget.onChanged(replaceTagLines(widget.ocr, lines, keepEmpty: keepEmpty));
  }

  void _split(int index) {
    final controller = _lines[index];
    final text = controller.text;
    final rawCaret = controller.selection.baseOffset;
    final caret = (rawCaret < 0 ? text.length : rawCaret).clamp(0, text.length);
    final next = splitTagLine(
      [for (final line in _lines) line.text],
      index,
      text.substring(0, caret),
      text.substring(caret),
    );
    _focusIndex = index + 1;
    _focusCaret = 0;
    _emit(next, keepEmpty: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_lines.isEmpty) {
      return const Align(
        alignment: Alignment.topLeft,
        child: Text('未识别到文字', style: TextStyle(color: AppColors.textMuted)),
      );
    }
    final displayed = [for (final controller in _lines) controller.text];
    return ListView(
      children: [
        for (var index = 0; index < _lines.length; index++)
          _TagLineRow(
            controller: _lines[index],
            focusNode: _foci[index],
            canMergeUp: index > 0,
            canMergeDown: index + 1 < _lines.length,
            onChanged: (text) => _emit(editTagLine(displayed, index, text)),
            onSplit: () => _split(index),
            onMergeUp: () => _emit(mergeAdjacentTagLines(displayed, index - 1)),
            onMergeDown: () => _emit(mergeAdjacentTagLines(displayed, index)),
            onDelete: () => _emit(removeTagLine(displayed, index)),
          ),
      ],
    );
  }
}

class _TagLineRow extends StatefulWidget {
  const _TagLineRow({
    required this.controller,
    required this.focusNode,
    required this.canMergeUp,
    required this.canMergeDown,
    required this.onChanged,
    required this.onSplit,
    required this.onMergeUp,
    required this.onMergeDown,
    required this.onDelete,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canMergeUp;
  final bool canMergeDown;
  final ValueChanged<String> onChanged;
  final VoidCallback onSplit;
  final VoidCallback onMergeUp;
  final VoidCallback onMergeDown;
  final VoidCallback onDelete;

  @override
  State<_TagLineRow> createState() => _TagLineRowState();
}

class _TagLineRowState extends State<_TagLineRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                decoration: const InputDecoration(isDense: true),
                onChanged: widget.onChanged,
                onSubmitted: (_) => widget.onSplit(),
              ),
            ),
            SizedBox(
              width: 112,
              child: _hover
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _LineAction(
                          tooltip: '合并到上一行',
                          icon: Icons.arrow_upward,
                          onPressed: widget.canMergeUp
                              ? widget.onMergeUp
                              : null,
                        ),
                        _LineAction(
                          tooltip: '合并到下一行',
                          icon: Icons.arrow_downward,
                          onPressed: widget.canMergeDown
                              ? widget.onMergeDown
                              : null,
                        ),
                        _LineAction(
                          tooltip: '删除',
                          icon: Icons.close,
                          onPressed: widget.onDelete,
                        ),
                      ],
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _LineAction extends StatelessWidget {
  const _LineAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}

bool _same(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}
