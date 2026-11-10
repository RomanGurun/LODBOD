import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

class LodbodBottomNav extends StatelessWidget {
  const LodbodBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem(
      Icons.local_shipping_outlined,
      Icons.local_shipping_rounded,
      'Shipments',
    ),
    _NavItem(Icons.add_rounded, Icons.add_rounded, 'Post Load'),
    _NavItem(Icons.insights_outlined, Icons.insights_rounded, 'Analytics'),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSizes.sm),
        child: Container(
          height: AppSizes.bottomNavHeight,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              for (var index = 0; index < _items.length; index++)
                Expanded(
                  child: index == 2
                      ? _CenterNavItem(
                          item: _items[index],
                          selected: index == currentIndex,
                          onTap: () => onTap(index),
                        )
                      : _NavItemButton(
                          item: _items[index],
                          selected: index == currentIndex,
                          onTap: () => onTap(index),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _NavItemButton extends StatelessWidget {
  const _NavItemButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textTertiary;
    return InkResponse(
      onTap: onTap,
      radius: 36,
      containedInkWell: true,
      highlightShape: BoxShape.circle,
      child: Padding(
        padding: const EdgeInsets.only(top: 9, bottom: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              selected ? item.selectedIcon : item.icon,
              size: AppSizes.bottomNavIcon,
              color: color,
            ),
            Text(
              item.label,
              maxLines: 1,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: AppTypography.micro,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterNavItem extends StatelessWidget {
  const _CenterNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: -17,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: AppSizes.navFab,
              height: AppSizes.navFab,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: AppColors.raisedShadow,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: AppSizes.navFabIcon,
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          child: Text(
            item.label,
            maxLines: 1,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: AppTypography.micro,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.primary : AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
