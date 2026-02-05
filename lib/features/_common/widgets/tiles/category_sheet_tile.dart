import 'package:flutter/material.dart';

class CategorySheetTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategorySheetTile({super.key, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        // Use withValues for Flutter 3.27+ (or withOpacity for older)
        color: isSelected ? colorScheme.primary.withValues(alpha: 0.08) : null,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? colorScheme.primary : colorScheme.onSurface, letterSpacing: 0.5),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
