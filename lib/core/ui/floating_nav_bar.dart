import 'package:claudy/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// A floating pill-shaped navigation bar item definition.
class FloatingNavBarItem {
  const FloatingNavBarItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
}

/// A floating, semi-transparent pill-shaped bottom navigation bar.
///
/// Sits above the content with configurable margins and casts a subtle shadow.
/// Uses smooth animations for icon/label transitions when selection changes.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final List<FloatingNavBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: Tokens.floatingNavBarHeight,
      margin: const EdgeInsets.only(
        left: Tokens.floatingNavBarMargin,
        right: Tokens.floatingNavBarMargin,
        bottom: Tokens.floatingNavBarMargin,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: Tokens.floatingNavBarOpacity),
        borderRadius: BorderRadius.circular(Tokens.floatingNavBarBorderRadius),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: Tokens.floatingNavBarElevation * 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Tokens.floatingNavBarBorderRadius),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            return _FloatingNavBarItemWidget(
              item: items[index],
              isSelected: index == selectedIndex,
              onTap: () => onItemSelected(index),
            );
          }),
        ),
      ),
    );
  }
}

class _FloatingNavBarItemWidget extends StatelessWidget {
  const _FloatingNavBarItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final FloatingNavBarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selectedColor = colorScheme.primary;
    final unselectedColor = colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashFactory: InkSparkle.splashFactory,
        borderRadius: BorderRadius.circular(Tokens.floatingNavBarBorderRadius),
        child: AnimatedContainer(
          duration: Tokens.motionMedium,
          curve: Tokens.easeOut,
          padding: const EdgeInsets.symmetric(vertical: Tokens.space8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: Tokens.motionFast,
                switchInCurve: Tokens.easeOut,
                switchOutCurve: Tokens.easeOut,
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Icon(
                  isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
                  key: ValueKey(isSelected),
                  color: isSelected ? selectedColor : unselectedColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: Tokens.space4),
              AnimatedDefaultTextStyle(
                duration: Tokens.motionFast,
                curve: Tokens.easeOut,
                style: theme.textTheme.labelSmall!.copyWith(
                  color: isSelected ? selectedColor : unselectedColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
