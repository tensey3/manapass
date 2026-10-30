import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../router/routes.dart';

class _NavItem {
  const _NavItem(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

const _mainItems = [
  _NavItem('ホーム', Icons.home_rounded, Routes.home),
  _NavItem('問題', Icons.menu_book_rounded, Routes.question),
  _NavItem('復習', Icons.replay_rounded, Routes.review),
  _NavItem('単語帳', Icons.style_rounded, Routes.vocab),
  _NavItem('進捗', Icons.bar_chart_rounded, Routes.progress),
];

const _settingsItem = _NavItem('設定', Icons.settings_rounded, Routes.settings);

class SideMenu extends StatelessWidget {
  const SideMenu({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Brand(),
            const SizedBox(height: 20),
            for (final item in _mainItems)
              _MenuTile(item: item, selected: location.startsWith(item.route)),
            const Spacer(),
            _MenuTile(
              item: _settingsItem,
              selected: location.startsWith(_settingsItem.route),
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.menuSelectedBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.school_rounded, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Text(
          'まなパス',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item, required this.selected});

  final _NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.menuSelectedText : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? AppColors.menuSelectedBg : Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.menuSelectedBorder : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: () {
            Scaffold.maybeOf(context)?.closeDrawer();
            context.go(item.route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(item.icon, size: 22, color: color),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
