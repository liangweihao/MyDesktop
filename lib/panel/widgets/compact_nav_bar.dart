import 'package:flutter/material.dart';

class CompactNavBar extends StatelessWidget {
  const CompactNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
    this.compact = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<CompactNavItem> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = compact ? 36.0 : 44.0;
    final iconSize = compact ? 18.0 : 20.0;
    final showLabel = !compact;

    return Material(
      color: scheme.surfaceContainerHighest,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onSelected(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        i == selectedIndex
                            ? items[i].selectedIcon
                            : items[i].icon,
                        size: iconSize,
                        color: i == selectedIndex
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      if (showLabel) ...[
                        const SizedBox(height: 2),
                        Text(
                          items[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: i == selectedIndex
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CompactNavItem {
  const CompactNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
