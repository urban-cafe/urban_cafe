import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/presentation/providers/theme_provider.dart';

class ThemeSelectionDialog extends StatelessWidget {
  const ThemeSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final currentMode = themeProvider.themeMode;

    return AlertDialog(
      title: const Text('Choose Theme'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(context, title: 'System Default', icon: Icons.brightness_auto, value: ThemeMode.system, groupValue: currentMode, onChanged: (val) => themeProvider.setThemeMode(val)),
          _buildOption(context, title: 'Light Mode', icon: Icons.light_mode, value: ThemeMode.light, groupValue: currentMode, onChanged: (val) => themeProvider.setThemeMode(val)),
          _buildOption(context, title: 'Dark Mode', icon: Icons.dark_mode, value: ThemeMode.dark, groupValue: currentMode, onChanged: (val) => themeProvider.setThemeMode(val)),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    );
  }

  Widget _buildOption(BuildContext context, {required String title, required IconData icon, required ThemeMode value, required ThemeMode groupValue, required Function(ThemeMode) onChanged}) {
    final isSelected = value == groupValue;
    final colorScheme = Theme.of(context).colorScheme;

    return RadioListTile<ThemeMode>(
      value: value,
      title: Text(
        title,
        style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? colorScheme.primary : colorScheme.onSurface),
      ),
      secondary: Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
      activeColor: colorScheme.primary,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
