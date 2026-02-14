import 'package:flutter/material.dart';
import 'package:urban_cafe/features/_common/widgets/buttons/primary_button.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialog({super.key, required this.title, required this.message, required this.confirmText, required this.cancelText, required this.onConfirm, this.isDestructive = false, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            Icon(isDestructive ? Icons.warning_amber_rounded : Icons.info_outline_rounded, size: 48, color: isDestructive ? colorScheme.error : colorScheme.primary),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(text: cancelText, onPressed: onCancel ?? () => Navigator.of(context).pop(false), backgroundColor: colorScheme.surfaceContainerHighest, foregroundColor: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(text: confirmText, onPressed: onConfirm, backgroundColor: isDestructive ? colorScheme.error : colorScheme.primary, foregroundColor: isDestructive ? colorScheme.onError : colorScheme.onPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
