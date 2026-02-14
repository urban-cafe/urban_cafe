import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;

  const PrimaryButton({super.key, required this.text, this.onPressed, this.isLoading = false, this.width, this.backgroundColor, this.foregroundColor, this.icon});

  @override
  Widget build(BuildContext context) {
    // If width is null, let it be double.infinity to match the full-width requirement typical of primary buttons
    // unless constrained by parent.
    // However, FilledButton by default shrinks to fit. To make it full width, wrap in SizedBox/Expanded.
    // The image shows full width.

    final buttonStyle = FilledButton.styleFrom(backgroundColor: backgroundColor, foregroundColor: foregroundColor);

    Widget child = isLoading
        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: foregroundColor ?? Theme.of(context).colorScheme.onPrimary))
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
              Text(text),
            ],
          );

    return SizedBox(
      width: width ?? double.infinity,
      child: FilledButton(onPressed: isLoading ? null : onPressed, style: buttonStyle, child: child),
    );
  }
}
