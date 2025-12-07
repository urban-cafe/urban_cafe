import 'package:flutter/material.dart';

/// Displays a global styled SnackBar
void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  final theme = Theme.of(context);

  // Clear any existing SnackBars so the new one shows immediately
  ScaffoldMessenger.of(context).clearSnackBars();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      // Use Error color for errors, Primary color for success
      backgroundColor: isError ? theme.colorScheme.error : theme.colorScheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ),
  );
}
