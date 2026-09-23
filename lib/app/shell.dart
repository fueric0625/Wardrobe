import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wardrobe/core/design_system/app_font.dart';
import 'package:wardrobe/core/design_system/theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _indexFor(String path) {
    if (path.startsWith('/outfits')) return 1;
    if (path.startsWith('/calendar')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final index = _indexFor(path);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _Sidebar(
            index: index,
            onSelect: (i) {
              switch (i) {
                case 0:
                  context.go('/wardrobe');
                case 1:
                  context.go('/outfits');
                case 2:
                  context.go('/calendar');
              }
            },
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            const Text(
              '衣橱',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 28),
            _NavItem(
              icon: Icons.checkroom_outlined,
              label: '衣橱',
              selected: index == 0,
              onTap: () => onSelect(0),
            ),
            _NavItem(
              icon: Icons.layers_outlined,
              label: '穿搭',
              selected: index == 1,
              onTap: () => onSelect(1),
            ),
            _NavItem(
              icon: Icons.calendar_month_outlined,
              label: '日历',
              selected: index == 2,
              onTap: () => onSelect(2),
            ),
            const Spacer(),
            const _FontButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FontButton extends ConsumerWidget {
  const _FontButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appFontProvider);
    return PopupMenuButton<String>(
      tooltip: '字体',
      offset: const Offset(80, 0),
      onSelected: (family) => ref.read(appFontProvider.notifier).select(family),
      itemBuilder: (context) => [
        for (final choice in appFontChoices)
          PopupMenuItem(
            value: choice.family,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: current == choice.family
                      ? const Icon(
                          Icons.check,
                          size: 18,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                Text(
                  choice.label,
                  style: TextStyle(fontFamily: choice.family, fontSize: 16),
                ),
              ],
            ),
          ),
      ],
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(Icons.text_fields, color: AppColors.textMuted, size: 22),
            SizedBox(height: 4),
            Text(
              '字体',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
