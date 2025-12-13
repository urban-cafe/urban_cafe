import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/presentation/providers/theme_provider.dart';

class ThemeSelectionButton extends StatelessWidget {
  const ThemeSelectionButton({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Performance: Use Selector to listen ONLY to the themeMode.
    // This prevents unnecessary rebuilds if other parts of the provider change.
    return Selector<ThemeProvider, ThemeMode>(
      selector: (_, provider) => provider.themeMode,
      builder: (context, currentMode, child) {
        // Determine the icon based on the mode
        IconData buttonIcon;
        switch (currentMode) {
          case ThemeMode.light:
            buttonIcon = Icons.light_mode_rounded;
            break;
          case ThemeMode.dark:
            buttonIcon = Icons.dark_mode_rounded;
            break;
          case ThemeMode.system:
            // If system, check actual platform brightness for the icon
            final isPlatformDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
            buttonIcon = isPlatformDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined;
            break;
        }

        return Theme(
          // 2. UI: Local theme override for a premium menu look
          data: Theme.of(context).copyWith(
            popupMenuTheme: PopupMenuThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              elevation: 4,
            ),
          ),
          child: PopupMenuButton<ThemeMode>(
            tooltip: 'Change Theme',
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

            // 3. UX: Animated Icon Transition
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => RotationTransition(turns: anim, child: child),
              child: Icon(
                buttonIcon,
                key: ValueKey<ThemeMode>(currentMode), // Key ensures animation triggers
                color: Colors.white, // Kept white for your Header Image contrast
              ),
            ),

            onSelected: (mode) => context.read<ThemeProvider>().setThemeMode(mode),

            itemBuilder: (BuildContext context) => [
              _buildItem(context, ThemeMode.light, Icons.light_mode_rounded, "Light", currentMode),
              _buildItem(context, ThemeMode.dark, Icons.dark_mode_rounded, "Dark", currentMode),
              _buildDivider(), // Subtle divider
              _buildItem(context, ThemeMode.system, Icons.settings_brightness_rounded, "System", currentMode),
            ],
          ),
        );
      },
    );
  }

  // Helper to build styled menu items
  PopupMenuItem<ThemeMode> _buildItem(BuildContext context, ThemeMode value, IconData icon, String label, ThemeMode currentMode) {
    final isSelected = value == currentMode;
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;

    return PopupMenuItem<ThemeMode>(
      value: value,
      height: 48,
      child: Row(
        children: [
          // Icon with color change if selected
          Icon(icon, size: 20, color: isSelected ? activeColor : colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),

          // Label text
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? activeColor : colorScheme.onSurface, fontSize: 14),
            ),
          ),

          // Checkmark for active state
          if (isSelected) Icon(Icons.check_rounded, size: 18, color: activeColor),
        ],
      ),
    );
  }

  // Tiny divider for visual separation
  PopupMenuEntry<ThemeMode> _buildDivider() {
    return const PopupMenuDivider(height: 1);
  }
}
