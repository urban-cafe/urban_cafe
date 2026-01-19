import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/presentation/providers/theme_provider.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('theme'.tr()), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text('Customize how the app looks on your device.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  _ThemeOption(label: 'System Default', description: 'Follows your device settings', icon: Icons.brightness_auto_outlined, isSelected: themeProvider.themeMode == ThemeMode.system, onTap: () => themeProvider.setThemeMode(ThemeMode.system), isFirst: true),
                  Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  _ThemeOption(label: 'Light Mode', description: 'Clean and bright interface', icon: Icons.light_mode_outlined, isSelected: themeProvider.themeMode == ThemeMode.light, onTap: () => themeProvider.setThemeMode(ThemeMode.light)),
                  Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  _ThemeOption(label: 'Dark Mode', description: 'Easy on the eyes in low light', icon: Icons.dark_mode_outlined, isSelected: themeProvider.themeMode == ThemeMode.dark, onTap: () => themeProvider.setThemeMode(ThemeMode.dark), isLast: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _ThemeOption({required this.label, required this.description, required this.icon, required this.isSelected, required this.onTap, this.isFirst = false, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(top: isFirst ? const Radius.circular(16) : Radius.zero, bottom: isLast ? const Radius.circular(16) : Radius.zero),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1) : null,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHigh, shape: BoxShape.circle),
                child: Icon(icon, size: 22, color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
