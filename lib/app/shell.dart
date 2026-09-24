import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wardrobe/core/design_system/theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _indexFor(String path) {
    if (path.startsWith('/settings')) return -1;
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
            Text(
              '衣橱',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppPalette.of(context).primary,
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
            const _SettingsButton(),
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
    final palette = AppPalette.of(context);
    final color = selected ? palette.primary : AppColors.textMuted;
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
            color: selected ? palette.primarySoft : Colors.transparent,
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

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    final selected = GoRouterState.of(context).uri.path.startsWith('/settings');
    final palette = AppPalette.of(context);
    final color = selected ? palette.primary : AppColors.textMuted;
    return InkWell(
      onTap: () => context.go('/settings'),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(Icons.settings_outlined, color: color, size: 22),
            const SizedBox(height: 4),
            Text('设置', style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}
