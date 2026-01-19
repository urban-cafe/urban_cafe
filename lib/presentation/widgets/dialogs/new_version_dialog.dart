import 'package:flutter/material.dart';
import 'package:urban_cafe/core/utils/web_reloader.dart';

class NewVersionDialog extends StatelessWidget {
  const NewVersionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.system_update, color: colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Update Available'),
        ],
      ),
      content: const Text(
        'A new version of the app is available. Please refresh to get the latest features and improvements.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Later'),
        ),
        FilledButton.icon(
          onPressed: () {
            reloadWebPage();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh Now'),
        ),
      ],
    );
  }
}
