import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/features/_common/theme_provider.dart';

class ThemeSelectionButton extends StatelessWidget {
  const ThemeSelectionButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Only this widget rebuilds when theme changes (if we were watching specific properties)
    // But since we read the current brightness from Theme.of(context), it works automatically.
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Theme(
      data: theme.copyWith(
        popupMenuTheme: PopupMenuThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: colorScheme.surfaceContainerLow,
        ),
      ),
      child: PopupMenuButton<ThemeMode>(
        tooltip: 'Change Theme',
        icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: colorScheme.primary),
        offset: const Offset(0, 45),
        constraints: const BoxConstraints.tightFor(width: 150),
        onSelected: (mode) => context.read<ThemeProvider>().setThemeMode(mode),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<ThemeMode>>[_buildCompactItem(context, Icons.light_mode_outlined, "Light", ThemeMode.light), _buildCompactItem(context, Icons.dark_mode_outlined, "Dark", ThemeMode.dark), _buildCompactItem(context, Icons.brightness_auto_outlined, "System", ThemeMode.system)],
      ),
    );
  }

  PopupMenuItem<ThemeMode> _buildCompactItem(BuildContext context, IconData icon, String label, ThemeMode value) {
    final theme = Theme.of(context);
    return PopupMenuItem<ThemeMode>(
      value: value,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurface),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.labelLarge?.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}
